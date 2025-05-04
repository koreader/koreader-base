--[[--
Zip reading workflow & code from luarocks' zip.lua:
   https://github.com/luarocks/luarocks/blob/master/src/luarocks/tools/zip.lua
 Modified to not require lua-zlib (we can wrap zlib with ffi)
   cf: http://luajit.org/ext_ffi_tutorial.html, which uses zlib as an example !

@module ffi.zipreader
]]

local zlib = require "ffi/zlib"

local function shl(n, m)
    return (n * 2 ^ m)
 end

local function number_to_lestring(num, nbytes)
    local out = {}
    for _ = 1, nbytes do
       local byte = num % 256
       table.insert(out, string.char(byte))
       num = math.floor((num - byte) / 256)
    end
    return table.concat(out)
end

local function lestring_to_number(str)
    local n = 0
    local bytes = { string.byte(str, 1, #str) }
    for b = 1, #str do
       n = n + shl(bytes[b], (b - 1) * 8)
    end
    return math.floor(n)
end

local function read_file_in_zip(zh, cdr)
    local sig = zh:read(4)
    if sig ~= number_to_lestring(0x04034b50, 4) then -- local file header signature
       return nil, "failed reading Local File Header signature"
    end

    zh:seek("cur", 22)
    local file_name_length = lestring_to_number(zh:read(2))
    local extra_field_length = lestring_to_number(zh:read(2))
    zh:read(file_name_length)
    zh:read(extra_field_length)

    local data = zh:read(cdr.compressed_size)

    local uncompressed
    if cdr.compression_method == 8 then
       uncompressed = zlib.zlib_uncompress_raw(data, cdr.uncompressed_size)
    elseif cdr.compression_method == 0 then
       uncompressed = data
    else
       return nil, "unknown compression method " .. cdr.compression_method
    end

    if #uncompressed ~= cdr.uncompressed_size then
       return nil, "uncompressed size doesn't match"
    end
    if cdr.crc32 ~= zlib.zlib_crc32(uncompressed) then
       return nil, "crc mismatch"
    end

    return uncompressed
end

local function process_end_of_central_dir(zh)
    local at, errend = zh:seek("end", -22)
    if not at then
       return nil, errend
    end

    while true do
       local sig = zh:read(4)
       if sig == number_to_lestring(0x06054b50, 4) then -- end of central directory signature
          break
       end
       at = at - 1
       local at1 = zh:seek("set", at)
       if at1 ~= at then
          return nil, "Could not find End of Central Directory signature"
       end
    end

    zh:seek("cur", 6)
    local central_directory_entries = lestring_to_number(zh:read(2))

    zh:seek("cur", 4)
    local central_directory_offset = lestring_to_number(zh:read(4))

    return central_directory_entries, central_directory_offset
end

local function process_central_dir(zh, cd_entries)
    local files = {}

    for i = 1, cd_entries do
       local sig = zh:read(4)
       if sig ~= number_to_lestring(0x02014b50, 4) then -- central directory signature
          return nil, "failed reading Central Directory signature"
       end

       local cdr = {}
       files[i] = cdr

       cdr.version_made_by = lestring_to_number(zh:read(2))
       cdr.version_needed = lestring_to_number(zh:read(2))
       cdr.bitflag = lestring_to_number(zh:read(2))
       cdr.compression_method = lestring_to_number(zh:read(2))
       cdr.last_mod_file_time = lestring_to_number(zh:read(2))
       cdr.last_mod_file_date = lestring_to_number(zh:read(2))
       cdr.crc32 = lestring_to_number(zh:read(4))
       cdr.compressed_size = lestring_to_number(zh:read(4))
       cdr.uncompressed_size = lestring_to_number(zh:read(4))
       cdr.file_name_length = lestring_to_number(zh:read(2))
       cdr.extra_field_length = lestring_to_number(zh:read(2))
       cdr.file_comment_length = lestring_to_number(zh:read(2))
       cdr.disk_number_start = lestring_to_number(zh:read(2))
       cdr.internal_attr = lestring_to_number(zh:read(2))
       cdr.external_attr = lestring_to_number(zh:read(4))
       cdr.offset = lestring_to_number(zh:read(4))
       cdr.file_name = zh:read(cdr.file_name_length)
       cdr.extra_field = zh:read(cdr.extra_field_length)
       cdr.file_comment = zh:read(cdr.file_comment_length)
    end
    return files
end

local ZipReader = {}

function ZipReader:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Open zip file
function ZipReader:open(zip_file_path)
    self.files = {}
    self.ziphandle = nil

    local zh, erropen = io.open(zip_file_path, "rb")
    if not zh then
        return nil, erropen
    end

    local cd_entries, cd_offset = process_end_of_central_dir(zh)
    if type(cd_offset) == "string" then
       return nil, cd_offset
    end

    local okseek, errseek = zh:seek("set", cd_offset)
    if not okseek then
       return nil, errseek
    end

    local files, errproc = process_central_dir(zh, cd_entries)
    if not files then
       return nil, errproc
    end

    self.files = files
    self.ziphandle = zh
    return true
end

function ZipReader:read_file(zip_entry)
    local file = zip_entry.file_name
    if file:sub(#file) == "/" then
        return nil, "entry is a directory"
    end

    local okseek, errseek = self.ziphandle:seek("set", zip_entry.offset)
    if not okseek then
        return nil, errseek
    end

    local contents, err = read_file_in_zip(self.ziphandle, zip_entry)
    return contents, err
end

function ZipReader:close()
    return self.ziphandle:close()
end

return ZipReader
