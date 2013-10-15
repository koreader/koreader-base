--[[
rendering image with mupdf library
--]]

local ffi = require("ffi")
local Blitbuffer = require("ffi/blitbuffer")
local mupdf = ffi.load("libs/libmupdf.so")

ffi.cdef[[
typedef struct fz_alloc_context_s fz_alloc_context;
typedef struct fz_locks_context_s fz_locks_context;
typedef struct fz_colorspace_s fz_colorspace;
typedef struct fz_context_s fz_context;

typedef struct fz_storable_s fz_storable;
typedef void (fz_store_free_fn)(fz_context *, fz_storable *);
typedef struct fz_storable_s {
	int refs;
	fz_store_free_fn *free;
} fz_storable;

typedef struct fz_pixmap_s {
	fz_storable storable;
	int x, y, w, h, n;
	int interpolate;
	int xres, yres;
	fz_colorspace *colorspace;
	unsigned char *samples;
	int free_samples;
} fz_pixmap;

fz_context *fz_new_context_imp(fz_alloc_context *alloc, fz_locks_context *locks, unsigned int max_store, const char *version);
fz_pixmap *fz_new_pixmap(fz_context *ctx, fz_colorspace *cs, int w, int h);
fz_pixmap *fz_load_png(fz_context *ctx, const char *data, int size);
void fz_convert_pixmap(fz_context *ctx, fz_pixmap *dst, fz_pixmap *src);
void fz_drop_pixmap(fz_context *ctx, fz_pixmap *pix);
fz_colorspace *fz_device_gray(fz_context *ctx);
void fz_free_context(fz_context *ctx);
]]

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
