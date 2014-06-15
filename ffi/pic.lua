local ffi = require("ffi")
local BB = require("ffi/blitbuffer")
local pic_jpeg = ffi.load("libs/libpic_jpeg.so")

ffi.cdef[[
uint8_t *jpegLoadFile(const char *fname, int *width, int *height, int *components);

void *malloc(int size);
void free(void *ptr);
void *memset(void *s, int c, int n);
]]

local Pic = {}

--[[
start of pic page type
--]]
local PicPage = {}

function PicPage:new(o)
    local o = o or {}
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
    scaled_bb:invert()
    bb:blitFullFrom(scaled_bb, 0, 0)
end


--[[
start of pic document
--]]
local PicDocument = {}

function PicDocument:new(o)
    local o = o or {}
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
    if self.raw_img then
        ffi.C.free(raw_img)
    end
end

PicDocument.__gc = PicDocument.close


--[[
start of pic module API
--]]
function Pic.openDocument(filename)
    local doc = PicDocument:new{}
    local w_p = ffi.new("int[1]")
    local h_p = ffi.new("int[1]")
    local comp_p = ffi.new("int[1]")

    local raw_img = pic_jpeg.jpegLoadFile(filename, w_p, h_p, comp_p)
    if raw_img == nil then
        error("Cannot open jpeg file")
    end

    doc.width = w_p[0]
    doc.height = h_p[0]

    if comp_p[0] == 1 then
        doc.image_bb = BB.new(doc.width, doc.height, BB.TYPE_BB8, raw_img)
    elseif comp_p[0] == 3 then
        doc.image_bb = BB.new(doc.width, doc.height, BB.TYPE_BBRGB24, raw_img)
    else
        ffi.C.free(raw_img)
        error("Unsupported image format")
    end

    doc.raw_img = raw_img
    doc.components = comp_p[0]

    return doc
end

return Pic
