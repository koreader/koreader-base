local Downloader = require("ffi/downloader")
local Hashoir = require("ffi/hashoir")
local buffer = require("string.buffer")
local ffi = require("ffi")
local lfs = require("libs/libkoreader-lfs")
local rapidjson = require("rapidjson")
local url = require("socket.url")
local util = require("ffi/util")
local zstd = require("ffi/zstd")

require "ffi/posix_h"

assert(ffi.abi("le"), "big-endian architecture")

local BLOCK_SIZE = 8 * 1024
local C = ffi.C

-- POSIX helpers. {{{

local function strerror(err)
    return ffi.string(C.strerror(err or ffi.errno()))
end

local function ensure_create(path, mode)
    local fd = C.open(path, C.O_CREAT + C.O_WRONLY + C.O_TRUNC, ffi.cast("mode_t", mode or (C.S_IRUSR + C.S_IWUSR + C.S_IRGRP + C.S_IROTH)))
    if fd < 0 then
        error(strerror())
    end
    return fd
end

local function ensure_lseek(fd, offset, whence)
    local ret = C.lseek(fd, offset, whence or C.SEEK_SET)
    if ret < 0 then
        error(strerror())
    end
    return ret
end

local function ensure_read(fd, ptr, len)
    local ret = C.read(fd, ptr, len)
    if ret ~= len then
        error(ret < 0 and strerror() or "short read")
    end
    return ret
end

local function ensure_write(fd, ptr, len)
    local ret = C.write(fd, ptr, len)
    if ret ~= len then
        error(ret < 0 and strerror() or "short write")
    end
    return ret
end

-- }}}

-- File hashing. {{{

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
    local fd = C.open(path, C.O_RDONLY)
    if fd < 0 then
        error(strerror())
    end
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

-- ZIP format helpers. {{{

ffi.cdef[[
struct __attribute__((packed)) zip_lfh {
    uint32_t signature;
    uint16_t min_ver;
    uint16_t flags;
    uint16_t compression;
    uint16_t mtime;
    uint16_t mdate;
    uint32_t crc32;
    uint32_t packed_size;
    uint32_t unpacked_size;
    uint16_t filename_len;
    uint16_t extra_field_len;
};

struct __attribute__((packed)) zip_cdfh {
    uint32_t signature;
    uint16_t version;
    uint16_t min_ver;
    uint16_t flags;
    uint16_t compression;
    uint16_t mtime;
    uint16_t mdate;
    uint32_t crc32;
    uint32_t packed_size;
    uint32_t unpacked_size;
    uint16_t filename_len;
    uint16_t extra_field_len;
    uint16_t comment_len;
    uint16_t disk_num;
    uint16_t internal_fattrs;
    uint32_t external_fattrs;
    uint32_t offset;
};

struct __attribute__((packed)) zip_eocd {
    uint32_t signature;
    uint16_t nb_disks;
    uint16_t disk_num;
    uint16_t disk_recs;
    uint16_t total_recs;
    uint32_t cdir_size;
    uint32_t cdir_offset;
    uint16_t comment_len;
};

enum {
    ZIP_LFH_SIGNATURE  = 0x04034b50,
    ZIP_CDFH_SIGNATURE = 0x02014b50,
    ZIP_EOCD_SIGNATURE = 0x06054b50,
};

enum {
    ZIP_LFH_SIZE  = sizeof (struct zip_lfh),
    ZIP_CDFH_SIZE = sizeof (struct zip_cdfh),
    ZIP_EOCD_SIZE = sizeof (struct zip_eocd),
};
]]

local function zip_cdir_iterator(ptr, len)
    return function()
        assert(len >= 0)
        if len == 0 then
            return
        end
        local cdfh = ffi.cast("struct zip_cdfh *", ptr)
        assert(cdfh.signature == C.ZIP_CDFH_SIGNATURE, cdfh.signature)
        local size = C.ZIP_CDFH_SIZE + cdfh.filename_len + cdfh.extra_field_len + cdfh.comment_len
        ptr = ptr + size
        len = len - size
        return cdfh, size
    end
end

-- }}}

-- ZipSync manifest deserialization / serialization. {{{

local function deserialize_zipsync(ptr, len)
    ptr, len = zstd.zstd_uncompress(ptr, len)
    local manifest = rapidjson.decode(ffi.string(ptr, len))
    C.free(ffi.gc(ptr, nil))
    assert(manifest)
    return manifest
end

local function load_zipsync(path)
    local len = lfs.attributes(path, "size")
    local fd = C.open(path, C.O_RDONLY)
    if fd < 0 then
        error(strerror())
    end
    local buf = buffer:new()
    local ptr = buf:reserve(len)
    local ret = C.read(fd, ptr, len)
    local err = ffi.errno()
    C.close(fd)
    if ret ~= len then
        error(ret < 0 and strerror(err) or "short read")
    end
    return deserialize_zipsync(ptr, len)
end

local function serialize_zipsync(manifest, compression_level)
    local data = rapidjson.encode(manifest, {sort_keys = true})
    assert(data)
    local ptr, len = zstd.zstd_compress(data, #data, compression_level or 19)
    ptr = ffi.gc(ptr, C.free)
    return ptr, len
end

local function save_zipsync(path, manifest, compression_level)
    local ptr, len = serialize_zipsync(manifest, compression_level)
    local fd = ensure_create(path)
    if fd < 0 then
        C.free(ffi.gc(ptr, nil))
        error(strerror())
    end
    local ret = C.write(fd, ptr, len)
    C.free(ffi.gc(ptr, nil))
    C.close(fd)
    if ret ~= len then
        error(ret < 0 and strerror() or "short write")
    end
end

-- }}}

-- ZipSyncUpdater. {{{

local ZipSyncUpdater = {}

function ZipSyncUpdater:new(state_dir, dl)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.dl = dl or Downloader:new()
    o.own_dl = dl ~= nil
    o.state_dir = state_dir
    o.update_url = nil
    o.manifest = nil
    o.missing = nil
    o.fd = nil
    return o
end

function ZipSyncUpdater:free()
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

function ZipSyncUpdater:fetch_manifest(zipsync_url)
    local url_path = url.parse(zipsync_url).path
    local basename = table.remove(url.parse_path(url_path))
    local zipsync_file = self.state_dir.."/"..basename
    local etag_file = zipsync_file..".etag"
    local manifest, etag
    -- Load existing manifest if present in state directory.
    if lfs.attributes(zipsync_file, "mode") == "file" then
        local ok, ret = pcall(load_zipsync, zipsync_file)
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
    if not self.dl:fetch(zipsync_url, function(ptr, len)
        buf:putcdata(ptr, len)
        return true
    end, nil, etag) then
        error(self.dl.err)
    end
    if self.dl.status_code ~= 304 then -- 304: Not Modified.
        local ptr, len = buf:ref()
        manifest = deserialize_zipsync(ptr, len)
        save_zipsync(zipsync_file, manifest, 3)
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
    self.update_url = url.absolute(zipsync_url, manifest.filename)
    return manifest.filename
end

function ZipSyncUpdater:prepare_update(syncdir, progress_cb)
    local missing_files = {}
    local reused_size = 0
    local download_size = 0
    for i, e in ipairs(self.manifest.files) do
        if syncdir and path_matches(syncdir.."/"..e.path, e.size, e.hash) then
            reused_size = reused_size + e.size
        else
            download_size = download_size + e.zip_stop - e.zip_start + 1
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

function ZipSyncUpdater:download_update(progress_cb)
    if #self.missing_files == 0 then
        -- Nothing to update!
        return
    end
    local update_file = self.state_dir.."/update.zip"
    os.remove(update_file)
    local missing = self.missing_files
    assert(self.manifest.zip_cdir_stop - self.manifest.zip_cdir_start > #missing * C.ZIP_CDFH_SIZE)
    local cdir = {
        zip_start = self.manifest.zip_cdir_start,
        zip_stop = self.manifest.zip_cdir_stop,
        zip_hash = self.manifest.zip_cdir_hash,
    }
    table.insert(missing, cdir)
    local offset = 0
    local ranges = {}
    for i, e in ipairs(missing) do
        e.new_zip_start = offset
        table.insert(ranges, {e.zip_start, e.zip_stop})
        offset = offset + e.zip_stop - e.zip_start + 1
    end
    -- Fetch missing entries + central directory.
    local raw_cdir_size = self.manifest.zip_cdir_stop - self.manifest.zip_cdir_start + 1
    local raw_cdir = ffi.gc(ffi.cast("uint8_t *", C.malloc(raw_cdir_size)), C.free)
    local raw_cdir_pos = 0
    local fd = ensure_create(update_file..".part")
    self.fd = fd
    -- Ensure we have enough disk space.
    local ret = C.posix_fallocate(fd, 0, cdir.new_zip_start + cdir.zip_stop - cdir.zip_start + 1 + C.ZIP_EOCD_SIZE)
    if ret ~= 0 then
        error(strerror(ret))
    end
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
                ensure_lseek(fd, entry.new_zip_start)
                entry_left = entry.zip_stop - entry.zip_start + 1
                hashoir:reset()
            end
            local count = math.min(entry_left, len)
            hashoir:update(ptr, count)
            if entry == cdir then
                assert(raw_cdir_pos + count <= raw_cdir_size)
                ffi.copy(raw_cdir + raw_cdir_pos, ptr, count)
                raw_cdir_pos = raw_cdir_pos + count
            else
                ensure_write(fd, ptr, count)
            end
            entry_left = entry_left - count
            assert(entry_left >= 0)
            if entry_left == 0 then
                if entry.zip_hash ~= hashoir:hexdigest() then
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
    assert(raw_cdir_pos == raw_cdir_size)
    -- Write an updated central directory with only
    -- the files we fetched (updating their offsets).
    ensure_lseek(fd, cdir.new_zip_start)
    entry_index = 0
    entry = nil
    for cdfh, size in zip_cdir_iterator(raw_cdir, raw_cdir_size) do
        if not entry then
            entry_index = entry_index + 1
            entry = missing[entry_index]
            if not entry then
                -- We're done: all remaining central
                -- directory entries don't concern us.
                break
            end
        end
        if cdfh.offset == entry.zip_start then
            -- One of ours!
            cdfh.offset = entry.new_zip_start
            ensure_write(fd, cdfh, size)
            entry = nil
        end
    end
    -- Write the end of central directory.
    local eocd = ffi.new("struct zip_eocd")
    eocd.signature = C.ZIP_EOCD_SIGNATURE
    eocd.nb_disks = 0
    eocd.disk_num = 0
    eocd.disk_recs = #missing - 1
    eocd.total_recs = #missing - 1
    eocd.cdir_size = ensure_lseek(fd, 0, C.SEEK_CUR) - cdir.new_zip_start
    eocd.cdir_offset = cdir.new_zip_start
    eocd.comment_len = 0
    ensure_write(fd, eocd, C.ZIP_EOCD_SIZE)
    ret = C.ftruncate(fd, ensure_lseek(fd, 0, C.SEEK_CUR))
    if ret ~= 0 then
        error(strerror())
    end
    C.close(fd)
    self.fd = nil
    local ok, err = os.rename(update_file..".part", update_file)
    if not ok then
        error(err)
    end
end

function ZipSyncUpdater:download_update_in_subprocess(progress_cb, progress_frequency)
    assert(progress_cb and progress_frequency)
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
    load_zipsync = load_zipsync,
    save_zipsync = save_zipsync,
    Updater = ZipSyncUpdater,
}

-- vim: foldmethod=marker foldlevel=0
