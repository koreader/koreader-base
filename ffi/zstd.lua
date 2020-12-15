--[[--
LuaJIT FFI wrapper for ZSTD.

@module ffi.zstd
]]

local ffi = require("ffi")
local C = ffi.C

local posix = require("ffi/posix_h") -- luacheck: ignore 211
local _ = require("ffi/zstd_h")

local zst
if ffi.os == "Windows" then
    zst = ffi.load("libs/libzstd.dll")
elseif ffi.os == "OSX" then
    zst = ffi.load("libs/libzstd.1.dylib")
else
    zst = ffi.load("libs/libzstd.so.1")
end

local zstd = {}

-- c.f., https://github.com/facebook/zstd/tree/dev/examples
function zstd.zstd_compress(ptr, size)
    local n = zst.ZSTD_compressBound(size)
    local cbuff = C.calloc(n, 1)
    assert(cbuff ~= nil)
    -- NOTE: We should be quite all right with the default (3), which will most likely trounce zlib's 9 in every respect...
    local clen = zst.ZSTD_compress(cbuff, n, ptr, size, zst.ZSTD_CLEVEL_DEFAULT)
    assert(zst.ZSTD_isError(clen) == 0)
    return cbuff, clen
end

function zstd.zstd_uncompress(ptr, size)
    -- The decompressed size is encoded in the ZST frame header
    local n = zst.ZSTD_getFrameContentSize(ptr, size)
    local buff = C.calloc(n, 1)
    assert(buff ~= nil)
    local ulen = zst.ZSTD_decompress(buff, n, ptr, size)
    assert(zst.ZSTD_isError(ulen) == 0)
    return buff, ulen
end

return zstd
