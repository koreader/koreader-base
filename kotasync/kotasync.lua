#!./luajit

local lfs
local util
local kotasync

local function naturalsize(size)
    local chunk, unit = 1, 'B '
    if size >= 1000*1000*1000 then
        chunk, unit = 1000*1000*1000, 'GB'
    elseif size >= 1000*1000 then
        chunk, unit = 1000*1000, 'MB'
    elseif size >= 1000 then
        chunk, unit = 1000, 'KB'
    end
    local fmt = chunk > 1 and "%.1f" or "%u"
    return string.format(fmt.." %s", size / chunk, unit)
end

local function make(tar_xz_path, kotasync_path, tar_xz_manifest, older_tar_xz_or_kotasync_path)
    local tar_xz = kotasync.TarXz:new():open(tar_xz_path, tar_xz_manifest)
    if older_tar_xz_or_kotasync_path then
        tar_xz:reorder(older_tar_xz_or_kotasync_path)
    end
    local files = {}
    local manifest_by_path = tar_xz.by_path
    if tar_xz_manifest then
        manifest_by_path = {}
        for __, f in ipairs(tar_xz.manifest) do
            assert(not manifest_by_path[f])
            manifest_by_path[f] = true
        end
    end
    for e in tar_xz:each() do
        -- Ignore directories.
        if e.size ~= 0 and manifest_by_path[e.path] then
            table.insert(files, e)
        end
    end
    if tar_xz_manifest and #files ~= #tar_xz.manifest then
        error("mismatched manifest / archive contents")
    end
    local manifest = {
        filename = tar_xz_path:match("([^/]+)$"),
        files = files,
        xz_check = tonumber(tar_xz.header_stream_flags.check),
    }
    tar_xz:close()
    if not kotasync_path then
        assert(tar_xz_path:match("[.]tar.xz$"))
        kotasync_path = tar_xz_path:sub(1, -7).."kotasync"
    end
    kotasync.save_manifest(kotasync_path, manifest)
end

local function sync(state_dir, manifest_url, seed)
    local updater = kotasync.Updater:new(state_dir)
    if seed and lfs.attributes(seed, "mode") == "file" then
        -- If the seed is a kotasync file, we need to load it
        -- now, as it may get overwritten by `fetch_manifest`.
        local by_path = {}
        for i, e in ipairs(kotasync.load_manifest(seed).files) do
            by_path[e.path] = e
        end
        seed = by_path
    end
    updater:fetch_manifest(manifest_url)
    local total_files = #updater.manifest.files
    local last_update = 0
    local delay = false --190000
    local update_frequency = 0.2
    local stats = updater:prepare_update(seed, function(count)
        local new_update = util.getTimestamp()
        if count ~= total_files and new_update - last_update < update_frequency then
            return true
        end
        last_update = new_update
        io.stderr:write(string.format("\ranalyzing: %4u/%4u", count, total_files))
        if delay then
            util.usleep(delay)
        end
        return true
    end)
    io.stderr:write(string.format("\r%99s\r", ""))
    assert(total_files == stats.total_files)
    if stats.missing_files == 0 then
        print('nothing to update!')
        return
    end
    print(string.format("missing : %u/%u files", stats.missing_files, total_files))
    print(string.format("reusing : %7s (%10u)", naturalsize(stats.reused_size), stats.reused_size))
    print(string.format("fetching: %7s (%10u)", naturalsize(stats.download_size), stats.download_size))
    io.stdout:flush()
    local pbar_indicators = {" ", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"}
    local pbar_size = 16
    local pbar_chunk = (stats.download_size + pbar_size - 1) / pbar_size
    local prev_path = ""
    local old_progress
    last_update = 0
    local ok, err = pcall(updater.download_update, updater, function(size, count, path)
        local new_update = util.getTimestamp()
        if size ~= stats.download_size and new_update - last_update < update_frequency then
            return true
        end
        last_update = new_update
        local padding = math.max(#prev_path, #path)
        local progress = math.floor(size / pbar_chunk)
        local pbar = pbar_indicators[#pbar_indicators]:rep(progress)..pbar_indicators[1 + math.floor(size % pbar_chunk * #pbar_indicators / pbar_chunk)]..(" "):rep(pbar_size - progress - 1)
        local new_progress = string.format("\rdownloading: %8s %4u/%4u %s %-"..padding.."s", size, count, stats.missing_files, pbar, path)
        if new_progress ~= old_progress then
            old_progress = new_progress
            io.stderr:write(new_progress)
        end
        prev_path = path
        if delay then
            util.usleep(delay)
        end
        return true
    end)
    io.stderr:write(string.format("\r%99s\r", ""))
    if not ok then
        io.stderr:write(string.format("ERROR: %s", err))
        return 1
    end
end

local help = [[
USAGE: kotasync make [-h] [--manifest TAR_XZ_MANIFEST] [--reorder OLDER_TAR_XZ_OR_KOTASYNC_FILE] TAR_XZ_FILE [KOTASYNC_FILE]
       kotasync sync [-h] STATE_DIR KOTASYNC_URL [SEED_DIR_OR_KOTASYNC_FILE]

options:
  -h, --help   show this help message and exit

MAKE:

  TAR_XZ_FILE            source tar.xz file
  KOTASYNC_FILE          destination kotasync file

  -m, --manifest TAR_XZ_MANIFEST
                         archive entry to use as base for manifest

  -r, --reorder OLDER_TAR_XZ_OR_KOTASYNC_FILE
                        will repack the new tar.xz with this order:
                        ┌────────────────────┬──────────────────┬─────────────┐
                        │ new/modified files │ unmodified files │   folders   │
                        │    (new order)     │   (old order)    │ (new order) │
                        └────────────────────┴──────────────────┴─────────────┘
SYNC:

  STATE_DIR             destination for the kotasync and update files
  KOTASYNC_URL          URL of kotasync file
  SEED_DIR_OR_KOTASYNC_FILE
                        optional seed directory / kotasync file
]]

local function main()
    local command
    local options = {}
    local arguments = {}
    while #arg > 0 do
        local a = table.remove(arg, 1)
        -- print(i, a)
        if a:match("^-(.+)$") then
            -- print('option', a)
            if a == "-h" or a == "--help" then
                io.stdout:write(help)
                return
            elseif command == "make" and (a == "-m" or a == "--manifest") then
                if #arg == 0 then
                    io.stderr:write(string.format("ERROR: option --manifest: expected one argument\n"))
                    return 2
                end
                options.manifest = table.remove(arg, 1)
            elseif command == "make" and (a == "-r" or a == "--reorder") then
                if #arg == 0 then
                    io.stderr:write(string.format("ERROR: option --reorder: expected one argument\n"))
                    return 2
                end
                options.reorder = table.remove(arg, 1)
            else
                io.stderr:write(string.format("ERROR: unrecognized option: %s\n", a))
                return 2
            end
        elseif command then
            table.insert(arguments, a)
        else
            command = a
        end
    end
    local fn
    if command == "make" then
        if #arguments < 1 then
            io.stderr:write("ERROR: not enough arguments\n")
            return 2
        end
        if #arguments > 2 then
            io.stderr:write("ERROR: too many arguments\n")
            return 2
        end
        fn = function() make(arguments[1], arguments[2], options.manifest, options.reorder) end
    elseif command == "sync" then
        if #arguments < 2 then
            io.stderr:write("ERROR: not enough arguments\n")
            return 2
        end
        if #arguments > 3 then
            io.stderr:write("ERROR: too many arguments\n")
            return 2
        end
        fn = function() sync(arguments[1], arguments[2], arguments[3]) end
    elseif not command then
        io.stderr:write(help)
        return 2
    else
        io.stderr:write(string.format("ERROR: unrecognized command: %s\n", command))
        return 2
    end
    require("ffi/loadlib")
    lfs = require("libs/libkoreader-lfs")
    util = require("ffi/util")
    kotasync = require("ffi/kotasync")
    local ok, err = xpcall(fn, debug.traceback)
    if not ok then
        io.stderr:write(string.format("ERROR: %s\n", err))
        return 3
    end
end

os.exit(main())
