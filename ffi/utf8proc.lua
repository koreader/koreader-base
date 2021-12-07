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

function Utf8Proc.normalize_NFC(str)
    local normalized_strz = libutf8proc.utf8proc_NFC(str)
    local normalized_str = ffi.string(normalized_strz)
    C.free(normalized_strz)
    return normalized_str
end

function Utf8Proc.count(str)
    local str_p = ffi.cast("const utf8proc_uint8_t *", str)
    local codepoint = ffi.new("utf8proc_int32_t[1]")
    local count = 0
    local pos = 0
    local str_len = #str -- may contain NUL
    while pos < str_len do
        local bytes = libutf8proc.utf8proc_iterate(str_p + pos, -1, codepoint)
        if bytes > 0 then
            count = count + 1
            pos = pos + bytes
        else
            return count, false
        end
    end
    return count, true
end

return Utf8Proc
