--[[--
@module ffi.arcreader
]]

local ffi = require "ffi"
local libarchive = ffi.loadlib("archive", "13")
require "ffi/libarchive_h"
require "ffi/posix_h"

local ArcReader = {}

local ENTRY_MODE = {
    [libarchive.AE_IFREG]  = "file",
    [libarchive.AE_IFLNK]  = "link",
    [libarchive.AE_IFSOCK] = "socket",
    [libarchive.AE_IFCHR]  = "char device",
    [libarchive.AE_IFBLK]  = "block device",
    [libarchive.AE_IFDIR]  = "directory",
    [libarchive.AE_IFIFO]  = "named pipe",
}

local function archive_error_string(archive)
    local err = libarchive.archive_error_string(archive)
    return err ~= nil and ffi.string(err) or nil
end

function ArcReader:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.archive_entry = ffi.new("struct archive_entry *[1]")
    o.entries = {}
    o.size = 0
    o.err = nil
    return o
end

function ArcReader:open(filepath)
    self.err = nil
    if not filepath then
        return
    end
    self.archive = ffi.gc(libarchive.archive_read_new(), libarchive.archive_free)
    libarchive.archive_read_support_format_all(self.archive)
    libarchive.archive_read_support_filter_all(self.archive)
    if libarchive.archive_read_open_filename(self.archive, filepath, 10240) ~= libarchive.ARCHIVE_OK then
        self.err = archive_error_string(self.archive)
        print("ArcReader: archive_read_open_filename failed:", self.err)
        libarchive.archive_free(self.archive)
        ffi.gc(self.archive, nil)
        self.archive = nil
        return
    end
    self.filepath = filepath
    self.index = 0
    return true
end

function ArcReader:next()
    self.err = nil
    if self.archive == nil then
        return
    end
    -- We can't consume the data twice: tweak the index
    -- to trigger a reset in case of subsequent attempt.
    self.index = math.floor(self.index) + 0.1
    local err = libarchive.archive_read_next_header(self.archive, self.archive_entry)
    if err ~= libarchive.ARCHIVE_OK then
        if err ~= libarchive.ARCHIVE_EOF then
            self.err = archive_error_string(self.archive)
            print("ArcReader: archive_read_next_header failed:", self.err)
        end
        return
    end
    local entry
    self.index = math.floor(self.index) + 1
    if self.index > self.size then
        local archive_entry = self.archive_entry[0]
        entry = {
            path = ffi.string(libarchive.archive_entry_pathname(archive_entry)),
            mode = ENTRY_MODE[libarchive.archive_entry_filetype(archive_entry)] or "other",
            size = libarchive.archive_entry_size(archive_entry),
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

function ArcReader:iterate(keep_pos)
    if self.index ~= 0 and not keep_pos then
        self:close(true)
        self:open(self.filepath)
    end
    return self.next, self
end

function ArcReader:seek(key)
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

function ArcReader:extractToMemory(key)
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
        print("ArcReader: archive_read_data failed:", self.err)
        return
    end
    return ffi.string(content, entry.size)
end

function ArcReader:extractToPath(key, dest_path)
    self.err = nil
    local entry = self:seek(key)
    if not entry then
        return false, "no such path"
    end
    local dest = libarchive.archive_write_disk_new()
    libarchive.archive_write_disk_set_options(dest, libarchive.ARCHIVE_EXTRACT_SECURE_NODOTDOT)
    local archive_entry = self.archive_entry[0]
    if dest_path then
        libarchive.archive_entry_set_pathname(archive_entry, dest_path)
    end
    -- We can't consume the data twice: tweak the index
    -- to trigger a reset in case of subsequent attempt.
    self.index = self.index + 0.1
    local ok = libarchive.archive_read_extract2(self.archive, archive_entry, dest) == libarchive.ARCHIVE_OK
    if not ok then
        self.err = archive_error_string(self.archive)
        print("ArcReader: archive_read_extract2 failed:", self.err)
    end
    libarchive.archive_write_close(dest)
    libarchive.archive_free(dest)
    return ok
end

function ArcReader:close(keep_info)
    self.err = nil
    if self.archive ~= nil then
        libarchive.archive_read_close(self.archive)
        libarchive.archive_free(self.archive)
        ffi.gc(self.archive, nil)
        self.archive = nil
    end
    self.archive = nil
    self.index = nil
    if not keep_info then
        self.filepath = nil
        self.entries = {}
        self.size = nil
    end
end

return ArcReader
