--[[--
Module for JPEG decoding/encoding.

This is a LuaJIT FFI wrapper for turbojpeg.

@module ffi.jpeg
]]

local BB = require("ffi/blitbuffer")
local ffi = require("ffi")

local _ = require("ffi/turbojpeg_h")
local turbojpeg = ffi.load("turbojpeg")

local Jpeg = {}

function Jpeg.openDocument(filename, color)
    local fh = io.open(filename, "rb")
    assert(fh, "couldn't open JPG file")
    local data = fh:read("*a")
    fh:close()

    return Jpeg.openDocumentFromMem(data, color)
end

function Jpeg.openDocumentFromMem(data, color)
    local handle = turbojpeg.tjInitDecompress()
    assert(handle, "no TurboJPEG API decompressor handle")

    local width = ffi.new("int[1]")
    local height = ffi.new("int[1]")
    local jpegSubsamp = ffi.new("int[1]")
    local colorspace = ffi.new("int[1]")

    turbojpeg.tjDecompressHeader3(handle, ffi.cast("const unsigned char*", data), #data, width, height, jpegSubsamp, colorspace)
    assert(width[0] > 0 and height[0] > 0, "image dimensions")

    local image_bb
    local format
    local components
    if color then
        image_bb = BB.new(width[0], height[0], BB.TYPE_BBRGB24)
        components = 3
        format = turbojpeg.TJPF_RGB
    else
        image_bb = BB.new(width[0], height[0], BB.TYPE_BB8)
        components = 1
        format = turbojpeg.TJPF_GRAY
    end

    if turbojpeg.tjDecompress2(handle, ffi.cast("unsigned char*", data), #data,
        ffi.cast("unsigned char*", image_bb.data),
        width[0], image_bb.stride, height[0], format, 0) == -1 then
        error("decoding JPEG file")
    end

    turbojpeg.tjDestroy(handle)
    return image_bb, width[0], height[0], components
end

function Jpeg.encodeToFile(filename, source_ptr, w, h, quality, color_type, subsample)
    quality = quality or 75
    color_type = color_type or turbojpeg.TJPF_RGB
    subsample = subsample or turbojpeg.TJSAMP_420


    local jpeg_size = ffi.new("unsigned long int [1]")

    local jpeg_image = ffi.new("unsigned char* [1]")
    jpeg_image[0] = ffi.new("unsigned char*")

    local handle = turbojpeg.tjInitCompress()
    assert(handle, "no TurboJPEG API compressor handle")

    if turbojpeg.tjCompress2(handle, source_ptr, w, 0, h, color_type,
        jpeg_image, jpeg_size, subsample, quality, 0) == 0 then

        local of, err = io.open(filename, "wb")
        if err ~= nil then
            return err
        else
            of:write(ffi.string(jpeg_image[0], jpeg_size[0]))
            of:close()
        end
    end

    turbojpeg.tjDestroy(handle)
    if jpeg_image[0] ~= nil then
        turbojpeg.tjFree(jpeg_image[0])
    end
end

return Jpeg