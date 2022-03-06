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

-- with normalization
function Utf8Proc.lowercase(str)
    local folded_strz = libutf8proc.utf8proc_NFKC_Casefold(str)
    local folded_str = ffi.string(folded_strz)
    C.free(folded_strz)
    return folded_str
end

-- no normalization here
function Utf8Proc.lowercase_dumb(str)
    local lowercased = ""
    local tmp_str = (" "):rep(10)
    local tmp_p = ffi.cast("utf8proc_uint8_t *", tmp_str)
    local str_p = ffi.cast("const utf8proc_uint8_t *", str)
    local codepoint = ffi.new("utf8proc_int32_t[1]")
    local count = 0
    local pos = 0
    local str_len = #str -- may contain NUL
    while pos < str_len do
        -- get codepoint
        local bytes = libutf8proc.utf8proc_iterate(str_p + pos, -1, codepoint)
        -- lowercase codepoint
        local lower_cp = libutf8proc.utf8proc_tolower(codepoint[0])
        -- encode lowercased codepoint and get length of new char*
        local lower_len = libutf8proc.utf8proc_encode_char(lower_cp, tmp_p)
        tmp_p[lower_len] = 0
        -- append
        lowercased = lowercased .. ffi.string(tmp_p)

        if bytes > 0 then
            count = count + 1
            pos = pos + bytes
        else
            return lowercased, false
        end
    end
    return lowercased, true
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
