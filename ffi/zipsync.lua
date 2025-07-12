local Hashoir = require("ffi/hashoir")
local buffer = require("string.buffer")
local ffi = require("ffi")
local json = require("dkjson")
local lfs = require("libs/libkoreader-lfs")
local url = require("socket.url")
local util = require("ffi/util")
local zstd = require("ffi/zstd")

require "ffi/libarchive_h"
require "ffi/posix_h"

assert(ffi.abi("le"), "big-endian architecture")

local BLOCK_SIZE = 16 * 1024
local C = ffi.C

-- POSIX helpers. {{{

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
    return ensure_open(path, C.O_CREAT + C.O_WRONLY + C.O_TRUNC, mode or (C.S_IRUSR + C.S_IWUSR + C.S_IRGRP + C.S_IROTH))
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
        error("read: "..(ret < 0 and strerror() or "short read"))
    end
    return ret
end

local function ensure_write(fd, ptr, len)
    local ret = C.write(fd, ptr, len)
    if ret ~= len then
        error("write: "..(ret < 0 and strerror() or "short write"))
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

-- ZIP format helpers. {{{

ffi.cdef[[
struct __attribute__((packed)) zip_lfh {
    uint32_t  signature;
    uint16_t  min_ver;
    uint16_t  flags;
    uint16_t  compression;
    uint16_t  mtime;
    uint16_t  mdate;
    uint16_t  __pad1;
    uint32_t  crc32;
    uint32_t  packed_size;
    uint32_t  unpacked_size;
    uint16_t  filename_len;
    uint16_t  extra_field_len;
    char     *filename;
    uint8_t  *extra_field;
};

enum {
    ZIP_LFH_SIGNATURE    = 0x04034b50,
    ZIP_LFH_PART1_SIZE   = 1 * 4 + 2 * 5,
    ZIP_LFH_PART2_OFFSET = ZIP_LFH_PART1_SIZE + 2,
    ZIP_LFH_PART2_SIZE   = 3 * 4 + 2 * 2,
    ZIP_LFH_SIZE         = ZIP_LFH_PART1_SIZE + ZIP_LFH_PART2_SIZE,
};

struct __attribute__((packed)) zip_cdfh {
    uint32_t  signature;
    uint16_t  version;
    uint16_t  min_ver;
    uint16_t  flags;
    uint16_t  compression;
    uint16_t  mtime;
    uint16_t  mdate;
    uint32_t  crc32;
    uint32_t  packed_size;
    uint32_t  unpacked_size;
    uint16_t  filename_len;
    uint16_t  extra_field_len;
    uint16_t  comment_len;
    uint16_t  disk_num;
    uint16_t  internal_fattrs;
    uint16_t  __pad1;
    uint32_t  external_fattrs;
    uint32_t  offset;
    char     *filename;
    uint8_t  *extra_field;
    char     *comment;
};

enum {
    ZIP_CDFH_SIGNATURE    = 0x02014b50,
    ZIP_CDFH_PART1_SIZE   = 1 * 4 + 6 * 2 + 3 * 4 + 5 * 2,
    ZIP_CDFH_PART2_OFFSET = ZIP_CDFH_PART1_SIZE + 2,
    ZIP_CDFH_PART2_SIZE   = 2 * 4,
    ZIP_CDFH_SIZE         = ZIP_CDFH_PART1_SIZE + ZIP_CDFH_PART2_SIZE,
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
    ZIP_EOCD_SIGNATURE = 0x06054b50,
    ZIP_EOCD_SIZE      = sizeof (struct zip_eocd),
};
]]

local function free_zip_lfh(lfh)
    ffi.gc(lfh, nil)
    C.free(lfh.filename)
    C.free(lfh.extra_field)
end

local function read_zip_lfh(fd)
    local lfh = ffi.gc(ffi.new("struct zip_lfh"), free_zip_lfh)
    local iov = ffi.new("struct iovec[2]")
    local iovcnt = 2
    local size = C.ZIP_LFH_SIZE
    local ret
    iov[0].iov_base = lfh
    iov[0].iov_len = C.ZIP_LFH_PART1_SIZE
    iov[1].iov_base = ffi.cast("uint8_t *", lfh) + C.ZIP_LFH_PART2_OFFSET
    iov[1].iov_len = C.ZIP_LFH_PART2_SIZE
    ret = C.readv(fd, iov, iovcnt)
    if ret ~= size then
        error("readv: "..(ret < 0 and strerror() or "short read"))
    end
    assert(lfh.signature == C.ZIP_LFH_SIGNATURE, lfh.signature)
    assert(lfh.filename_len > 0)
    lfh.filename = C.malloc(lfh.filename_len)
    iov[0].iov_base = lfh.filename
    iov[0].iov_len = lfh.filename_len
    iovcnt = 1
    size = lfh.filename_len
    if lfh.extra_field_len > 0 then
        lfh.extra_field = C.malloc(lfh.extra_field_len)
        iov[iovcnt].iov_base = lfh.extra_field
        iov[iovcnt].iov_len = lfh.extra_field_len
        iovcnt = iovcnt + 1
        size = size + lfh.extra_field_len
    end
    ret = C.readv(fd, iov, iovcnt)
    if ret ~= size then
        error("readv: "..(ret < 0 and strerror() or "short read"))
    end
    return lfh
end

local function write_zip_lfh(fd, lfh)
    local iov = ffi.new("struct iovec[4]")
    local iovcnt = 3
    local size = C.ZIP_LFH_SIZE + lfh.filename_len
    local ret
    assert(lfh.signature == C.ZIP_LFH_SIGNATURE, lfh.signature)
    assert(lfh.filename_len > 0)
    iov[0].iov_base = lfh
    iov[0].iov_len = C.ZIP_LFH_PART1_SIZE
    iov[1].iov_base = ffi.cast("uint8_t *", lfh) + C.ZIP_LFH_PART2_OFFSET
    iov[1].iov_len = C.ZIP_LFH_PART2_SIZE
    iov[2].iov_base = lfh.filename
    iov[2].iov_len = lfh.filename_len
    if lfh.extra_field_len > 0 then
        iov[iovcnt].iov_base = lfh.extra_field
        iov[iovcnt].iov_len = lfh.extra_field_len
        iovcnt = iovcnt + 1
        size = size + lfh.extra_field_len
    end
    ret = C.writev(fd, iov, iovcnt)
    if ret ~= size then
        error("writev: "..(ret < 0 and strerror() or "short write"))
    end
    return C.ZIP_LFH_SIZE + lfh.filename_len + lfh.extra_field_len
end

local function free_zip_cdfh(cdfh)
    ffi.gc(cdfh, nil)
    C.free(cdfh.filename)
    C.free(cdfh.extra_field)
    C.free(cdfh.comment)
end

local function unpack_zip_cdfh(ptr)
    local cdfh = ffi.new("struct zip_cdfh")
    ffi.copy(cdfh, ptr, C.ZIP_CDFH_PART1_SIZE)
    assert(cdfh.signature == C.ZIP_CDFH_SIGNATURE, cdfh.signature)
    assert(cdfh.filename_len > 0)
    ffi.copy(ffi.cast("uint8_t *", cdfh) + C.ZIP_CDFH_PART2_OFFSET, ptr + C.ZIP_CDFH_PART1_SIZE, C.ZIP_CDFH_PART2_SIZE)
    cdfh.filename = ptr + C.ZIP_CDFH_SIZE
    cdfh.extra_field = cdfh.filename + cdfh.filename_len
    cdfh.comment = cdfh.extra_field + cdfh.extra_field_len
    return cdfh
end

local function read_zip_cdfh(fd)
    local cdfh = ffi.gc(ffi.new("struct zip_cdfh"), free_zip_cdfh)
    local iov = ffi.new("struct iovec[3]")
    local iovcnt = 2
    local size = C.ZIP_CDFH_SIZE
    local ret
    iov[0].iov_base = cdfh
    iov[0].iov_len = C.ZIP_CDFH_PART1_SIZE
    iov[1].iov_base = ffi.cast("uint8_t *", cdfh) + C.ZIP_CDFH_PART2_OFFSET
    iov[1].iov_len = C.ZIP_CDFH_PART2_SIZE
    ret = C.readv(fd, iov, iovcnt)
    if ret ~= size then
        error("readv: "..(ret < 0 and strerror() or "short read"))
    end
    assert(cdfh.signature == C.ZIP_CDFH_SIGNATURE, cdfh.signature)
    assert(cdfh.filename_len > 0)
    cdfh.filename = C.malloc(cdfh.filename_len)
    iov[0].iov_base = cdfh.filename
    iov[0].iov_len = cdfh.filename_len
    iovcnt = 1
    size = cdfh.filename_len
    if cdfh.extra_field_len > 0 then
        cdfh.extra_field = C.malloc(cdfh.extra_field_len)
        iov[iovcnt].iov_base = cdfh.extra_field
        iov[iovcnt].iov_len = cdfh.extra_field_len
        iovcnt = iovcnt + 1
        size = size + cdfh.extra_field_len
    end
    if cdfh.comment_len > 0 then
        cdfh.comment = C.malloc(cdfh.comment_len)
        iov[iovcnt].iov_base = cdfh.comment
        iov[iovcnt].iov_len = cdfh.comment_len
        iovcnt = iovcnt + 1
        size = size + cdfh.comment_len
    end
    ret = C.readv(fd, iov, iovcnt)
    if ret ~= size then
        error("readv: "..(ret < 0 and strerror() or "short read"))
    end
    return cdfh
end

local function write_zip_cdfh(fd, cdfh)
    local iov = ffi.new("struct iovec[5]")
    local iovcnt = 3
    local size = C.ZIP_CDFH_SIZE + cdfh.filename_len
    local ret
    assert(cdfh.signature == C.ZIP_CDFH_SIGNATURE, cdfh.signature)
    assert(cdfh.filename_len > 0)
    iov[0].iov_base = cdfh
    iov[0].iov_len = C.ZIP_CDFH_PART1_SIZE
    iov[1].iov_base = ffi.cast("uint8_t *", cdfh) + C.ZIP_CDFH_PART2_OFFSET
    iov[1].iov_len = C.ZIP_CDFH_PART2_SIZE
    iov[2].iov_base = cdfh.filename
    iov[2].iov_len = cdfh.filename_len
    if cdfh.extra_field_len > 0 then
        iov[iovcnt].iov_base = cdfh.extra_field
        iov[iovcnt].iov_len = cdfh.extra_field_len
        iovcnt = iovcnt + 1
        size = size + cdfh.extra_field_len
    end
    if cdfh.comment_len > 0 then
        iov[iovcnt].iov_base = cdfh.comment
        iov[iovcnt].iov_len = cdfh.comment_len
        iovcnt = iovcnt + 1
        size = size + cdfh.comment_len
    end
    ret = C.writev(fd, iov, iovcnt)
    if ret ~= size then
        error("writev: "..(ret < 0 and strerror() or "short write"))
    end
    return C.ZIP_CDFH_SIZE + cdfh.filename_len + cdfh.extra_field_len + cdfh.comment_len
end

local function zip_cdir_iterator(ptr, len)
    return function()
        assert(len >= 0)
        if len == 0 then
            return
        end
        local cdfh = unpack_zip_cdfh(ptr)
        assert(cdfh.signature == C.ZIP_CDFH_SIGNATURE, cdfh.signature)
        local size = C.ZIP_CDFH_SIZE + cdfh.filename_len + cdfh.extra_field_len + cdfh.comment_len
        ptr = ptr + size
        len = len - size
        return cdfh
    end
end

-- }}}

-- ZipSync manifest deserialization / serialization. {{{

local function deserialize_zipsync(ptr, len)
    ptr, len = zstd.zstd_uncompress(ptr, len)
    local manifest = json.decode(ffi.string(ptr, len))
    C.free(ffi.gc(ptr, nil))
    assert(manifest)
    return manifest
end

local function load_zipsync(path)
    local len = lfs.attributes(path, "size")
    local fd = ensure_open(path)
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
    local data = json.encode(manifest, {keyorder = {
        "filename", "files", "hash", "path", "size", "zip_cdir_hash",
        "zip_cdir_start", "zip_cdir_stop", "zip_hash", "zip_start", "zip_stop",
    }})
    assert(data)
    local ptr, len = zstd.zstd_compress(data, #data, compression_level or 19)
    return ffi.gc(ptr, C.free), len
end

local function save_zipsync(path, manifest, compression_level)
    local ptr, len = serialize_zipsync(manifest, compression_level)
    local fd = ensure_create(path)
    ensure_write(fd, ptr, len)
    C.free(ffi.gc(ptr, nil))
    C.close(fd)
end

-- }}}

-- ZipArchive. {{{

local ZipArchive = {}

function ZipArchive:new(filename)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    if filename then
        o:open(filename)
    end
    return o
end

function ZipArchive:open(filename)
    self:close()
    self.filename = filename
    local fd = ensure_open(filename)
    self.fd = fd
    local eocd = ffi.new("struct zip_eocd")
    ensure_lseek(fd, -C.ZIP_EOCD_SIZE, C.SEEK_END)
    ensure_read(fd, eocd, C.ZIP_EOCD_SIZE)
    assert(eocd.signature == C.ZIP_EOCD_SIGNATURE)
    assert(eocd.nb_disks == 0)
    assert(eocd.disk_num == 0)
    ensure_lseek(fd, eocd.cdir_offset)
    -- Central directory.
    local entry
    local entries = {}
    local by_path = {}
    local size = eocd.cdir_size
    while size > C.ZIP_CDFH_SIZE do
        local cdfh = read_zip_cdfh(fd)
        assert(cdfh.offset < eocd.cdir_offset)
        local offset = tonumber(cdfh.offset)
        -- Update previous end offset.
        if entry then
            entry.zip_stop = offset - 1
        end
        -- Ignore directories.
        entry = {
            cdfh = cdfh,
            path = ffi.string(cdfh.filename, cdfh.filename_len),
            size = tonumber(cdfh.unpacked_size),
            zip_start = offset,
        }
        table.insert(entries, entry)
        by_path[entry.path] = entry
        size = size - C.ZIP_CDFH_SIZE - cdfh.filename_len - cdfh.extra_field_len - cdfh.comment_len
        assert(size >= 0, size)
    end
    if entry then
        entry.zip_stop = eocd.cdir_offset - 1
    end
    -- Local directory.
    for i, e in ipairs(entries) do
        ensure_lseek(fd, e.zip_start)
        local lfh = read_zip_lfh(fd)
        assert(lfh.flags == e.cdfh.flags)
        assert(lfh.crc32 == e.cdfh.crc32)
        assert(lfh.packed_size == e.cdfh.packed_size)
        assert(lfh.unpacked_size == e.cdfh.unpacked_size)
        assert(lfh.filename_len == e.cdfh.filename_len)
        e.lfh = lfh
    end
    self.eocd = eocd
    self.entries = entries
    self.by_path = by_path
end

function ZipArchive:each()
    local i = 0
    return function()
        i = i + 1
        if i > #self.entries then
            return
        end
        return self.entries[i]
    end
end

function ZipArchive:hash(start, stop)
    assert(stop >= start)
    ensure_lseek(self.fd, start)
    local buf = buffer:new()
    local hashoir = Hashoir:new()
    for ptr, len in read_fd_blocks_iterator(self.fd, buf, stop - start + 1) do
        hashoir:update(ptr, len)
    end
    return hashoir:hexdigest()
end

function ZipArchive:hash_packed(e)
    if e.zip_hash then
        return e.zip_hash
    end
    e.zip_hash = self:hash(e.zip_start, e.zip_stop)
    return e.zip_hash
end

function ZipArchive:hash_unpacked(e)
    if e.hash then
        return e.hash
    end
    if e.cdfh.compression == 0 then
        -- Stored.
        local start = e.zip_start + C.ZIP_LFH_SIZE + e.lfh.filename_len + e.lfh.extra_field_len
        local stop = start + e.size - 1
        assert(stop <= e.zip_stop)
        e.hash = self:hash(start, stop)
        return e.hash
    end
    if not self.archive then
        local archiver = require("ffi/archiver")
        self.archive = archiver.Reader:new()
        if not self.archive:open(self.filename) then
            error(self.archive.err)
        end
        for entry in self.archive:iterate() do end
    end
    local hashoir = Hashoir:new()
    for ptr, len in self.archive:extractIterator(e.path) do
        hashoir:update(ptr, len)
    end
    if self.archive.err then
        error(self.archive.err)
    end
    e.hash = hashoir:hexdigest()
    return e.hash
end

function ZipArchive:reorder(older_zip_or_zipsync_path)
    local matches
    if older_zip_or_zipsync_path:match("[.]zipsync$") then
        local by_path = {}
        for i, v in ipairs(load_zipsync(older_zip_or_zipsync_path).files) do
            by_path[v.path] = v
        end
        matches = function(new)
            local old = by_path[new.path]
            return old and old.size == new.size and old.hash == new.hash and old.zip_start
        end
    else
        local zip = ZipArchive:new(older_zip_or_zipsync_path)
        matches = function(new)
            local old = zip.by_path[new.path]
            return old and old.size == new.size and zip:hash_unpacked(old) == new.hash and old.zip_start
        end
    end
    local entries = {}
    for i, e in ipairs(self.entries) do
        if e.size == 0 then
            -- Folder.
            e.sort = {0, e.cdfh.offset}
        else
            self:hash_unpacked(e)
            local old_offset = matches(e)
            if old_offset then
                -- Unmodified file.
                e.sort = {1, old_offset}
            else
                -- New/modified file.
                e.sort = {2, e.cdfh.offset}
            end
        end
        table.insert(entries, e)
    end
    table.sort(entries, function(e1, e2)
        return e1.sort[1] < e2.sort[1] or (e1.sort[1] == e2.sort[1] and e1.sort[2] < e2.sort[2])
    end)
    self:rewrite(entries)
end

function ZipArchive:rewrite(entries)
    local template = ffi.new("char[16]", "XXXXXX.zip.part")
    local fd = C.mkstemps(template, 9)
    if fd < 0 then
        error("mkstemps: "..strerror())
    end
    self.tmpfd = fd
    local buf = buffer:new()
    -- First: the entries themselves.
    local offset = 0
    for i, e in ipairs(entries) do
        local delta = offset - e.cdfh.offset
        local hdr_size = write_zip_lfh(fd, e.lfh)
        local full_size = e.zip_stop - e.zip_start + 1
        local data_size = full_size - hdr_size
        assert(data_size >= 0 and data_size + hdr_size == full_size)
        ensure_lseek(self.fd, e.zip_start + hdr_size)
        e.cdfh.offset = e.cdfh.offset + delta
        e.zip_start = e.zip_start + delta
        e.zip_stop = e.zip_stop + delta
        assert(e.zip_stop - e.zip_start + 1 == full_size)
        for ptr, len in read_fd_blocks_iterator(self.fd, buf, data_size) do
            ensure_write(fd, ptr, len)
        end
        offset = offset + full_size
    end
    -- Then: the updated central directory.
    self.eocd.cdir_offset = offset
    for i, e in ipairs(entries) do
        offset = offset + write_zip_cdfh(fd, e.cdfh)
    end
    self.eocd.cdir_size = offset - self.eocd.cdir_offset
    -- And finally: the end of central directory marker.
    ensure_write(fd, self.eocd, C.ZIP_EOCD_SIZE)
    C.close(self.fd)
    os.rename(ffi.string(template, 15), self.filename)
    self.entries = entries
    self.fd = fd
end

function ZipArchive:close()
    if self.archive then
        self.archive:close()
        self.archive = nil
    end
    if self.tmpfd then
        C.close(self.tmpfd)
        self.tmpfd = nil
    end
    if self.fd then
        C.close(self.fd)
        self.fd = nil
    end
end

-- }}}

-- ZipSyncUpdater. {{{

local ZipSyncUpdater = {}

function ZipSyncUpdater:new(state_dir, dl)
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

function ZipSyncUpdater:prepare_update(seed, progress_cb)
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
            download_size = download_size + e.zip_stop - e.zip_start + 1
            table.insert(missing_files, e)
        end
        if progress_cb and not progress_cb(i) then
            -- Canceled.
            return
        end
    end
    if #missing_files then
        download_size = download_size + self.manifest.zip_cdir_stop - self.manifest.zip_cdir_start + 1
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
        error("posix_fallocate: "..strerror(ret))
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
        if entry_path and progress_cb and not progress_cb(downloaded, entry_index, entry_path) then
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
    for cdfh in zip_cdir_iterator(raw_cdir, raw_cdir_size) do
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
            write_zip_cdfh(fd, cdfh)
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
        error("ftruncate: "..strerror())
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
    ZipArchive = ZipArchive,
}

-- vim: foldmethod=marker foldlevel=0
