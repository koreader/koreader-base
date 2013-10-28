local ffi = require("ffi")
local Blitbuffer = require("ffi/blitbuffer")
local pic_jpeg = ffi.load("libs/libpic_jpeg.so")

--require("ffi/pic_h")

ffi.cdef[[
typedef struct PicDocument {
	int width;
	int height;
	int components;
	uint8_t *image;
} PicDocument;

typedef struct PicPage {
	int width;
	int height;
	uint8_t *image;
	PicDocument *doc;
} PicPage;

uint8_t *jpegLoadFile(const char *fname, int *width, int *height, int *components);

void *malloc(int size);
void free(void *ptr);
void *memset(void *s, int c, int n);
]]

local Pic = {}

--[[
start of helper function
--]]

--[[
Uses luminance match for approximating the human perception of colour, as per
http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale

L = 0.299*Red + 0.587*Green + 0.114*Blue
--]]

function rgbToGrayscale(raw_img, w, h)
	local buf = ffi.cast("uint8_t*", ffi.C.malloc(w * h + 1))
	ffi.fill(buf, w*h+1)

	if buf == nil then
		return nil
	end

	local rgb_pos = 0
	local gray_pos = 0
	for x = 0, w-1 do
		for y = 0, h-1 do
			buf[gray_pos] = 0.299*raw_img[rgb_pos] + 0.587*raw_img[rgb_pos+1]
								+ 0.114*raw_img[rgb_pos+2]
			gray_pos = gray_pos + 1
			rgb_pos = rgb_pos + 3
		end
	end

	return buf
end


--[[
start of pic page type
--]]
local PicPage_mt = {__index={}}
local PicPage = ffi.metatype("PicPage", PicPage_mt)

function PicPage_mt.__index:getSize(dc)
	local zoom = dc:getZoom()
	return self['width'] * zoom, self['height'] * zoom
end

function PicPage_mt.__index:getUsedBBox()
	return 0.01, 0.01, -0.01, -0.01
end

function PicPage_mt.__index:close()
end
PicPage_mt.__gc = PicPage_mt.__index.close

function PicPage_mt.__index:drawPage(dc, bb)
end


--[[
start of pic document
--]]
local PicDoc_mt = {__index={}}
local PicDocument = ffi.metatype("PicDocument", PicDoc_mt)

function PicDoc_mt.__index:openPage()
	local page = PicPage({
		width = self["width"],
		height = self["height"],
		image = self["image"],
		doc = self,
	})
	return page
end

function PicDoc_mt.__index:getToc()
	return {}
end

function PicDoc_mt.__index:getPages()
	return 1
end

function PicDoc_mt.__index:getCacheSize()
	return 0
end

function PicDoc_mt.__index:cleanCache()
end

function PicDoc_mt.__index:getOriginalPageSize()
	return self['width'], self['height'], self['components']
end

function PicDoc_mt.__index:close()
	if self["image"] ~= nil then
		ffi.C.free(self["image"])
		self["image"] = nil
	end
end
PicDoc_mt.__gc = PicDoc_mt.__index.close


--[[
start of pic module API
--]]
function Pic.openDocument(filename)
	local doc = PicDocument()
	local w_p = ffi.new("int[1]")
	local h_p = ffi.new("int[1]")
	local comp_p = ffi.new("int[1]")

	local raw_img = pic_jpeg.jpegLoadFile(filename, w_p, h_p, comp_p)
	if raw_img == nil then
		error("Cannot open jpeg file")
	end

	if comp_p[0] == 1 then
		doc["image"] = raw_img
	elseif comp_p[0] == 3 then
		local gray_raw_img = rgbToGrayscale(raw_img, w_p[0], h_p[0])
		ffi.C.free(raw_img)

		if gray_raw_img == nil then
			error("Cannot convert image to grayscale")
		else
			doc["image"] = gray_raw_img
		end
	else
		ffi.C.free(raw_img)
		error("Unsupported image format")
	end

	doc["width"] = w_p[0]
	doc["height"] = h_p[0]
	doc["components"] = comp_p[0]

	return doc
end

return Pic
