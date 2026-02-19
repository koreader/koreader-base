local Hashoir = require("ffi/hashoir")
local bit = require("bit")
local buffer = require("string.buffer")
local ffi = require("ffi")
local json = require("dkjson")
local lfs = require("libs/libkoreader-lfs")
local zstd = require("ffi/zstd")

require "ffi/loadlib"
require "ffi/posix_h"
require "ffi/xz_h"

local BLOCK_SIZE = 16 * 1024
local C = ffi.C

-- POSIX {{{

local function strerror(err)
    return ffi.string(C.strerror(err or ffi.errno()))
end

local function ensure_open(path, flags, mode)
    local fd = C.open(path, flags or C.O_RDONLY, mode and ffi.cast("mode_t", mode))
    if fd < 0 then
        error("open: "..strerror())
    end
    return fd
end

local function ensure_create(path, mode)
    return ensure_open(path, bit.bor(C.O_CREAT, C.O_WRONLY, C.O_TRUNC), mode or bit.bor(C.S_IRUSR, C.S_IWUSR, C.S_IRGRP, C.S_IROTH))
end

local function ensure_lseek(fd, offset, whence)
    local ret = C.lseek(fd, offset, whence or C.SEEK_SET)
    if ret < 0 then
        error("lseek: "..strerror())
    end
    return ret
end

local function ensure_read(fd, ptr, len)
    local ret = C.read(fd, ptr, len)
    if ret ~= len then
        error("read: "..(ret < 0 and strerror() or string.format("short read, %u/%u", ret, len)))
    end
    return ret
end

local function ensure_write(fd, ptr, len)
    local ret = C.write(fd, ptr, len)
    if ret ~= len then
        error("write: "..(ret < 0 and strerror() or string.format("short write, %u/%u", ret, len)))
    end
    return ret
end

-- }}}

-- Misc {{{

local function read_fd_blocks_iterator(fd, buf, len, block_size)
    block_size = block_size or BLOCK_SIZE
    local ptr = buf:reserve(block_size)
    return function()
        assert(len >= 0)
        if len == 0 then
            return
        end
        local count = math.min(len, block_size)
        ensure_read(fd, ptr, count)
        len = len - count
        return ptr, count
    end
end

local function hash_file(path, size)
    local fd = ensure_open(path)
    local buf = buffer:new()
    local hashoir = Hashoir:new()
    for ptr, len in read_fd_blocks_iterator(fd, buf, size) do
        hashoir:update(ptr, len)
    end
    C.close(fd)
    return hashoir:hexdigest()
end

local function path_matches(path, size, hash)
    if lfs.attributes(path, "size") ~= size then
        return false
    end
    local ok, file_hash = pcall(hash_file, path, size)
    return ok and file_hash == hash
end

-- }}}

-- TAR {{{

ffi.cdef[[
struct ustar_header {
    char path[100];
    char mode[8];
    char owner[8];
    char group[8];
    char size[12];
    char mtime[12];
    char checksum[8];
    char type;
    char link_name[100];
    char ustar_indicator[6];
    char ustar_version[2];
    char owner_name[32];
    char group_name[32];
    char device_major[8];
    char device_minor[8];
    char path_prefix[155];
};
]]

assert(ffi.sizeof("struct ustar_header") == 500)

-- "ustar  \0"
local FORMAT_GNUTAR = ffi.new("uint8_t[8]", 0x75, 0x73, 0x74, 0x61, 0x72, 0x20, 0x20, 0x00)
-- "ustar\000"
local FORMAT_USTAR = ffi.new("uint8_t[8]", 0x75, 0x73, 0x74, 0x61, 0x72, 0x00, 0x30, 0x30)

local function tar_size(file_size)
    local size = file_size + 511
    return 512 + size - bit.band(size, 511)
end

-- }}}

-- Manifest {{{

local function deserialize_manifest(ptr, len)
    ptr, len = zstd.zstd_uncompress(ptr, len)
    local manifest = json.decode(ffi.string(ptr, len))
    C.free(ffi.gc(ptr, nil))
    assert(manifest)
    return manifest
end

local function load_manifest(path)
    local len = lfs.attributes(path, "size")
    local fd = ensure_open(path)
    local buf = buffer:new()
    local ptr = buf:reserve(len)
    local ret = C.read(fd, ptr, len)
    local err = ffi.errno()
    C.close(fd)
    if ret ~= len then
        error(ret < 0 and strerror(err) or string.format("short read, %u/%u", ret, len))
    end
    return deserialize_manifest(ptr, len)
end

local function serialize_manifest(manifest, compression_level)
    local data = json.encode(manifest, {keyorder = {
        "filename", "files",
        "hash", "path", "size",
        "xz_check", "xz_hash", "xz_offset", "xz_size",
    }})
    assert(data)
    local ptr, len = zstd.zstd_compress(data, #data, compression_level or 19)
    return ffi.gc(ptr, C.free), len
end

local function save_manifest(path, manifest, compression_level)
    local ptr, len = serialize_manifest(manifest, compression_level)
    local fd = ensure_create(path)
    ensure_write(fd, ptr, len)
    C.free(ffi.gc(ptr, nil))
    C.close(fd)
end

-- }}}

-- XZ {{{

-- Our indexes are not that big.
local XZ_INDEX_MAXSIZE = 2 * 1024 * 1024
local XZ_INDEX_MEMLIMIT = 4 * 1024 * 1024

-- We compile a static lzma library, linked into
-- our archive library, and use that by default.
local xz
if (os.getenv("KOTASYNC_USE_XZ_LIB") or ""):match(".") then
    xz = ffi.loadlib("lzma", "5")
else
    xz = ffi.loadlib("archive", "13")
end

local function xz_block_header_size_decode(ptr)
    return (ptr[0] + 1) * 4
end

local function xz_padded_size(unpadded_size)
    local size = unpadded_size + 3
    return size - bit.band(size, 3)
end

local function free_xz_index(i)
    xz.lzma_index_end(i, nil)
end

-- }}}

-- TAR.XZ {{{

local TarXz = {}

function TarXz:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function TarXz:close()
    if self.tmpfd then
        C.close(self.tmpfd)
        self.tmpfd = nil
    end
    if self.fd then
        C.close(self.fd)
        self.fd = nil
    end
    return self
end

function TarXz:open(filename, manifest)
    self:close()
    self.filename = filename
    local fd = ensure_open(filename)
    self.fd = fd
    local stream_buf = ffi.new("uint8_t[?]", xz.LZMA_STREAM_HEADER_SIZE)
    local ret
    -- Check header.
    ensure_read(fd, stream_buf, xz.LZMA_STREAM_HEADER_SIZE)
    local header_stream_flags = ffi.new("lzma_stream_flags")
    ret = xz.lzma_stream_header_decode(header_stream_flags, stream_buf)
    assert(ret == xz.LZMA_OK, ret)
    assert(header_stream_flags.version == 0)
    local check_size = xz.lzma_check_size(header_stream_flags.check)
    assert(check_size > 0)
    -- Check footer.
    ensure_lseek(fd, -xz.LZMA_STREAM_HEADER_SIZE, C.SEEK_END)
    ensure_read(fd, stream_buf, xz.LZMA_STREAM_HEADER_SIZE)
    local footer_stream_flags = ffi.new("lzma_stream_flags")
    ret = xz.lzma_stream_footer_decode(footer_stream_flags, stream_buf)
    assert(ret == xz.LZMA_OK, ret)
    -- Check header & footer match.
    ret = xz.lzma_stream_flags_compare(header_stream_flags, footer_stream_flags)
    assert(ret == xz.LZMA_OK, ret)
    -- Decode index.
    ensure_lseek(fd, -(footer_stream_flags.backward_size + xz.LZMA_STREAM_HEADER_SIZE), C.SEEK_END)
    local index_buf = ffi.gc(ffi.cast("uint8_t *", C.malloc(footer_stream_flags.backward_size)), C.free)
    ensure_read(fd, index_buf, footer_stream_flags.backward_size)
    local index = ffi.new("lzma_index *[1]")
    local memlimit = ffi.new("uint64_t[1]", XZ_INDEX_MEMLIMIT)
    local pos = ffi.new("size_t[1]")
    ret = xz.lzma_index_buffer_decode(index, memlimit, nil, index_buf, pos, footer_stream_flags.backward_size)
    assert(ret == xz.LZMA_OK, ret)
    index = ffi.gc(index[0], free_xz_index)
    assert(xz.lzma_index_stream_count(index) == 1)
    -- Iterate over blocks.
    local entries = {}
    local by_path = {}
    local manifest_entries = {}
    local hashoir = Hashoir:new()
    local index_iter = ffi.new("lzma_index_iter")
    xz.lzma_index_iter_init(index_iter, index)
    while xz.lzma_index_iter_next(index_iter, xz.LZMA_INDEX_ITER_NONEMPTY_BLOCK) == 0 do
        -- Read compressed data.
        ensure_lseek(fd, index_iter.block.compressed_file_offset)
        local comp_size = tonumber(index_iter.block.total_size)
        local comp_buf = ffi.new("uint8_t[?]", comp_size)
        ensure_read(fd, comp_buf, comp_size)
        -- Decode block header.
        local block = ffi.new("lzma_block")
        block.header_size = xz_block_header_size_decode(comp_buf)
        block.check = header_stream_flags.check
        local filters = ffi.new("lzma_filter[?]", xz.LZMA_FILTERS_MAX + 1)
        block.filters = filters
        ret = xz.lzma_block_header_decode(block, nil, comp_buf)
        assert(ret == xz.LZMA_OK, ret)
        assert(block.uncompressed_size == index_iter.block.uncompressed_size)
        ret = xz.lzma_block_compressed_size(block, index_iter.block.unpadded_size)
        assert(ret == xz.LZMA_OK)
        assert(xz.lzma_block_unpadded_size(block) == index_iter.block.unpadded_size)
        assert(xz.lzma_block_total_size(block) == index_iter.block.total_size)
        -- Decompress block.
        local uncomp_size = block.uncompressed_size
        local uncomp_buf = ffi.new("uint8_t[?]", uncomp_size)
        local in_pos = ffi.new("size_t[1]", block.header_size)
        local out_pos = ffi.new("size_t[1]", 0)
        ret = xz.lzma_block_buffer_decode(block, nil, comp_buf, in_pos, comp_size, uncomp_buf, out_pos, uncomp_size)
        assert(ret == xz.LZMA_OK, ret)
        -- Check TAR header.
        local ustar_header = ffi.cast("struct ustar_header *", uncomp_buf)
        if ustar_header.path[0] == 0 then
            -- Empty final block.
            assert(index_iter.block.number_in_file == xz.lzma_index_block_count(index))
            break
        end
        -- We only support the UStar & GNUtar formats.
        -- NOTE: this need to be checked **after** handling the final
        -- empty block, whose header is using the original Unix format.
        assert(C.memcmp(ustar_header.ustar_indicator, FORMAT_GNUTAR, 8) == 0 or
               C.memcmp(ustar_header.ustar_indicator, FORMAT_USTAR, 8) == 0)
        assert(ustar_header.path_prefix[0] == 0)
        local path = ffi.string(ustar_header.path)
        ustar_header.size[11] = 0
        local file_size = tonumber(ffi.string(ustar_header.size, 12), 8)
        assert(tar_size(file_size) == block.uncompressed_size)
        if manifest == path then
            for entry in ffi.string(uncomp_buf + 512, file_size):gmatch("[^\n]+") do
                table.insert(manifest_entries, entry)
            end
        end
        local entry = {
            hash = file_size ~= 0 and hashoir:reset():update(uncomp_buf + 512, file_size):hexdigest() or nil,
            path = path,
            size = tonumber(file_size),
            xz_hash = hashoir:reset():update(comp_buf, comp_size):hexdigest(),
            xz_offset = tonumber(index_iter.block.compressed_file_offset),
            xz_size = tonumber(index_iter.block.unpadded_size),
        }
        table.insert(entries, entry)
        by_path[entry.path] = entry
    end
    if manifest and #manifest_entries == 0 then
        error("manifest entry missing or empty")
    end
    self.header_stream_flags = header_stream_flags
    self.footer_stream_flags = footer_stream_flags
    self.manifest = manifest_entries
    self.entries = entries
    self.by_path = by_path
    return self
end

function TarXz:each()
    local i = 0
    return function()
        i = i + 1
        if i > #self.entries then
            return
        end
        return self.entries[i]
    end
end

function TarXz:reorder(older_tar_xz_or_manifest_path)
    local by_path
    if older_tar_xz_or_manifest_path:match("[.]kotasync$") then
        by_path = {}
        for i, v in ipairs(load_manifest(older_tar_xz_or_manifest_path).files) do
            by_path[v.path] = v
        end
    else
        local older_tar_xz = TarXz:new():open(older_tar_xz_or_manifest_path)
        by_path = older_tar_xz.by_path
        older_tar_xz:close()
    end
    local entries = {}
    for i, e in ipairs(self.entries) do
        if e.size == 0 then
            -- Folder.
            e.sort = {2, e.xz_offset}
        else
            local old = by_path[e.path]
            if old and old.size == e.size and old.hash == e.hash then
                -- Unmodified file.
                e.sort = {1, old.xz_offset}
            else
                -- New/modified file.
                e.sort = {0, e.xz_offset}
            end
        end
        table.insert(entries, e)
    end
    table.sort(entries, function(e1, e2)
        return e1.sort[1] < e2.sort[1] or (e1.sort[1] == e2.sort[1] and e1.sort[2] < e2.sort[2])
    end)
    for i, e in ipairs(entries) do
        e.sort = nil
    end
    return self:rewrite(entries)
end

function TarXz:rewrite(entries)
    local directory = self.filename:match("^(.+)/[^/]+$") or "./"
    local template_size = #directory + 19
    local template = ffi.new("char[?]", template_size, directory.."/XXXXXX.tar.xz.part")
    local fd = C.mkstemps(template, 12)
    if fd < 0 then
        error("mkstemps: "..strerror())
    end
    self.tmpfd = fd
    local stream_buf = ffi.new("uint8_t[?]", xz.LZMA_STREAM_HEADER_SIZE)
    local ret
    -- First: the header.
    ret = xz.lzma_stream_header_encode(self.header_stream_flags, stream_buf)
    assert(ret == xz.LZMA_OK, ret)
    ensure_write(fd, stream_buf, C.LZMA_STREAM_HEADER_SIZE)
    -- Second: the blocks.
    local offset = C.LZMA_STREAM_HEADER_SIZE
    local by_path = {}
    local buf = buffer:new()
    for i, e in ipairs(entries) do
        ensure_lseek(self.fd, e.xz_offset)
        e.xz_offset = offset
        local size = xz_padded_size(e.xz_size)
        for ptr, len in read_fd_blocks_iterator(self.fd, buf, size) do
            ensure_write(fd, ptr, len)
        end
        by_path[e.path] = e
        offset = offset + size
    end
    C.close(self.fd)
    self.fd = nil
    -- Third: the index.
    local index = ffi.gc(xz.lzma_index_init(nil), free_xz_index)
    assert(index ~= nil)
    for i, e in ipairs(entries) do
        ret = xz.lzma_index_append(index, nil, e.xz_size, tar_size(e.size))
        assert(ret == xz.LZMA_OK, ret)
    end
    assert(xz.lzma_index_block_count(index) == #entries)
    local index_size = xz.lzma_index_size(index)
    local index_buf = ffi.new("uint8_t[?]", index_size)
    local pos = ffi.new("size_t[1]")
    ret = xz.lzma_index_buffer_encode(index, index_buf, pos, index_size)
    assert(ret == xz.LZMA_OK, ret)
    ensure_write(fd, index_buf, index_size)
    -- Finally: the footer.
    self.footer_stream_flags.backward_size = index_size
    ret = xz.lzma_stream_footer_encode(self.footer_stream_flags, stream_buf)
    assert(ret == xz.LZMA_OK, ret)
    ensure_write(fd, stream_buf, C.LZMA_STREAM_HEADER_SIZE)
    -- Rename temporary file and update internal state.
    local ok, err = os.rename(ffi.string(template, template_size), self.filename)
    if not ok then
        error(err)
    end
    self.entries = entries
    self.by_path = by_path
    self.fd = fd
    self.tmpfd = nil
    return self
end

-- }}}

-- Updater. {{{

local Updater = {}

function Updater:new(state_dir, dl)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    local Downloader = require("ffi/downloader")
    o.dl = dl or Downloader:new()
    o.own_dl = dl ~= nil
    o.state_dir = state_dir
    o.update_url = nil
    o.manifest = nil
    o.missing = nil
    o.fd = nil
    return o
end

function Updater:free()
    if self.fd then
        C.close(self.fd)
        self.fd = nil
    end
    if self.own_dl then
        self.dl:free()
    end
    self.dl = nil
    self.missing = nil
    self.manifest = nil
    self.state_dir = nil
    self.update_url = nil
end

function Updater:fetch_manifest(manifest_url)
    local url = require("socket.url")
    local url_path = url.parse(manifest_url).path
    local basename = table.remove(url.parse_path(url_path))
    local manifest_file = self.state_dir.."/"..basename
    local etag_file = manifest_file..".etag"
    local manifest, etag
    -- Load existing manifest if present in state directory.
    if lfs.attributes(manifest_file, "mode") == "file" then
        local ok, ret = pcall(load_manifest, manifest_file)
        if ok then
            manifest = ret
        end
    end
    -- And the associated ETag if applicable.
    if manifest and lfs.attributes(etag_file, "mode") == "file" then
        etag = io.lines(etag_file)()
    end
    -- Try fetching an updated version.
    local buf = buffer:new()
    if not self.dl:fetch(manifest_url, function(ptr, len)
        buf:putcdata(ptr, len)
        return true
    end, nil, etag) then
        error(self.dl.err)
    end
    if self.dl.status_code ~= 304 then -- 304: Not Modified.
        local ptr, len = buf:ref()
        manifest = deserialize_manifest(ptr, len)
        save_manifest(manifest_file, manifest, 3)
        -- Update ETag file.
        if self.dl.etag then
            local fp = io.open(etag_file, "w")
            fp:write(self.dl.etag)
            fp:close()
        else
            os.remove(etag_file)
        end
    end
    self.manifest = manifest
    self.update_url = url.absolute(manifest_url, manifest.filename)
    return manifest.filename
end

function Updater:prepare_update(seed, progress_cb)
    local missing_files = {}
    local reused_size = 0
    local download_size = 0
    local matches = function(e)
        return false
    end
    if seed then
        if type(seed) == "table" then
            matches = function(e)
                local se = seed[e.path]
                return se and se.size == e.size and se.hash == e.hash
            end
        else
            assert(lfs.attributes(seed, "mode") == "directory")
            matches = function(e)
                return path_matches(seed.."/"..e.path, e.size, e.hash)
            end
        end
    end
    for i, e in ipairs(self.manifest.files) do
        if matches(e) then
            reused_size = reused_size + e.size
        else
            download_size = download_size + xz_padded_size(e.xz_size)
            table.insert(missing_files, e)
        end
        if progress_cb and not progress_cb(i) then
            -- Canceled.
            return
        end
    end
    self.missing_files = missing_files
    return {
        missing_files = #self.missing_files,
        total_files = #self.manifest.files,
        reused_size = reused_size,
        download_size = download_size
    }
end

function Updater:download_update(progress_cb)
    if #self.missing_files == 0 then
        -- Nothing to update!
        return
    end
    local update_file = self.state_dir.."/update.tar.xz"
    os.remove(update_file)
    local fd = ensure_create(update_file..".part")
    self.fd = fd
    local stream_buf = ffi.new("uint8_t[?]", xz.LZMA_STREAM_HEADER_SIZE)
    local ret
    -- Write header.
    local header_stream_flags = ffi.new("lzma_stream_flags")
    header_stream_flags.check = self.manifest.xz_check
    ret = xz.lzma_stream_header_encode(header_stream_flags, stream_buf)
    assert(ret == xz.LZMA_OK, ret)
    ensure_write(fd, stream_buf, C.LZMA_STREAM_HEADER_SIZE)
    local missing = self.missing_files
    local offset = xz.LZMA_STREAM_HEADER_SIZE
    local ranges = {}
    for i, e in ipairs(missing) do
        e.new_xz_start = offset
        local size = xz_padded_size(e.xz_size)
        table.insert(ranges, {e.xz_offset, e.xz_offset + size - 1})
        offset = offset + size
    end
    local index_offset = offset
    -- Ensure we have enough disk space.
    ret = C.posix_fallocate(fd, 0, offset + XZ_INDEX_MAXSIZE + xz.LZMA_STREAM_HEADER_SIZE)
    if ret ~= 0 then
        error("posix_fallocate: "..strerror(ret))
    end
    -- Fetch & write missing blocks.
    local hashoir = Hashoir:new()
    local entry_index = 0
    local entry_left = 0
    local entry_path
    local entry
    local downloaded = 0
    if not self.dl:fetch(self.update_url, function(ptr, len)
        downloaded = downloaded + len
        while len > 0 do
            if not entry then
                entry_index = entry_index + 1
                entry = missing[entry_index]
                entry_path = entry.path
                ensure_lseek(fd, entry.new_xz_start)
                entry_left = xz_padded_size(entry.xz_size)
                hashoir:reset()
            end
            local count = math.min(entry_left, len)
            hashoir:update(ptr, count)
            ensure_write(fd, ptr, count)
            entry_left = entry_left - count
            assert(entry_left >= 0)
            if entry_left == 0 then
                if entry.xz_hash ~= hashoir:hexdigest() then
                    error("corrupted entry: "..entry_path)
                end
                entry = nil
            end
            ptr = ptr + count
            len = len - count
        end
        if progress_cb and not progress_cb(downloaded, entry_index, entry_path) then
            return false
        end
        return true
    end, ranges) then
        return false, self.dl.err
    end
    -- Write index.
    ensure_lseek(fd, index_offset)
    local index = ffi.gc(xz.lzma_index_init(nil), free_xz_index)
    for i, e in ipairs(missing) do
        ret = xz.lzma_index_append(index, nil, e.xz_size, tar_size(e.size))
        assert(ret == xz.LZMA_OK, ret)
    end
    local index_size = xz.lzma_index_size(index)
    local index_buf = ffi.new("uint8_t[?]", index_size)
    local pos = ffi.new("size_t[1]")
    ret = xz.lzma_index_buffer_encode(index, index_buf, pos, index_size)
    assert(ret == xz.LZMA_OK, ret)
    ensure_write(fd, index_buf, index_size)
    -- Write footer.
    local footer_stream_flags = ffi.new("lzma_stream_flags")
    footer_stream_flags.backward_size = index_size
    footer_stream_flags.check = self.manifest.xz_check
    ret = xz.lzma_stream_footer_encode(footer_stream_flags, stream_buf)
    assert(ret == xz.LZMA_OK, ret)
    ensure_write(fd, stream_buf, C.LZMA_STREAM_HEADER_SIZE)
    -- Finalize.
    ret = C.ftruncate(fd, ensure_lseek(fd, 0, C.SEEK_CUR))
    if ret ~= 0 then
        error("ftruncate: "..strerror())
    end
    C.close(fd)
    self.fd = nil
    local ok, err = os.rename(update_file..".part", update_file)
    if not ok then
        error(err)
    end
end

function Updater:download_update_in_subprocess(progress_cb, progress_frequency)
    assert(progress_cb and progress_frequency)
    local util = require("ffi/util")
    local child, read_fd = util.runInSubProcess(function(pid, write_fd)
        local last_update = 0
        local msg_len = ffi.new('uint16_t[1]')
        local buf = buffer:new()
        local send = function(...)
            buf:reset():encode{...}
            msg_len[0] = #buf
            ensure_write(write_fd, msg_len, 2)
            local ptr = buf:ref()
            ensure_write(write_fd, ptr, msg_len[0])
        end
        local ok, err = pcall(self.download_update, self, function(size, count, path)
            local new_update = util.getTimestamp()
            if new_update - last_update >= progress_frequency then
                last_update = new_update
                send(false, size, count, path)
            end
            return true
        end)
        send(true, ok, err)
    end, true)
    if not child then
        -- read_fd: error message
        return child, read_fd
    end
    local msg_len = ffi.new('uint16_t[1]')
    local buf = buffer:new()
    while true do
        ensure_read(read_fd, msg_len, 2)
        local ptr = buf:reserve(msg_len[0])
        ensure_read(read_fd, ptr, msg_len[0])
        buf:commit(msg_len[0])
        local msg = buf:decode()
        if msg[1] then
            -- It's done.
            util.isSubProcessDone(child, true)
            return msg[2], msg[3]
        end
        if not progress_cb(msg[2], msg[3], msg[4]) then
            -- Canceled.
            C.kill(-child, 15)
            util.isSubProcessDone(child, true)
            return false
        end
    end
end

-- }}}

return {
    load_manifest = load_manifest,
    save_manifest = save_manifest,
    TarXz = TarXz,
    Updater = Updater,
}
