--[[
rendering image with mupdf library
--]]

local ffi = require("ffi")
local Blitbuffer = require("ffi/blitbuffer")
local mupdf = ffi.load("libs/libmupdf.so")

require("ffi/mupdf_h")

local Image = {}

function Image:initContext(cache_size)
	self.context = mupdf.fz_new_context_imp(nil, nil, cache_size or bit.lshift(8, 20), "1.3")
end

function Image:_getFileData(filename)
	local f = io.open(filename)
	local data = f:read("*a")
	f:close()
	return data
end

function Image:loadPNGData(data)
	self.pixmap = mupdf.fz_load_png(self.context, data, #data)
end

function Image:toBlitBuffer()
	local pixmap = ffi.new("fz_pixmap[1]")
	pixmap = self.pixmap
	if self.pixmap.n ~= 2 then
		self.pixmap = mupdf.fz_new_pixmap(self.context, mupdf.fz_device_gray(self.context), 
										  pixmap.w, pixmap.h);
		mupdf.fz_convert_pixmap(self.context, self.pixmap, pixmap);
		mupdf.fz_drop_pixmap(self.context, pixmap);
	end
	self.bb = Blitbuffer.new(self.pixmap.w, self.pixmap.h)
	for y = 0, self.pixmap.h - 1 do
		for x = 0, self.pixmap.w - 1 do
			local pix = self.pixmap.samples[(x + y*self.pixmap.w)*2]
			self.bb:setPixel(x, y, bit.rshift(0xFF - pix, 4))
		end
	end
end

function Image:freeContext()
	if self.pixmap ~= nil then
		mupdf.fz_drop_pixmap(self.context, self.pixmap)
		self.pixmap = nil
	end
	if self.context ~= nil then
		mupdf.fz_free_context(self.context)
		self.context = nil
	end
end

function Image:fromPNG(filename)
	self:initContext()
	self:loadPNGData(self:_getFileData(filename))
	self:toBlitBuffer()
	self:freeContext()
	return self.bb
end

return Image
