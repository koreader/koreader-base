--[[
rendering image with mupdf library
--]]

local ffi = require("ffi")
local Blitbuffer = require("ffi/blitbuffer")
local mupdf = nil
if ffi.os == "Windows" then
	mupdf = ffi.load("libs/libmupdf.dll")
else
	mupdf = ffi.load("libs/libmupdf.so")
end

require("ffi/mupdf_h")

local Image = {}

function Image:initContext(cache_size)
    -- Remember to change library version when upgrading MuPDF!
    self.context = mupdf.fz_new_context_imp(nil, nil, cache_size or bit.lshift(8, 20), "1.5")
end

function Image:_loadImage(data, size, width, height)
    local image = mupdf.fz_new_image_from_data(self.context,
                    ffi.cast("unsigned char*", data), size)
    if image ~= nil then
        self.pixmap = mupdf.fz_new_pixmap_from_image(self.context,
                    image, width or -1, height or -1)
        self.image = mupdf.fz_keep_image(self.context, image)
    end
end

function Image:loadImageFile(filename, width, height)
    local file = io.open(filename, "rb")
    if file then
        local data = file:read("*a")
        file:close()
        if data then
            self:_loadImage(data, #data, width, height)
        end
    end
end

function Image:loadImageData(data, size, width, height)
    if data and size then
        self:_loadImage(data, size, width, height)
    end
end

function Image:toBlitBuffer()
    if self.pixmap == nil then return end
    local pixmap = ffi.new("fz_pixmap*[1]", self.pixmap)[0]
    if self.pixmap.n ~= 2 then
        self.pixmap = mupdf.fz_new_pixmap(self.context, mupdf.fz_device_gray(self.context),
                        pixmap.w, pixmap.h);
        mupdf.fz_convert_pixmap(self.context, self.pixmap, pixmap);
        mupdf.fz_drop_pixmap(self.context, pixmap);
    end
    self.bb = Blitbuffer.new(self.pixmap.w, self.pixmap.h, Blitbuffer.TYPE_BB8A, self.pixmap.samples)
    self.bb:invert() -- our blitbuffers have reversed b->w scale
    self.bb = self.bb:copy() -- we make a copy so mupdf can drop the memory
end

function Image:freeContext()
    if self.image ~= nil then
        mupdf.fz_drop_image(self.context, self.image)
        self.image = nil
    end
    if self.pixmap ~= nil then
        mupdf.fz_drop_pixmap(self.context, self.pixmap)
        self.pixmap = nil
    end
    if self.context ~= nil then
        mupdf.fz_free_context(self.context)
        self.context = nil
    end
end

function Image:fromFile(filename, width, height)
    self:initContext(0)
    self:loadImageFile(filename, width, height)
    self:toBlitBuffer()
    self:freeContext()
    return self.bb
end

function Image:fromData(data, size, width, height)
    self:initContext(0)
    self:loadImageData(data, size, width, height)
    self:toBlitBuffer()
    self:freeContext()
    return self.bb
end

return Image
