--[[--
@module ffi.archiver
]]

local ffi = require "ffi"
local libarchive = ffi.loadlib("archive", "13")
require "ffi/libarchive_h"
require "ffi/posix_h"

local function archive_error_string(archive)
    local err = libarchive.archive_error_string(archive)
    return err ~= nil and ffi.string(err) or nil
end

-- Reader {{{

local ENTRY_MODE = {
    [libarchive.AE_IFREG]  = "file",
    [libarchive.AE_IFLNK]  = "link",
    [libarchive.AE_IFSOCK] = "socket",
    [libarchive.AE_IFCHR]  = "char device",
    [libarchive.AE_IFBLK]  = "block device",
    [libarchive.AE_IFDIR]  = "directory",
    [libarchive.AE_IFIFO]  = "named pipe",
}

local Reader = {}

function Reader:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.archive_entry = ffi.gc(libarchive.archive_entry_new(), libarchive.archive_entry_free)
    o.entries = {}
    o.size = 0
    o.err = nil
    return o
end

function Reader:open(filepath)
    self.err = nil
    if not filepath then
        return
    end
    self.archive = ffi.gc(libarchive.archive_read_new(), libarchive.archive_free)
    libarchive.archive_read_support_format_all(self.archive)
    libarchive.archive_read_support_filter_all(self.archive)
    if libarchive.archive_read_open_filename(self.archive, filepath, 10240) ~= libarchive.ARCHIVE_OK then
        self.err = archive_error_string(self.archive)
        print("Archive.Reader:open failed:", self.err)
        self.archive = nil
        return
    end
    self.filepath = filepath
    self.index = 0
    return true
end

function Reader:next()
    self.err = nil
    if self.archive == nil then
        return
    end
    -- We can't consume the data twice: tweak the index
    -- to trigger a reset in case of subsequent attempt.
    self.index = math.floor(self.index) + 0.1
    local err = libarchive.archive_read_next_header2(self.archive, self.archive_entry)
    if err ~= libarchive.ARCHIVE_OK then
        if err ~= libarchive.ARCHIVE_EOF then
            self.err = archive_error_string(self.archive)
            print("Archive.Reader:next failed:", self.err)
        end
        return
    end
    local entry
    self.index = math.floor(self.index) + 1
    if self.index > self.size then
        entry = {
            path = ffi.string(libarchive.archive_entry_pathname(self.archive_entry)),
            mode = ENTRY_MODE[libarchive.archive_entry_filetype(self.archive_entry)] or "other",
            size = libarchive.archive_entry_size(self.archive_entry),
            index = self.index,
        }
        self.entries[self.index] = entry
        self.entries[entry.path] = entry
        self.size = self.size + 1
    else
        entry = self.entries[self.index]
    end
    return entry
end

function Reader:iterate(keep_pos)
    if self.index ~= 0 and not keep_pos then
        self:close(true)
        self:open(self.filepath)
    end
    return self.next, self
end

function Reader:seek(key)
    local entry = self.entries[key]
    if not entry then
        return
    end
    if entry.index == self.index then
        return entry
    end
    for __ in self:iterate(entry.index > self.index) do
        if entry.index == self.index then
            return entry
        end
    end
end

function Reader:extractToMemory(key)
    self.err = nil
    local entry = self:seek(key)
    if not entry or entry.mode ~= "file" then
        return
    end
    -- We can't consume the data twice: tweak the index
    -- to trigger a reset in case of subsequent attempt.
    self.index = self.index + 0.1
    local content = ffi.gc(ffi.C.malloc(entry.size), ffi.C.free)
    local count = libarchive.archive_read_data(self.archive, content, entry.size)
    if count ~= entry.size then
        self.err = archive_error_string(self.archive) or "short read"
        print("Reader: archive_read_data failed:", self.err)
        return
    end
    return ffi.string(content, entry.size)
end

function Reader:extractToPath(key, dest_path)
    self.err = nil
    local entry = self:seek(key)
    if not entry then
        return false, "no such path"
    end
    local dest = ffi.gc(libarchive.archive_write_disk_new(), libarchive.archive_free)
    libarchive.archive_write_disk_set_options(dest, libarchive.ARCHIVE_EXTRACT_SECURE_NODOTDOT)
    if dest_path then
        libarchive.archive_entry_set_pathname(self.archive_entry, dest_path)
    end
    -- We can't consume the data twice: tweak the index
    -- to trigger a reset in case of subsequent attempt.
    self.index = self.index + 0.1
    local ok = libarchive.archive_read_extract2(self.archive, self.archive_entry, dest) == libarchive.ARCHIVE_OK
    if not ok then
        self.err = archive_error_string(self.archive)
        print("Reader: archive_read_extract2 failed:", self.err)
    end
    libarchive.archive_write_close(dest)
    return ok
end

function Reader:close(keep_info)
    self.err = nil
    if self.archive ~= nil then
        libarchive.archive_read_close(self.archive)
        self.archive = nil
    end
    self.index = nil
    if not keep_info then
        self.filepath = nil
        self.entries = {}
        self.size = nil
    end
end

-- }}}

-- Writer {{{

local FORMAT_ALIASES = {
    ["epub"]  = "zip",
    ["targz"] = "tar.gz",
    ["tgz"]   = "tar.gz",
    ["tzst"]  = "tar.zst",
}

local FILTER_ALIASES = {
    ["gz"]  = "gzip",
    ["zst"] = "zstd",
}

local function archive_write_add_filter_by_name(archive, filter)
    if not filter then
        return libarchive.ARCHIVE_OK
    end
    return libarchive.archive_write_add_filter_by_name(archive, filter)
end

local Writer = {}

function Writer:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.archive_read_disk = nil
    o.err = nil
    return o
end

function Writer:open(filepath, format)
    self.err = nil
    self.archive = ffi.gc(libarchive.archive_write_new(), libarchive.archive_free)
    if not format then
        format = filepath:match("[.](tar[.][^.]+)$") or filepath:match("[.]([^.]+)$")
    end
    format = FORMAT_ALIASES[format] or format
    local base_format, filter = format:match("([^.]+)[.]([^.]+)")
    if not base_format then
        base_format = format
    end
    if base_format == "tar" then
        base_format = "gnutar"
    end
    filter = FILTER_ALIASES[filter] or filter
    if libarchive.archive_write_set_format_by_name(self.archive, base_format) ~= libarchive.ARCHIVE_OK or
       archive_write_add_filter_by_name(self.archive, filter) ~= libarchive.ARCHIVE_OK or
       libarchive.archive_write_open_filename(self.archive, filepath) ~= libarchive.ARCHIVE_OK then
        self.err = archive_error_string(self.archive)
        print("Archive.Writer:open failed:", self.err)
        self.archive = nil
        return
    end
    self.filepath = filepath
    return true
end

function Writer:setZipCompression(method)
    self.err = nil
    if self.archive == nil then
        return
    end
    local r
    if method == "store" then
        r = libarchive.archive_write_zip_set_compression_store(self.archive)
    elseif method == "deflate" then
        r = libarchive.archive_write_zip_set_compression_deflate(self.archive)
    else
        r = libarchive.ARCHIVE_FAILED
        self.err = "unsuported method"
    end
    if r ~= libarchive.ARCHIVE_OK then
        self.err = self.err or archive_error_string(self.archive)
        print("Archive.Writer:setZipCompression failed:", self.err)
        return
    end
    return true
end

function Writer:addFileFromMemory(entry_path, content, mtime)
    self.err = nil
    if self.archive == nil then
        return
    end
    local entry = ffi.gc(libarchive.archive_entry_new(), libarchive.archive_entry_free)
    libarchive.archive_entry_set_pathname(entry, entry_path)
    libarchive.archive_entry_set_filetype(entry, libarchive.AE_IFREG)
    libarchive.archive_entry_set_mtime(entry, mtime or os.time(), 0)
    libarchive.archive_entry_set_perm(entry, 0644)
    libarchive.archive_entry_set_size(entry, #content)
    if libarchive.archive_write_header(self.archive, entry) ~= libarchive.ARCHIVE_OK or
       libarchive.archive_write_data(self.archive, content, #content) ~= #content then
        self.err = archive_error_string(self.archive) or "short write"
        print("Archive.Writer:addFileFromMemory failed:", self.err)
        return
    end
    return true
end

function Writer:addPath(entry_root, root, recursive, mtime)
    self.err = nil
    if self.archive == nil then
        return
    end
    if not root then
        root = entry_root
    end
    local rd = self.archive_read_disk
    if rd == nil then
        self.archive_read_disk = ffi.gc(libarchive.archive_read_disk_new(), libarchive.archive_free)
        libarchive.archive_read_disk_set_behavior(self.archive_read_disk, 0
            + libarchive.ARCHIVE_READDISK_NO_ACL
            + libarchive.ARCHIVE_READDISK_NO_FFLAGS
            + libarchive.ARCHIVE_READDISK_NO_SPARSE
            + libarchive.ARCHIVE_READDISK_NO_TRAVERSE_MOUNTS
            + libarchive.ARCHIVE_READDISK_NO_XATTR
        )
        rd = self.archive_read_disk
    end
    local entry = ffi.gc(libarchive.archive_entry_new(), libarchive.archive_entry_free)
    local buff = ffi.new("const void *[1]")
    local size = ffi.new("size_t [1]")
    local offs = ffi.new("int64_t [1]")
    if libarchive.archive_read_disk_open(rd, root) ~= libarchive.ARCHIVE_OK then
        self.err = archive_error_string(self.archive)
        print("Archive.Writer:addPath failed:", self.err)
        return
    end
    local r
    while true do
        r = libarchive.archive_read_next_header2(rd, entry)
        if r ~= libarchive.ARCHIVE_OK then
            break
        end
        local path = ffi.string(libarchive.archive_entry_pathname(entry))
        local entry_path = entry_root
        if #path > #root then
            entry_path = entry_path.."/"..path:sub(#root + 2)
        end
        libarchive.archive_entry_set_pathname(entry, entry_path)
        if mtime then
            libarchive.archive_entry_set_mtime(entry, mtime, 0)
        end
        libarchive.archive_entry_set_uid(entry, 0)
        libarchive.archive_entry_set_gid(entry, 0)
        r = libarchive.archive_write_header(self.archive, entry)
        if r ~= libarchive.ARCHIVE_OK then
            break
        end
        if libarchive.archive_entry_filetype(entry) == libarchive.AE_IFREG then
            local eof
            repeat
                r = libarchive.archive_read_data_block(rd, buff, size, offs)
                if r ~= libarchive.ARCHIVE_OK then
                    eof = r == libarchive.ARCHIVE_EOF
                    if not eof then
                        break
                    end
                    r = libarchive.ARCHIVE_OK
                end
                if libarchive.archive_write_data(self.archive, buff[0], size[0]) ~= size[0] then
                    r = libarchive.ARCHIVE_FAILED
                    self.err = "short write"
                    break
                end
            until eof
            if r ~= libarchive.ARCHIVE_OK then
                break
            end
        end
        if recursive then
            libarchive.archive_read_disk_descend(rd)
        end
    end
    if r ~= libarchive.ARCHIVE_OK and r ~= libarchive.ARCHIVE_EOF then
        self.err = self.err or archive_error_string(rd) or archive_error_string(self.archive)
        print("Archive.Writer:addPath failed:", self.err)
    end
    libarchive.archive_read_close(rd)
    return r == libarchive.ARCHIVE_OK
end

function Writer:close()
    self.err = nil
    if self.archive ~= nil then
        libarchive.archive_write_close(self.archive)
        self.archive = nil
    end
    self.archive_read_disk = nil
end

-- }}}

return {
    Reader = Reader,
    Writer = Writer,
}

-- vim: foldmethod=marker foldlevel=0
