--[[
rendering image with mupdf library
--]]

local ffi = require("ffi")
local Blitbuffer = require("ffi/blitbuffer")
local mupdf = ffi.load("libs/libmupdf.so")

require("ffi/mupdf_h")

local Image = {}

function Image:initContext(cache_size)
	-- Remember to change library version when upgrading MuPDF!
	self.context = mupdf.fz_new_context_imp(nil, nil, cache_size or bit.lshift(8, 20), "1.5")
end

function Image:loadImage(filename, width, height)
	local file = io.open(filename)
    if file then
	    local data = file:read("*a")
	    file:close()
	    self.image = mupdf.fz_new_image_from_data(self.context,
                        ffi.cast("unsigned char*", data), #data)
        if self.image ~= nil then
            self.pixmap = mupdf.fz_new_pixmap_from_image(self.context,
                        self.image, width or -1, height or -1)
        end
    end
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
	self.bb = Blitbuffer.new(self.pixmap.w, self.pixmap.h, Blitbuffer.TYPE_BB8A, self.pixmap.samples)
	self.bb:invert() -- our blitbuffers have reversed b->w scale
	self.bb = self.bb:copy() -- we make a copy so mupdf can drop the memory
end

function Image:freeContext()
	if self.pixmap ~= nil then
		mupdf.fz_drop_pixmap(self.context, self.pixmap)
		self.pixmap = nil
	end
    if self.image ~= nil then
        mupdf.fz_drop_image(self.context, self.image)
        self.image = nil
    end

    --[[ FIXME: segmentation fault when calling fz_free_context if we called
    -- fz_drop_image first. Although valgrind shows that commenting out
    -- fz_free_context does not leading to memory leak, it's still a dirty hack
    -- and need to be fixed by those who knows mupdf better.
	if self.context ~= nil then
		mupdf.fz_free_context(self.context)
		self.context = nil
	end
    --]]
end

function Image:fromFile(filename, width, height)
	self:initContext()
	self:loadImage(filename, width, height)
	self:toBlitBuffer()
	self:freeContext()
	return self.bb
end

return Image
