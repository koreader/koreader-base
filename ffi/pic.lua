local ffi = require("ffi")
local BB = require("ffi/blitbuffer")
local Png = require("ffi/png")

local dummy = require("ffi/turbojpeg_h")
local dummy = require("ffi/giflib_h")
local turbojpeg, giflib
if ffi.os == "Windows" then
    turbojpeg = ffi.load("libs/libturbojpeg.dll")
    giflib = ffi.load("libs/libgif-7.dll")
elseif ffi.os == "OSX" then
    turbojpeg = ffi.load("libs/libturbojpeg.dylib")
    giflib = ffi.load("libs/libgif.7.dylib")
else
    turbojpeg = ffi.load("libs/libturbojpeg.so")
    giflib = ffi.load("libs/libgif.so.7")
end

local Pic = {}

--[[
start of pic page type
--]]
local PicPage = {}

function PicPage:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function PicPage:getSize(dc)
    local zoom = dc:getZoom()
    return self.width * zoom, self.height * zoom
end

function PicPage:getUsedBBox()
    return 0.01, 0.01, -0.01, -0.01
end

function PicPage:close()
end

PicPage.__gc = PicPage.close

function PicPage:draw(dc, bb)
    local scaled_bb = self.image_bb:scale(bb:getWidth(), bb:getHeight())
    bb:blitFullFrom(scaled_bb, 0, 0)
end


--[[
start of pic document
--]]
local PicDocument = {}

function PicDocument:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function PicDocument:openPage()
    local page = PicPage:new{
        width = self.width,
        height = self.height,
        image_bb = self.image_bb,
        doc = self,
    }
    return page
end

function PicDocument:getToc()
    return {}
end

function PicDocument:getPages()
    return 1
end

function PicDocument:getCacheSize()
    return 0
end

function PicDocument:cleanCache()
end

function PicDocument:getOriginalPageSize()
    return self.width, self.height, self.components
end

function PicDocument:close()
    if self.image_bb ~= nil then
        self.image_bb:free()
        self.image_bb = nil
    end
end

PicDocument.__gc = PicDocument.close


local GifPage = PicPage:new()
function GifPage:close()
    -- with Gifs, the blitbuffers are per page
    if self.image_bb ~= nil then
        self.image_bb:free()
        self.image_bb = nil
    end
end

local GifDocument = PicDocument:new{
    giffile = nil,
}
function GifDocument:getPages()
    return self.giffile.ImageCount
end
function GifDocument:getOriginalPageSize(number)
    local i = self.giffile.SavedImages[number-1]
    return i.ImageDesc.Width, i.ImageDesc.Height, 4 -- components
end
function GifDocument:openPage(number)
    local i = self.giffile.SavedImages[number-1]
    local width = i.ImageDesc.Width
    local height = i.ImageDesc.Height
    local bb = BB.new(width, height, BB.TYPE_BBRGB32)

    local cmap = i.ImageDesc.ColorMap ~= nil and i.ImageDesc.ColorMap or self.giffile.SColorMap
    local palette={}
    -- TODO: transparency from Graphics Control Extension
    for c=0, cmap.ColorCount-1 do
        local color = cmap.Colors[c]
        palette[c] = BB.ColorRGB32(color.Red, color.Green, color.Blue, 0)
    end
    local p = i.RasterBits
    for y = 0, height-1 do
        for x = 0, width-1 do
            bb:setPixel(x, y, palette[p[0]])
            p = p + 1
        end
    end

    local page = GifPage:new{
        width = i.ImageDesc.Width,
        height = i.ImageDesc.Height,
        image_bb = bb,
        doc = self,
    }

    return page
end
function GifDocument:close()
    local err = ffi.new("int[1]")
    if giflib.DGifCloseFile(self.giffile, err) ~= giflib.GIF_OK then
        error(string.format("error closing/deallocating GIF: %s",
            ffi.string(giflib.GifErrorString(err[0]))))
    end
    self.giffile = nil
end

function Pic.openGIFDocument(filename)
    local err = ffi.new("int[1]")
    local giffile = giflib.DGifOpenFileName(filename, err)
    if giffile == nil then
        error(string.format("Cannot read GIF file: %s",
            ffi.string(giflib.GifErrorString(err[0]))))
    end
    if giflib.DGifSlurp(giffile) ~= giflib.GIF_OK then
        giflib.DGifCloseFile(giffile, err)
        error(string.format("Cannot parse GIF file: %s",
            ffi.string(giflib.GifErrorString(giffile.Error))))
    end
    return GifDocument:new{giffile = giffile}
end

function Pic.openPNGDocument(filename)
    local ok, re = Png.decodeFromFile(filename)
    if not ok then error(re) end

    local doc = PicDocument:new{width=re.width, height=re.height}
    doc.image_bb = BB.new(re.width, re.height, BB.TYPE_BBRGB32, re.data)
    -- mark buffer for freeing when Blitbuffer is freed:
    doc.image_bb:setAllocated(1)
    doc.components = 4
    return doc
end

function Pic.openJPGDocument(filename)
    local fh = io.open(filename, "r")
    assert(fh, "couldn't open file")
    local data = fh:read("*a")
    fh:close()

    local handle = turbojpeg.tjInitDecompress()
    assert(handle, "no TurboJPEG API decompressor handle")

    local width = ffi.new("int[1]")
    local height = ffi.new("int[1]")
    local jpegsubsamp = ffi.new("int[1]")

    turbojpeg.tjDecompressHeader2(handle, ffi.cast("unsigned char*", data), #data, width, height, jpegsubsamp)
    assert(width[0] > 0 and height[0] > 0, "image dimensions")

    local doc = PicDocument:new{width=width[0], height=height[0]}
    local format
    if Pic.color then
        doc.image_bb = BB.new(width[0], height[0], BB.TYPE_BBRGB24)
        doc.components = 3
        format = turbojpeg.TJPF_RGB
    else
        doc.image_bb = BB.new(width[0], height[0], BB.TYPE_BB8)
        doc.components = 1
        format = turbojpeg.TJPF_GRAY
    end

    if turbojpeg.tjDecompress2(handle, ffi.cast("unsigned char*", data), #data,
        ffi.cast("unsigned char*", doc.image_bb.data),
        width[0], doc.image_bb.pitch, height[0], format, 0) == -1 then
        error("decoding JPEG file")
    end

    turbojpeg.tjDestroy(handle)

    return doc
end

function Pic.openJPGDocumentFromMem(data)
    local handle = turbojpeg.tjInitDecompress()
    assert(handle, "no TurboJPEG API decompressor handle")

    local width = ffi.new("int[1]")
    local height = ffi.new("int[1]")
    local jpegsubsamp = ffi.new("int[1]")
    turbojpeg.tjDecompressHeader2(handle, ffi.cast("unsigned char*", data), #data, width, height, jpegsubsamp)

    local doc = PicDocument:new{width=width[0], height=height[0] }
    doc.image_bb = BB.new(width[0], height[0], BB.TYPE_BBRGB24)
    doc.components = 1
    local format = turbojpeg.TJPF_BGR

    if turbojpeg.tjDecompress2(handle, ffi.cast("unsigned char*", data), #data,
        ffi.cast("unsigned char*", doc.image_bb.data),
        width[0], doc.image_bb.pitch, height[0], format, 0) == -1 then
        return false
    end
    turbojpeg.tjDestroy(handle)
    return doc
end

--[[
start of pic module API
--]]
function Pic.openDocument(filename)
    local extension = string.lower(string.match(filename, ".+%.([^.]+)") or "")
    if extension == "jpg" or extension == "jpeg" then
        return Pic.openJPGDocument(filename)
    elseif extension == "png" then
        return Pic.openPNGDocument(filename)
    elseif extension == "gif" then
        return Pic.openGIFDocument(filename)
    else
        error("Unsupported image format")
    end
end

return Pic
