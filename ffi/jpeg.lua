--[[--
Module for JPEG decoding/encoding.

This is a LuaJIT FFI wrapper for turbojpeg.

@module ffi.jpeg
]]

local ffi = require("ffi")
local C = ffi.C
local BB = require("ffi/blitbuffer")

require("ffi/posix_h")
require("ffi/turbojpeg_h")

-- The turbojpeg library symbols are versioned, so it should always be
-- backward compatible: the major & patch numbers are always 0, and when
-- a new API version is made available, the minor number is incremented.
local turbojpeg = ffi.loadlib("turbojpeg", "0.5.0", "turbojpeg", "0.4.0", "turbojpeg", "0.3.0", "turbojpeg")

-- Starting with 3.2.0, `tj3Init(…)` is a macro for `tj3InitVersion(…, TURBOJPEG_VERSION_NUMBER)`
-- (to automatically disable API-incompatible features when code was compiled for an older version).
local tj3Init = pcall(function() return turbojpeg.tj3Init ~= nil end) and turbojpeg.tj3Init or function(t)
    return turbojpeg.tj3InitVersion(t, turbojpeg.TURBOJPEG_VERSION_NUMBER)
end

local Jpeg = {}

function Jpeg.openDocument(filename, color)
    local fh = io.open(filename, "rb")
    assert(fh, "couldn't open JPG file")
    local data = fh:read("*a")
    fh:close()

    return Jpeg.openDocumentFromMem(data, color)
end

function Jpeg.openDocumentFromMem(data, color, size)
    local handle = tj3Init(turbojpeg.TJINIT_DECOMPRESS)
    assert(handle, "no TurboJPEG API decompressor handle")

    if turbojpeg.tj3DecompressHeader(handle, ffi.cast("const unsigned char*", data), size or #data) < 0 then
        turbojpeg.tj3Destroy(handle)
        error("reading JPEG header")
    end

    local width = turbojpeg.tj3Get(handle, turbojpeg.TJPARAM_JPEGWIDTH)
    local height = turbojpeg.tj3Get(handle, turbojpeg.TJPARAM_JPEGHEIGHT)
    --[[
    local inSubsamp = turbojpeg.tj3Get(handle, turbojpeg.TJPARAM_SUBSAMP)
    local inColorspace = turbojpeg.tj3Get(handle, turbojpeg.TJPARAM_COLORSPACE)
    --]]

    local image_bb
    local format
    local components
    if color then
        image_bb = BB.new(width, height, BB.TYPE_BBRGB24)
        components = 3
        format = turbojpeg.TJPF_RGB
    else
        image_bb = BB.new(width, height, BB.TYPE_BB8)
        components = 1
        format = turbojpeg.TJPF_GRAY
    end

    if turbojpeg.tj3Decompress8(handle, ffi.cast("unsigned char*", data), size or #data,
                                ffi.cast("unsigned char*", image_bb.data), image_bb.stride, format) < 0 then
        turbojpeg.tj3Destroy(handle)
        error("decoding JPEG file")
    end

    turbojpeg.tj3Destroy(handle)
    return image_bb, width, height, components
end

function Jpeg.encodeToFile(filename, source_ptr, w, h, n, quality, stride, subsample)
    local handle = tj3Init(turbojpeg.TJINIT_COMPRESS)
    assert(handle, "no TurboJPEG API compressor handle")

    local color_type
    if n == 3 then
        color_type = turbojpeg.TJPF_RGB
    elseif n == 4 then
        color_type = turbojpeg.TJPF_RGBA
    else
        return false, "unsupported input format"
    end

    turbojpeg.tj3Set(handle, turbojpeg.TJPARAM_SUBSAMP, subsample or turbojpeg.TJSAMP_420)
    turbojpeg.tj3Set(handle, turbojpeg.TJPARAM_QUALITY, quality or 75)

    local jpeg_size = ffi.new("size_t [1]")
    local jpeg_image = ffi.new("unsigned char* [1]")

    local ok, err = turbojpeg.tj3Compress8(handle, source_ptr, w, stride or w * n, h, color_type, jpeg_image, jpeg_size) == 0
    if ok then
        local fhandle = C.open(filename, bit.bor(C.O_WRONLY, C.O_CREAT, C.O_TRUNC, C.O_CLOEXEC), ffi.cast("int", bit.bor(C.S_IRUSR, C.S_IWUSR, C.S_IRGRP, C.S_IROTH)))
        if fhandle >= 0 then
            C.write(fhandle, jpeg_image[0], jpeg_size[0])
            C.close(fhandle)
        else
            ok = false
            err = ffi.string(C.strerror(ffi.errno()))
        end
    else
        err = ffi.string(turbojpeg.tj3GetErrorStr(handle))
    end

    turbojpeg.tj3Destroy(handle)
    -- Handles NULL pointers sanely
    turbojpeg.tj3Free(jpeg_image[0])

    return ok, err
end

function Jpeg.writeBMP(filename, source_ptr, w, h, n, stride)
    local handle = tj3Init(turbojpeg.TJINIT_COMPRESS)
    assert(handle, "no TurboJPEG API compressor handle")

    local color_type
    if n == 1 then
        color_type = turbojpeg.TJPF_GRAY
    elseif n == 3 then
        color_type = turbojpeg.TJPF_RGB
    elseif n == 4 then
        color_type = turbojpeg.TJPF_RGBA
    else
        return false, "unsupported input format"
    end

    -- if file extension is not ".bmp" tjSaveImage uses netpbm format!
    local ret
    if filename:sub(-#".bmp") == ".bmp" then
        ret = turbojpeg.tj3SaveImage8(handle, filename, source_ptr, w, stride or w * n, h, color_type)
    else
        os.remove(filename)
        local tmp_filename = filename .. ".tmp.bmp"
        ret = turbojpeg.tj3SaveImage8(handle, tmp_filename, source_ptr, w, stride or w * n, h, color_type)
        os.rename(tmp_filename, filename)
    end

    local ok, err = ret == 0
    if not ok then
        err = ffi.string(turbojpeg.tj3GetErrorStr(handle))
    end

    turbojpeg.tj3Destroy(handle)

    return ok, err
end

return Jpeg
