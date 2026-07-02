--[[--
Module for AVIF decoding.

This is a LuaJIT FFI wrapper for libavif.

@module ffi.avif
]]

local ffi = require("ffi")
local BB = require("ffi/blitbuffer")

require("ffi/libavif_h")

local libavif = ffi.load("avif")

local Avif = {
    decoder = nil,
    image = nil,
    width = nil,
    height = nil,
    components = 4, -- always RGB32
    nb_frames = nil,
    cur_frame = nil,
}

function Avif:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Avif.fromFile(filename)
    local fh = io.open(filename, "rb")
    assert(fh, "couldn't open AVIF file")
    local data = fh:read("*a")
    fh:close()
    return Avif.fromData(data)
end

function Avif.fromData(data, size)
    size = size or #data
    local decoder = libavif.avifDecoderCreate()
    assert(decoder ~= nil, "libavif avifDecoderCreate() failed.")

    local res = libavif.avifDecoderSetIOMemory(decoder, ffi.cast("const uint8_t*", data), size)
    assert(res == 0, "libavif avifDecoderSetIOMemory() failed: " .. ffi.string(libavif.avifResultToString(res)))

    res = libavif.avifDecoderParse(decoder)
    assert(res == 0, "libavif avifDecoderParse() failed: " .. ffi.string(libavif.avifResultToString(res)))

    local image = decoder.image
    return Avif:new{
        decoder = decoder,
        width = image.width,
        height = image.height,
        nb_frames = decoder.imageCount,
    }
end

function Avif:getFrameImage(number, no_copy)
    if number < 1 then number = 1 end
    if number > self.nb_frames then number = self.nb_frames end

    -- For AVIF, we decode the Nth image and then convert it to RGB.
    -- If we are not already on the requested frame, we need to decode it.
    if self.cur_frame ~= number then
        local res = libavif.avifDecoderNthImage(self.decoder, number - 1)
        assert(res == 0, "libavif avifDecoderNthImage() failed")
        self.cur_frame = number
    end

    local image = self.decoder.image
    local rgb = ffi.new("avifRGBImage")
    libavif.avifRGBImageSetDefaults(rgb, image)
    rgb.format = 1 -- AVIF_RGB_FORMAT_RGBA
    libavif.avifRGBImageAllocatePixels(rgb)

    local res = libavif.avifImageYUVToRGB(image, rgb)
    assert(res == 0, "libavif avifImageYUVToRGB() failed")

    local image_bb = BB.new(rgb.width, rgb.height, BB.TYPE_BBRGB32, rgb.pixels)

    -- We must free the allocated pixels since we are copying them into a BlitBuffer (or using them directly if no_copy=true)
    -- However, BB.new doesn't take ownership.
    -- If no_copy is true, the caller must be careful.
    -- But the pattern in WebP is to copy by default.

    local result_bb
    if no_copy then
        result_bb = image_bb
    else
        result_bb = image_bb:copy()
    end

    libavif.avifRGBImageFreePixels(rgb)

    return result_bb
end

function Avif:close()
    if self.decoder then
        libavif.avifDecoderDestroy(self.decoder)
        self.decoder = nil
    end
end

return Avif
