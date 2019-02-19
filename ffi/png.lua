--[[--
Module for PNG decoding/encoding.

Currently, this is a LuaJIT FFI wrapper for lodepng lib.

@module ffi.png
]]

local ffi = require("ffi")
local _ = require("ffi/lodepng_h")

local lodepng
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
        local err_msg = lodepng.lodepng_error_text(err)
        return false, err_msg
    else
        return true
    end
end

function Png.decodeFromFile(filename, req_n)
    local width = ffi.new("int[1]")
    local height = ffi.new("int[1]")
    local ptr = ffi.new("unsigned char*[1]")
    local fmt
    if req_n == 1 then
        fmt = lodepng.LCT_GREY
    elseif req_n == 2 then
        fmt = lodepng.LCT_GREY_ALPHA
    elseif req_n == 3 then
        fmt = lodepng.LCT_RGB
    elseif req_n == 4 then
        fmt = lodepng.LCT_RGBA
    end
    -- TODO: Inspect, honor req_n if gray/gray_alpha, return actual ncomp so that bbtype matches
    local err = lodepng.lodepng_decode_file(ptr, width, height, filename, fmt, 8)
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
