--[[--
Module for utf8 string operations.

This is a LuaJIT FFI wrapper for utf8proc.
]]

local ffi = require("ffi")
local C = ffi.C

require("ffi/posix_h")
require("ffi/utf8proc_h")

local libutf8proc
if ffi.os == "Windows" then
    libutf8proc = ffi.load("libs/libutf8proc.dll")
elseif ffi.os == "OSX" then
    libutf8proc = ffi.load("libs/libutf8proc.dylib")
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

return Utf8Proc
