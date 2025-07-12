#!./luajit

local lfs
local util
local zipsync

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

local function zipsync_make(zip_path, zipsync_path, older_zip_or_zipsync_path)
    local zip = zipsync.ZipArchive:new(zip_path)
    if older_zip_or_zipsync_path then
        zip:reorder(older_zip_or_zipsync_path)
    end
    local files = {}
    for e in zip:each() do
        -- Ignore directories.
        if e.size ~= 0 then
            table.insert(files, {
                hash = zip:hash_unpacked(e),
                path = e.path,
                size = e.size,
                zip_hash = zip:hash_packed(e),
                zip_start = e.zip_start,
                zip_stop = e.zip_stop,
            })
        end
    end
    local manifest = {
        filename = zip_path:match("([^/]+)$"),
        files = files,
        zip_cdir_start = zip.eocd.cdir_offset,
        zip_cdir_stop = zip.eocd.cdir_offset + zip.eocd.cdir_size - 1,
        zip_cdir_hash = zip:hash(zip.eocd.cdir_offset, zip.eocd.cdir_offset + zip.eocd.cdir_size - 1),
    }
    zip:close()
    if not zipsync_path then
        assert(zip_path:match("[.]zip$"))
        zipsync_path = zip_path.."sync"
    end
    zipsync.save_zipsync(zipsync_path, manifest)
end

local function zipsync_sync(state_dir, zipsync_url, seed)
    local updater = zipsync.Updater:new(state_dir)
    if seed and lfs.attributes(seed, "mode") == "file" then
        -- If the seed is a zipsync file, we need to load it
        -- now, as it may get overwritten by `fetch_manifest`.
        local by_path = {}
        for i, e in ipairs(zipsync.load_zipsync(seed).files) do
            by_path[e.path] = e
        end
        seed = by_path
    end
    updater:fetch_manifest(zipsync_url)
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
USAGE: zipsync make [-h] [--reorder OLDER_ZIP_OR_ZIPSYNC_FILE] ZIP_FILE [ZIPSYNC_FILE]
       zipsync sync [-h] STATE_DIR ZIPSYNC_URL [SEED_DIR_OR_ZIPSYNC_FILE]

options:
  -h, --help   show this help message and exit

MAKE:

  ZIP_FILE              source ZIP file
  ZIPSYNC_FILE          destination zipsync file

  -r, --reorder OLDER_ZIP_OR_ZIPSYNC_FILE
                        will repack the new zip with this order:
                        ┌─────────────┬──────────────────┬────────────────────┬────┬──────┐
                        │   folders   │ unmodified files │ new/modified files │ CD │ EOCD │
                        │ (new order) │   (old order)    │    (new order)     │    │      │
                        └─────────────┴──────────────────┴────────────────────┴────┴──────┘
SYNC:

  STATE_DIR             destination for the zipsync and update files
  ZIPSYNC_URL           URL of zipsync file
  SEED_DIR_OR_ZIPSYNC_FILE
                        optional seed directory / zsync file
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
                print(help)
                return
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
        fn = function() zipsync_make(arguments[1], arguments[2], options["reorder"]) end
    elseif command == "sync" then
        if #arguments < 2 then
            io.stderr:write("ERROR: not enough arguments\n")
            return 2
        end
        if #arguments > 3 then
            io.stderr:write("ERROR: too many arguments\n")
            return 2
        end
        fn = function() zipsync_sync(arguments[1], arguments[2], arguments[3]) end
    elseif not command then
        print(help)
        return 2
    else
        io.stderr:write(string.format("ERROR: unrecognized command: %s\n", command))
        return 2
    end
    package.path = "common/?.lua;"..package.path
    package.cpath = "common/?.so;"..package.cpath
    require("ffi/loadlib")
    lfs = require("libs/libkoreader-lfs")
    util = require("ffi/util")
    zipsync = require("ffi/zipsync")
    return fn()
end

os.exit(main())
