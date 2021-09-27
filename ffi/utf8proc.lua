--[[--
Module for utf8 string operations.

This is a LuaJIT FFI wrapper for utf8proc.

@module ffi.utf8proc
]]

local ffi = require("ffi")
local C = ffi.C

require("ffi/posix_h")
require("ffi/utf8proc_h")

local libutf8proc
if ffi.os == "Windows" then
    libutf8proc = ffi.load("libs/libutf8proc-2.dll")
elseif ffi.os == "OSX" then
    libutf8proc = ffi.load("libs/libutf8proc.2.dylib")
else
    libutf8proc = ffi.load("libs/libutf8proc.so.2")
end

local Utf8Proc = {}

function Utf8Proc.lowercase(str)
    local folded_strz = libutf8proc.utf8proc_NFKC_Casefold(str)
    local folded_str = ffi.string(folded_strz)
    C.free(folded_strz)
    return folded_str
end

function Utf8Proc.strlen(str)
    local str_buf = ffi.cast("const utf8proc_uint8_t *", str)
    local buffer = ffi.new("utf8proc_int32_t[1]")
    local retval = 0
    local pos = 0
    while str_buf[pos] ~= 0 do
        pos = pos + libutf8proc.utf8proc_iterate(str_buf + pos, -1, buffer)
        retval = retval + 1
    end
    return retval
end

return Utf8Proc
