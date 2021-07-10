--[[--
Module for utf8 string operations

This is a LuaJIT FFI wrapper for utf8proc.
]]

local ffi = require("ffi")

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
    local str8_len = str:len()

    local str8 = ffi.new("uint8_t[" .. str8_len .."]")
    local str32 = ffi.new("int32_t[" .. str8_len .. "]")

    -- copy string contents to uint8_t array
    for i = 1,str8_len do
        str8[i-1] = str:byte(i)
    end

    -- generate array of codepoints
    local str32_len = 0
    local pos8 = 0
    while pos8<str8_len do
        pos8 = pos8 + libutf8proc.utf8proc_iterate(str8 + pos8, str8_len-pos8, str32 + str32_len)
        str32_len = str32_len + 1
    end

    -- tolower
    for i = 0,str32_len-1 do
        str32[i] = libutf8proc.utf8proc_tolower(str32[i])
    end

    -- encode back to utf8
    pos8 = 0
    for i = 0,3 do
        pos8 = pos8 + libutf8proc.utf8proc_encode_char(str32[i], str8 + pos8);
    end

    local retval = ""
    for i = 0,str8_len-1 do
        retval = retval .. string.char(str8[i])
    end

    return retval
end

return Utf8Proc
