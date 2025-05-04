--[[--
LuaJIT FFI wrapper for zlib.

@module ffi.zlib
]]

local ffi = require("ffi")
require("ffi/zlib_h")

local libz = ffi.loadlib("koreader-zlib")

local zlib = {}

-- Data compression/decompression of strings via zlib
-- from http://luajit.org/ext_ffi_tutorial.html
function zlib.zlib_compress(data)
    local n = libz.compressBound(#data)
    local buf = ffi.new("uint8_t[?]", n)
    local buflen = ffi.new("unsigned long[1]", n)
    local res = libz.compress2(buf, buflen, data, #data, 9)
    assert(res == 0)
    return ffi.string(buf, buflen[0])
end

function zlib.zlib_uncompress(zdata, datalen)
    local buf = ffi.new("uint8_t[?]", datalen)
    local buflen = ffi.new("unsigned long[1]", datalen)
    local res = libz.uncompress(buf, buflen, zdata, #zdata)
    assert(res == 0)
    return ffi.string(buf, buflen[0])
end

function zlib.zlib_uncompress_raw(zdata, datalen)
    local buf = ffi.new("uint8_t[?]", datalen)
    local buflen = ffi.new("unsigned long[1]", datalen)
    local res = libz.uncompress_raw(buf, buflen, zdata, #zdata)
    assert(res == 0)
    return ffi.string(buf, buflen[0])
end

function zlib.zlib_crc32(data, checksum)
    checksum = checksum or 0
    data = data or ""
    return libz.crc32(checksum, data, #data)
end

return zlib
