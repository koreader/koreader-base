--[[--
@module ffi.zipwriter
]]

local ffi = require "ffi"
local libarchive = ffi.loadlib("archive", "13")
require "ffi/libarchive_h"

-- Pure lua zip writer
local ZipWriter = {}

function ZipWriter:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--- Complete the writing of the zipfile.
function ZipWriter:close()
    libarchive.archive_write_close(self.archive)
    libarchive.archive_write_free(self.archive)
    self.archive = nil
    return true
end

-- Open zipfile
function ZipWriter:open(zipfilepath)
    self.archive = libarchive.archive_write_new()
    self.started_time = os.time()
    libarchive.archive_write_set_format_zip(self.archive)
    if libarchive.archive_write_open_filename(self.archive, zipfilepath) ~= libarchive.ARCHIVE_OK then
        local err = ffi.string(libarchive.archive_error_string(self.archive))
        print("archive_write_open_filename failed:", err)
        libarchive.archive_write_free(self.archive)
        self.archive = nil
        return false
    end
    return true
end

-- Add to zipfile content with the name in_zip_filepath
function ZipWriter:add(in_zip_filepath, content, no_compression)
    local entry = libarchive.archive_entry_new()
    libarchive.archive_entry_set_pathname(entry, in_zip_filepath)
    libarchive.archive_entry_set_size(entry, #content)
    libarchive.archive_entry_set_filetype(entry, libarchive.AE_IFREG)
    libarchive.archive_entry_set_mtime(entry, self.started_time, 0);
    libarchive.archive_entry_set_perm(entry, 0644);
    if no_compression then
        libarchive.archive_write_zip_set_compression_store(self.archive)
    else
        libarchive.archive_write_zip_set_compression_deflate(self.archive)
    end
    libarchive.archive_write_header(self.archive, entry);
    libarchive.archive_write_data(self.archive, content, #content)
    libarchive.archive_entry_free(entry)
end

-- Convenience function
-- function ZipWriter.createZipWithFiles(zipfilename, files)
--     local zw = ZipWriter:new()
--     zw:open(zipfilename)
--     for _, f in pairs(files) do
--         zw:add(f.filename, f.content)
--     end
--     zw:close()
-- end
-- files = {}
-- files[1] = {filename="tutu.txt", content="this is tutu"}
-- files[2] = {filename="subtoto/toto.txt", content="this is toto in subtoto directory"}
-- createZipWithFiles("tata.zip", files)

return ZipWriter
