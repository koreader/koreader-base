--[[--
Module for PNG decoding/encoding.

Currently, this is a LuaJIT FFI wrapper for lodepng lib.

@module ffi.png
]]

local ffi = require("ffi")
local _ = require("ffi/lodepng_h")

local loadpng
if ffi.os == "Windows" then
    lodepng = ffi.load("libs/liblodepng.dll")
elseif ffi.os == "OSX" then
	lodepng = ffi.load("libs/liblodepng.dylib")
else
    lodepng = ffi.load("libs/liblodepng.so")
end

local Png = {}

function Png.encodeToFile(filename, mem, w, h)
    local err = lodepng.lodepng_encode32_file(filename, mem, w, h)
    if err ~= 0 then
        err_msg = lodepng.lodepng_error_text(err)
        return false, err_msg
    else
        return true
    end
end

function Png.decodeFromFile(filename)
    local width = ffi.new("int[1]")
    local height = ffi.new("int[1]")
    local ptr = ffi.new("unsigned char*[1]")
    local err = lodepng.lodepng_decode32_file(ptr, width, height, filename)
    if err ~= 0 then
        return false, ffi.string(lodepng.lodepng_error_text(err))
    else
        return true, {
            width = width[0],
            height = height[0],
            data = ptr[0],
        }
    end
end

return Png
