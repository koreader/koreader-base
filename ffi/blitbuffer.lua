--[[
Generic blitbuffer/GFX stuff that works on memory buffers
--]]

local ffi = require("ffi")

-- we will use this extensively
local floor = math.floor
local rshift = bit.rshift
local lshift = bit.lshift
local band = bit.band
local bor = bit.bor
local bxor = bit.bxor

local intt = ffi.typeof("int")
local uint32pt = ffi.typeof("uint32_t*")
local posix = require("ffi/posix_h")

-- the following definitions are redundant.
-- they need to be since only this way we can set
-- different metatables for them.
ffi.cdef[[
typedef struct BlitBuffer4 {
        int w; 
        int h; 
        int pitch;
        uint8_t *data;
        uint8_t allocated;
} BlitBuffer4;
typedef struct BlitBuffer8 {
        int w; 
        int h; 
        int pitch;
        uint8_t *data;
        uint8_t allocated;
} BlitBuffer8;
typedef struct BlitBufferA8 {
        int w; 
        int h; 
        int pitch;
        uint8_t *data;
        uint8_t allocated;
} BlitBufferA8;
typedef struct BlitBuffer16 {
        int w; 
        int h; 
        int pitch;
        uint8_t *data;
        uint8_t allocated;
} BlitBuffer16;
typedef struct BlitBufferRGB24 {
        int w; 
        int h; 
        int pitch;
        uint8_t *data;
        uint8_t allocated;
} BlitBufferRGB24;
typedef struct BlitBufferRGB32 {
        int w; 
        int h; 
        int pitch;
        uint8_t *data;
        uint8_t allocated;
} BlitBufferRGB32;

typedef struct Color4L {
	uint8_t a;
} Color4L;
typedef struct Color4U {
	uint8_t a;
} Color4U;
typedef struct Color8 {
	uint8_t a;
} Color8;
typedef struct ColorA8 {
	uint8_t a;
	uint8_t dummy; // only support pre-multiplied for now
} ColorA8;
typedef struct Color16 {
	uint16_t a;
} Color16;
typedef struct ColorRGB24 {
	uint8_t r;
	uint8_t g;
	uint8_t b;
} ColorRGB24;
typedef struct ColorRGB32 {
	uint8_t r;
	uint8_t g;
	uint8_t b;
	uint8_t a;
} ColorRGB32;

void *malloc(int size);
void free(void *ptr);
void *memset(void *s, int c, int n);
]]

local BB = {}

-- this is only needed for casting userdata from the Lua/C API:
local BBtype = ffi.typeof("BlitBuffer4*")

-- color value types
local Color4U = ffi.typeof("Color4U")
local Color4L = ffi.typeof("Color4L")
local Color8 = ffi.typeof("Color8")
local ColorA8 = ffi.typeof("ColorA8")
local Color16 = ffi.typeof("Color16")
local ColorRGB24 = ffi.typeof("ColorRGB24")
local ColorRGB32 = ffi.typeof("ColorRGB32")

-- color value pointer types
local P_Color4U = ffi.typeof("Color4U*")
local P_Color4L = ffi.typeof("Color4L*")
local P_Color8 = ffi.typeof("Color8*")
local P_ColorA8 = ffi.typeof("ColorA8*")
local P_Color16 = ffi.typeof("Color16*")
local P_ColorRGB24 = ffi.typeof("ColorRGB24*")
local P_ColorRGB32 = ffi.typeof("ColorRGB32*")

-- metatables for BlitBuffer objects:
local BB4_mt = {__index={}}
local BB8_mt = {__index={}}
local BBA8_mt = {__index={}}
local BB16_mt = {__index={}}
local BBRGB24_mt = {__index={}}
local BBRGB32_mt = {__index={}}

-- virtual blitbuffers:
local BB_rotated_mt = {__index={}}
local BB_inverted_mt = {__index={}}
local BB_masked_mt = {__index={}}

-- this is like a metatable for the others,
-- but we don't make it a metatable because LuaJIT
-- doesn't cope well with ctype metatables with
-- metatables on them
-- we just replicate what's in the following table
-- when we set the other metatables for their types
local BB_mt = {__index={}}

-- metatables for color types:
local Color4L_mt = {__index={}}
local Color4U_mt = {__index={}}
local Color8_mt = {__index={}}
local ColorA8_mt = {__index={}}
local Color16_mt = {__index={}}
local ColorRGB24_mt = {__index={}}
local ColorRGB32_mt = {__index={}}

-- getPixelP (pointer) routines
function BB4_mt.__index:getPixelP(x, y)
	--self:checkCoordinates(x, y)
	local p = self.data + self.pitch*y + rshift(x, 1)
	if band(x, 1) == 0 then 
		return ffi.cast(P_Color4U, p), true
	else
		return ffi.cast(P_Color4L, p), false
	end
end
function BB8_mt.__index:getPixelP(x, y)
	--self:checkCoordinates(x, y)
	return ffi.cast(P_Color8, self.data + self.pitch*y + x)
end
function BBA8_mt.__index:getPixelP(x, y)
	--self:checkCoordinates(x, y)
	return ffi.cast(P_ColorA8, self.data + self.pitch*y + lshift(x,1))
end
function BB16_mt.__index:getPixelP(x, y)
	--self:checkCoordinates(x, y)
	return ffi.cast(P_Color16, self.data + self.pitch*y + lshift(x,1))
end
function BBRGB24_mt.__index:getPixelP(x, y)
	--self:checkCoordinates(x, y)
	return ffi.cast(P_ColorRGB24, self.data + self.pitch*y + x*3)
end
function BBRGB32_mt.__index:getPixelP(x, y)
	--self:checkCoordinates(x, y)
	return ffi.cast(P_ColorRGB32, self.data + self.pitch*y + lshift(x,2))
end
function BB_rotated_mt.__index:getPixelP(x, y)
	if self.degree == 90 then 
		return self.bb:getPixelP(self.bb.w - y - 1, x)
	elseif self.degree == 180 then
		return self.bb:getPixelP(self.bb.w - x - 1, self.bb.h - y - 1)
	elseif self.degree == 270 then
		return self.bb:getPixelP(y, self.bb.h - x - 1)
	end
	error("could not get pixel pointer for this rotation")
end
function BB_inverted_mt.__index:getPixelP(x, y)
	return self.bb:getPixelP(x, y)
end

-- coordinate checking
--function BB_mt.__index:checkCoordinates(x, y) end
function BB_mt.__index:checkCoordinates(x, y)
	assert(x >= 0, "x coordinate >= 0")
	assert(y >= 0, "y coordinate >= 0")
	assert(x < self.w, "x coordinate < width")
	assert(y < self.h, "y coordinate < height")
end

function BB_mt.__index:getPixel(x, y) return self:getPixelP(x, y)[0] end
function BB_inverted_mt.__index:getPixel(x, y) return self:getPixelP(x, y)[0]:invert() end

-- color conversions:
-- to Color4L:
function Color4L_mt.__index:getColor4L() return Color4L(band(self.a, 0x0F)) end
function Color4U_mt.__index:getColor4L() return Color4L(rshift(self.a, 4)) end
function Color8_mt.__index:getColor4L() return Color4L(rshift(self.a, 4)) end
function ColorA8_mt.__index:getColor4L() return Color4L(rshift(self.a, 4)) end
function Color16_mt.__index:getColor4L() return Color4L(rshift(self.a, 12)) end
--[[
Uses luminance match for approximating the human perception of colour, as per
http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale

L = 0.299*Red + 0.587*Green + 0.114*Blue
--]]
function ColorRGB24_mt.__index:getColor4L()
	return Color4L(rshift(4897*self.r + 9617*self.g + 1868*self.b, 18))
end
ColorRGB32_mt.__index.getColor4L = ColorRGB24_mt.__index.getColor4L

-- to Color4U:
function Color4L_mt.__index:getColor4U() return Color4U(lshift(self.a, 4)) end
function Color4U_mt.__index:getColor4U() return Color4U(band(self.a, 0xF0)) end
function Color8_mt.__index:getColor4U() return Color4U(band(self.a, 0xF0)) end
function ColorA8_mt.__index:getColor4U() return Color4U(band(self.a, 0xF0)) end
function Color16_mt.__index:getColor4U() return Color4U(band(rshift(self.a,8),0xF0)) end
function ColorRGB24_mt.__index:getColor4U()
	return Color4U(band(rshift(4897*self.r + 9617*self.g + 1868*self.b, 14), 0xF0))
end
ColorRGB32_mt.__index.getColor4U = ColorRGB24_mt.__index.getColor4U

-- to Color8:
function Color4L_mt.__index:getColor8()
	local v = band(self.a, 0x0F)
	return Color8(v*0x11)
end
function Color4U_mt.__index:getColor8()
	local v = band(self.a, 0xF0)
	return Color8(bor(rshift(v, 4), v))
end
function Color8_mt.__index:getColor8() return self end
function ColorA8_mt.__index:getColor8() return Color8(self.a) end
function Color16_mt.__index:getColor8() return Color8(self.a) end
function ColorRGB24_mt.__index:getColor8()
	return Color8(rshift(4897*self:getR() + 9617*self:getG() + 1868*self:getB(), 14))
end
ColorRGB32_mt.__index.getColor8 = ColorRGB24_mt.__index.getColor8

-- to ColorA8:
function Color4L_mt.__index:getColorA8()
	local v = band(self.a, 0x0F)
	return ColorA8(v*0x11)
end
function Color4U_mt.__index:getColorA8()
	local v = band(self.a, 0xF0)
	return ColorA8(bor(rshift(v, 4), v))
end
function Color8_mt.__index:getColorA8() return ColorA8(self.a) end
function ColorA8_mt.__index:getColorA8() return self end
function Color16_mt.__index:getColorA8() return ColorA8(self.a) end
function ColorRGB24_mt.__index:getColorA8()
	return ColorA8(rshift(4897*self:getR() + 9617*self:getG() + 1868*self:getB(), 14))
end
ColorRGB32_mt.__index.getColorA8 = ColorRGB24_mt.__index.getColorA8

-- to Color16:
function Color4L_mt.__index:getColor16()
	local v = self:getColor8().a
	return Color16(bor(v, lshift(v, 8)))
end
Color4U_mt.__index.getColor16 = Color4L_mt.__index.getColor16
Color8_mt.__index.getColor16 = Color4L_mt.__index.getColor16
ColorA8_mt.__index.getColor16 = Color4L_mt.__index.getColor16
function Color16_mt.__index.getColor16() return self end
ColorRGB24_mt.__index.getColor16 = Color4L_mt.__index.getColor16
ColorRGB32_mt.__index.getColor16 = Color4L_mt.__index.getColor16

-- to ColorRGB24:
function Color4L_mt.__index:getColorRGB24()
	local v = self:getColor8()
	return ColorRGB24(v.a, v.a, v.a)
end
Color4U_mt.__index.getColorRGB24 = Color4L_mt.__index.getColorRGB24
Color8_mt.__index.getColorRGB24 = Color4L_mt.__index.getColorRGB24
ColorA8_mt.__index.getColorRGB24 = Color4L_mt.__index.getColorRGB24
Color16_mt.__index.getColorRGB24 = Color4L_mt.__index.getColorRGB24
function ColorRGB24_mt.__index:getColorRGB24() return self end
function ColorRGB32_mt.__index:getColorRGB24() return ColorRGB24(self.r, self.g, self.b) end

-- to ColorRGB32:
function Color4L_mt.__index:getColorRGB32()
	local v = self:getColor8()
	return ColorRGB32(v.a, v.a, v.a, 0)
end
Color4U_mt.__index.getColorRGB32 = Color4L_mt.__index.getColorRGB32
Color8_mt.__index.getColorRGB32 = Color4L_mt.__index.getColorRGB32
ColorA8_mt.__index.getColorRGB32 = Color4L_mt.__index.getColorRGB32
Color16_mt.__index.getColorRGB32 = Color4L_mt.__index.getColorRGB32
function ColorRGB24_mt.__index:getColorRGB32() return ColorRGB32(self.r, self.g, self.b) end
function ColorRGB32_mt.__index:getColorRGB32() return self end

-- RGB getters (special case for 4bpp mode)
Color4L_mt.__index.getR = Color4L_mt.__index.getColor8
Color4L_mt.__index.getG = Color4L_mt.__index.getColor8
Color4L_mt.__index.getB = Color4L_mt.__index.getColor8
Color4U_mt.__index.getR = Color4U_mt.__index.getColor8
Color4U_mt.__index.getG = Color4U_mt.__index.getColor8
Color4U_mt.__index.getB = Color4U_mt.__index.getColor8
Color8_mt.__index.getR = Color8_mt.__index.getColor8
Color8_mt.__index.getG = Color8_mt.__index.getColor8
Color8_mt.__index.getB = Color8_mt.__index.getColor8
ColorA8_mt.__index.getR = ColorA8_mt.__index.getColor8
ColorA8_mt.__index.getG = ColorA8_mt.__index.getColor8
ColorA8_mt.__index.getB = ColorA8_mt.__index.getColor8
Color16_mt.__index.getR = Color16_mt.__index.getColor8
Color16_mt.__index.getG = Color16_mt.__index.getColor8
Color16_mt.__index.getB = Color16_mt.__index.getColor8
function ColorRGB24_mt.__index:getR() return self.r end
function ColorRGB24_mt.__index:getG() return self.g end
function ColorRGB24_mt.__index:getB() return self.b end
ColorRGB32_mt.__index.getR = ColorRGB24_mt.__index.getR
ColorRGB32_mt.__index.getG = ColorRGB24_mt.__index.getG
ColorRGB32_mt.__index.getB = ColorRGB24_mt.__index.getB

-- modifications:
-- inversion:
function Color4L_mt.__index:invert() return Color4L(bxor(self.a, 0x0F)) end
function Color4U_mt.__index:invert() return Color4U(bxor(self.a, 0xF0)) end
function Color8_mt.__index:invert() return Color8(bxor(self.a, 0xFF)) end
function ColorA8_mt.__index:invert() return ColorA8(bxor(self.a, 0xFF)) end
function Color16_mt.__index:invert() return Color16(bxor(self.a, 0xFFFF)) end
function ColorRGB24_mt.__index:invert()
	return ColorRGB24(bxor(self.r, 0xFF), bxor(self.g, 0xFF), bxor(self.b, 0xFF))
end
function ColorRGB32_mt.__index:invert()
	return ColorRGB32(bxor(self.r, 0xFF), bxor(self.g, 0xFF), bxor(self.b, 0xFF))
end
-- adding two colors:
function Color4L_mt.__index:add(color, intensity)
	local value = tonumber(self.a) * intensity + tonumber(color:getColor4L().a) * (1-intensity)
	if value > 0x0F then value = 0x0F end
	return Color4L(value)
end
function Color4U_mt.__index:add(color, intensity)
	local orig = band(self.a, 0xF0)
	local value = tonumber(orig) * intensity + tonumber(color:getColor4U().a) * (1-intensity)
	if value > 0xF0 then value = 0xF0 end
	--return Color4U(band(ffi.cast("uint8_t", value), 0xF0))
	return Color4U(band(value, 0xF0))
end
function Color8_mt.__index:add(color, intensity)
	local value = tonumber(self.a) * intensity + tonumber(color:getColor8().a) * (1-intensity)
	if value > 0xFF then value = 0xFF end
	return Color8(value)
end
function ColorA8_mt.__index:add(color, intensity)
	return self:getColor8():add(color, intensity):getColorA8()
end
function Color16_mt.__index:add(color, intensity)
	local value = tonumber(self.a) * intensity + tonumber(color:getColor16().a) * (1-intensity)
	if value > 0xFFFF then value = 0xFFFF end
	return Color16(value)
end
function ColorRGB24_mt.__index:add(color, intensity)
	local r = tonumber(self:getR()) * intensity + tonumber(color:getR()) * (1-intensity)
	if r > 255 then r = 255 end
	local g = tonumber(self:getG()) * intensity + tonumber(color:getG()) * (1-intensity)
	if g > 255 then g = 255 end
	local b = tonumber(self:getB()) * intensity + tonumber(color:getB()) * (1-intensity)
	if b > 255 then b = 255 end
	return ColorRGB24(r, g, b)
end
function ColorRGB32_mt.__index:add(color, intensity)
	return ColorRGB24_mt.__index.add(self, color, intensity):getColorRGB32()
end
-- dimming
function Color4L_mt.__index:dim()
	return Color8(rshift(self:getColor8().a, 1))
end
Color4U_mt.__index.dim = Color4L_mt.__index.dim
Color8_mt.__index.dim = Color4L_mt.__index.dim
ColorA8_mt.__index.dim = Color4L_mt.__index.dim
Color16_mt.__index.dim = Color4L_mt.__index.dim
ColorRGB24_mt.__index.dim = Color4L_mt.__index.dim
ColorRGB32_mt.__index.dim = Color4L_mt.__index.dim
-- lighten up
function Color4L_mt.__index:lighten(low)
	local value = self:getColor4L().a
	low = low * 0x0F
	if value < low then return Color4L(low) end
	return self
end
Color4U_mt.__index.lighten = Color4L_mt.__index.lighten
Color8_mt.__index.lighten = Color4L_mt.__index.lighten
ColorA8_mt.__index.lighten = Color4L_mt.__index.lighten
Color16_mt.__index.lighten = Color4L_mt.__index.lighten
ColorRGB24_mt.__index.lighten = Color4L_mt.__index.lighten
ColorRGB32_mt.__index.lighten = Color4L_mt.__index.lighten
-- masking
function Color4L_mt.__index:mask(fg, bg)
	return fg:add(bg, tonumber(self:getColor8().a) / 0xFF)
end
Color4U_mt.__index.mask = Color4L_mt.__index.mask
Color8_mt.__index.mask = Color4L_mt.__index.mask
ColorA8_mt.__index.mask = Color4L_mt.__index.mask
Color16_mt.__index.mask = Color4L_mt.__index.mask
ColorRGB24_mt.__index.mask = Color4L_mt.__index.mask
ColorRGB32_mt.__index.mask = Color4L_mt.__index.mask

function BB4_mt.__index.getMyColor(color) return color:getColor4L() end
function BB8_mt.__index.getMyColor(color) return color:getColor8() end
function BBA8_mt.__index.getMyColor(color) return color:getColorA8() end
function BB16_mt.__index.getMyColor(color) return color:getColor16() end
function BBRGB24_mt.__index.getMyColor(color) return color:getColorRGB24() end
function BBRGB32_mt.__index.getMyColor(color) return color:getColorRGB32() end

function BB_mt.__index:isInverted() return false end
function BB_inverted_mt.__index:isInverted() return true end
function BB_mt.__index:invert()
	if self:isInverted() then return self.bb end
	local bb = {
		bb = self,
		w = self.w,
		h = self.h,
		pitch = self.pitch,
		data = self.data,
		blitfunc = self.blitfunc,
		getMyColor = self.getMyColor
	}
	setmetatable(bb, BB_inverted_mt)
	return bb
end
function BB_mt.__index:isRotated() return false end
function BB_rotated_mt.__index:isRotated() return true end
function BB_mt.__index:rotate(degree)
	local backing_bb = self
	if self:isRotated() then
		-- combine rotations
		degree = (degree + self.degree)
		backing_bb = self.bb
	end
	degree = degree % 360
	if degree == 0 then return self.bb end
	local bb = {
		bb = backing_bb,
		w = self.w,
		h = self.h,
		degree = degree,
		pitch = backing_bb.pitch,
		data = backing_bb.data,
		getMyColor = backing_bb.getMyColor,
		select_y_upper = 2,
		select_x_upper = 2
	}
	if degree == 90 or degree == 270 then
		bb.w = backing_bb.h
		bb.h = backing_bb.w
	end
	if degree == 90 then bb.select_y_upper = 1
	elseif degree == 180 then bb.select_x_upper = 1
	elseif degree == 270 then bb.select_y_upper = 0
	end
	setmetatable(bb, BB_rotated_mt)
	return bb
end
BB_mt.__index.rotateAbsolute = BB_mt.__index.rotate
function BB_rotated_mt.__index:rotateAbsolute(degree)
	return self:rotate(degree - self.degree)
end
function BB_mt.__index:getBpp() return self.bb:getBpp() end
function BB_mt.__index:isRGB() return self.bb:isRGB() end

-- set pixel values
function BB_mt.__index:setPixel(x, p, color)
	if x then p = self:getPixelP(x, p) end
	p[0] = self.getMyColor(color)
end
-- two-pixel setting for 4bpp mode
function BB4_mt.__index:setPixel(x, y, color, dummy, color2)
	if x then
		local p, is_upper = self:getPixelP(x, y)
		if is_upper then
			p[0].a = bor(band(p[0].a, 0x0F), color:getColor4U().a)
		else
			p[0].a = bor(band(p[0].a, 0xF0), color:getColor4L().a)
		end
	else
		local p = y
		p[0].a = bor(
				(color and color:getColor4U().a) or band(p[0].a, 0xF0),
				(color2 and color2:getColor4L().a) or band(p[0].a, 0x0F)
			)
	end
end

function BB_inverted_mt.__index:setPixel(x, p, color, dummy, color2)
	-- this will work for both 4bpp and other modes
	self.bb:setPixelInverted(x, p, color, dummy, color2)
end

function BB_mt.__index:setPixelInverted(x, p, color)
	self:setPixel(x, p, color:invert())
end
function BB4_mt.__index:setPixelInverted(x, p, color, dummy, color2)
	self:setPixel(x, p, color and color:invert(), dummy, color2 and color2:invert())
end
function BB_inverted_mt.__index:setPixelInverted(x, p, color, dummy, color2)
	-- this will work for both 4bpp and other modes
	self.bb:setPixel(x, p, color, dummy, color2)
end

function BB_mt.__index:setPixelAdd(x, p, color, intensity)
	if x then p = self:getPixelP(x, p) end
	p[0] = self.getMyColor(color):add(p[0], intensity)
end
function BB4_mt.__index:setPixelAdd(x, p, color, intensity, color2)
	if x then
		p = self:getPixelP(x, p)
		if band(x, 1) == 1 then
			color2 = color
			color = nil
		end
	end
	local v1 = band(p[0].a, 0xF0)
	local v2 = band(p[0].a, 0x0F)
	if color then
		v1 = tonumber(v1) * (1-intensity) + tonumber(color:getColor4U().a) * intensity
		if v1 > 0xF0 then v1 = 0xF0 end
		v1 = band(v1, 0xF0)
	end
	if color2 then
		v2 = tonumber(v2) * (1-intensity) + tonumber(color2:getColor4L().a) * intensity
		if v2 > 0x0F then v2 = 0x0F end
	end
	p[0].a = bor(v1, v2)
end

function BB_mt.__index:setPixelDim(x, p, color, dummy, color2)
	-- this will work for both 4bpp and other modes
	self:setPixel(x, p, color and color:dim(), dummy, color2 and color2:dim())
end

function BB_mt.__index:setPixelLighten(x, p, color, low, color2)
	-- this will work for both 4bpp and other modes
	self:setPixel(x, p, color and color:lighten(low), dummy, color2 and color2:lighten(low))
end

-- checked Pixel setting:
function BB_mt.__index:setPixelClamped(x, y, color)
	if x >= 0 and x < self.w and y >= 0 and y < self.h then
		self:setPixel(x, y, color)
	end
end

function BB4_mt.__index:getBpp() return 4 end
function BB8_mt.__index:getBpp() return 8 end
function BBA8_mt.__index:getBpp() return 16 end
function BB16_mt.__index:getBpp() return 16 end
function BBRGB24_mt.__index:getBpp() return 24 end
function BBRGB32_mt.__index:getBpp() return 32 end

function BB4_mt.__index:isRGB() return false end
function BB8_mt.__index:isRGB() return false end
function BBA8_mt.__index:isRGB() return false end
function BB16_mt.__index:isRGB() return false end
function BBRGB24_mt.__index:isRGB() return true end
function BBRGB32_mt.__index:isRGB() return true end

-- compatibility functions for accessing dimensions
function BB_mt.__index:getWidth() return self.w end
function BB_mt.__index:getHeight() return self.h end

-- names of optimized blitting routines
BB_mt.__index.blitfunc = "blitDefault" -- not optimized
BB4_mt.__index.blitfunc = "blitTo4"
BB8_mt.__index.blitfunc = "blitTo8"
BBA8_mt.__index.blitfunc = "blitToA8"
BB16_mt.__index.blitfunc = "blitTo16"
BBRGB24_mt.__index.blitfunc = "blitToRGB24"
BBRGB32_mt.__index.blitfunc = "blitToRGB32"

--[[
generic boundary check for copy operations

@param length length of copy operation
@param target_offset where to place part into target
@param source_offset where to take part from in source
@param target_size length of target buffer
@param source_size length of source buffer

@return adapted length that actually fits
@return adapted target offset, guaranteed within range 0..(target_size-1)
@return adapted source offset, guaranteed within range 0..(source_size-1)
--]]
local function checkBounds(length, target_offset, source_offset, target_size, source_size)
	-- deal with negative offsets
	if target_offset < 0 then
		length = length + target_offset
		source_offset = source_offset - target_offset
		target_offset = 0
	end
	if source_offset < 0 then
		length = length + source_offset
		target_offset = target_offset - source_offset
		source_offset = 0
	end
	-- calculate maximum lengths (size left starting at offset)
	local target_left = target_size - target_offset
	local source_left = source_size - source_offset
	-- return corresponding values
	if target_left <= 0 or source_left <= 0 then
		return 0, 0, 0
	elseif length <= target_left and length <= source_left then
		-- length is the smallest value
		return floor(length), floor(target_offset), floor(source_offset)
	elseif target_left < length and target_left < source_left then
		-- target_left is the smalles value
		return floor(target_left), floor(target_offset), floor(source_offset)
	else
		-- source_left must be the smallest value
		return floor(source_left), floor(target_offset), floor(source_offset)
	end
end

function BB_mt.__index:blitDefault(dest, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
	-- slow default variant:
	local o_y = offs_y
	for y = dest_y, dest_y+height-1 do
		local o_x = offs_x
		for x = dest_x, dest_x+width-1 do
			setter(dest, x, y, self:getPixel(o_x, o_y), set_param)
			o_x = o_x + 1
		end
		o_y = o_y + 1
	end
end
-- no optimized blitting by default:
BB_mt.__index.blitTo4 = BB_mt.__index.blitDefault
BB_mt.__index.blitTo8 = BB_mt.__index.blitDefault
BB_mt.__index.blitToA8 = BB_mt.__index.blitDefault
BB_mt.__index.blitTo16 = BB_mt.__index.blitDefault
BB_mt.__index.blitToRGB24 = BB_mt.__index.blitDefault
BB_mt.__index.blitToRGB32 = BB_mt.__index.blitDefault

-- slightly optimized default routine for blitting to 4bpp buffers
function BB_mt.__index:blitTo4(dest, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
	local o_y = offs_y
	if band(dest_x, 1) == 1 then
		-- one "odd" column to process first
		for y = dest_y, dest_y+height-1 do
			setter(dest, dest_x, y, self:getPixel(offs_x, o_y), set_param)
			o_y = o_y + 1
		end
		dest_x = dest_x + 1
		offs_x = offs_x + 1
		width = width - 1
		o_y = offs_y
	end
	if band(width, 1) == 1 then
		-- one "odd" column at the end of each line
		local x = dest_x + width - 1
		local o_x = offs_x + width - 1
		for y = dest_y, dest_y+height-1 do
			setter(dest, x, y, self:getPixel(o_x, o_y), set_param)
			o_y = o_y + 1
		end
		width = width - 1
		o_y = offs_y
	end
	if width == 0 then return end
	-- now do the "doubles" in between
	for y = dest_y, dest_y+height-1 do
		local o_x = offs_x
		local p = dest:getPixelP(dest_x, y)
		for x = 0, width-2, 2 do
			setter(dest, nil, p, self:getPixel(o_x, o_y), set_param, self:getPixel(o_x+1, o_y))
			p = p + 1
			o_x = o_x + 2
		end
		o_y = o_y + 1
	end
	return true
end

-- optimized 4bpp to 4bpp blitting
function BB4_mt.__index:blitTo4(dest, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
	local o_y = offs_y
	for y = dest_y, dest_y+height-1 do
		local w = width
		local dest_p = dest:getPixelP(dest_x, y)
		local source_p = self:getPixelP(offs_x, o_y)
		if band(offs_x, 1) == 1 then
			-- odd source x coordinate
			local nv = source_p[0]
			source_p = source_p + 1
			if band(dest_x, 1) == 1 then
				-- ... and odd destination x coordinate
				setter(dest, nil, dest_p, nil, set_param, nv)
				dest_p = dest_p + 1
				w = w - 1
				while w > 1 do
					nv = source_p[0]
					setter(dest, nil, dest_p, Color4U(nv.a), set_param, nv)
					source_p = source_p + 1
					dest_p = dest_p + 1
					w = w - 2
				end
				if w > 0 then
					setter(dest, nil, dest_p, Color4U(source_p[0].a), set_param, nil)
				end
			else
				-- even destination coordinate
				while w > 1 do
					local v = source_p[0]
					setter(dest, nil, dest_p, Color4L(nv.a), set_param, Color4U(v.a))
					nv = v
					source_p = source_p + 1
					dest_p = dest_p + 1
					w = w - 2
				end
				if w > 0 then
					setter(dest, nil, dest_p, Color4L(nv.a), set_param, nil)
				end
			end
		else
			-- even source x coordinate
			if band(dest_x, 1) == 1 then
				-- ..but odd destination x coordinate
				local nv = source_p[0]
				source_p = source_p + 1
				setter(dest, nil, dest_p, nil, set_param, nv)
				dest_p = dest_p + 1
				w = w - 1
				while w > 1 do
					local v = source_p[0]
					setter(dest, nil, dest_p, Color4L(nv.a), set_param, v)
					nv = v
					source_p = source_p + 1
					dest_p = dest_p + 1
					w = w - 2
				end
				if w > 0 then
					setter(dest, nil, dest_p, Color4L(nv.a), set_param, nil)
				end
			else
				-- even destination x coordinate
				while w > 1 do
					local v = source_p[0]
					setter(dest, nil, dest_p, v, set_param, Color4L(v.a))
					source_p = source_p + 1
					dest_p = dest_p + 1
					w = w - 2
				end
				if w > 0 then
					setter(dest, nil, dest_p, source_p[0], set_param, nil)
				end
			end
		end
		o_y = o_y + 1
	end
	return true
end

function BB4_mt.__index:blitTo8(dest, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
	local o_y = offs_y
	for y = dest_y, dest_y+height-1 do
		local w = width
		local dest_p = dest:getPixelP(dest_x, y)
		local source_p = self:getPixelP(offs_x, o_y)
		if band(offs_x, 1) == 1 then
			local v = source_p[0].a
			local l = band(v, 0x0F)
			setter(dest, nil, dest_p, Color8(bor(l, lshift(l, 4))), set_param)
			dest_p = dest_p + 1
			source_p = source_p + 1
			w = w - 1
		end
		while w > 1 do
			local v = source_p[0].a
			local u = band(v, 0xF0)
			local l = band(v, 0x0F)
			setter(dest, nil, dest_p, Color8(bor(u, rshift(u, 4))), set_param)
			dest_p = dest_p + 1
			setter(dest, nil, dest_p, Color8(bor(l, lshift(l, 4))), set_param)
			dest_p = dest_p + 1
			source_p = source_p + 1
			w = w - 2
		end
		if w > 0 then
			local v = source_p[0].a
			local u = band(v, 0xF0)
			setter(dest, nil, dest_p, Color8(bor(u, rshift(u, 4))), set_param)
		end
		o_y = o_y + 1
	end
	return true
end
BB4_mt.__index.blitToA8 = BB4_mt.__index.blitTo8
BB4_mt.__index.blitTo16 = BB4_mt.__index.blitTo8
BB4_mt.__index.blitToRGB24 = BB4_mt.__index.blitTo8
BB4_mt.__index.blitToRGB32 = BB4_mt.__index.blitTo8

function BB_mt.__index:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
	width, height = width or source.w, height or source.h
	width, dest_x, offs_x = checkBounds(width, dest_x or 0, offs_x or 0, self.w, source.w)
	height, dest_y, offs_y = checkBounds(height, dest_y or 0, offs_y or 0, self.h, source.h)
	if not setter then setter = self.setPixel end

	if width <= 0 or height <= 0 then return end
	return source[self.blitfunc](source, self, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
end
BB_mt.__index.blitFullFrom = BB_mt.__index.blitFrom

function BB_mt.__index:addblitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, intensity)
	self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixelAdd, intensity)
end

function BB_mt.__index:blitFromRotate(source, degree)
	self:rotate(degree):blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixel, intensity)
end

--[[
explicit unset

will free resources immediately
this is also called upon garbage collection
--]]
function BB_mt.__index:free()
	if self.allocated ~= 0 then
		self.allocated = 0
		ffi.C.free(self.data)
	end
end

--[[
memory management
--]]
BB_mt.__gc = BB_mt.__index.free


--[[
PAINTING
--]]

--[[
invert a rectangle within the buffer

@param x X coordinate
@param y Y coordinate
@param w width
@param h height
--]]
function BB_mt.__index:invertRect(x, y, w, h)
	self:blitFrom(self, x, y, x, y, w, h, self.setPixelInverted)
end

--[[
paint a rectangle onto this buffer

@param x1 X coordinate
@param y1 Y coordinate
@param w width
@param h height
@param value color value
--]]
function BB_mt.__index:paintRect(x1, y1, w, h, value)
	-- compatibility:
	if type(value) == "number" then value = Color4L(value) end
	if w <= 0 or h <= 0 then return end
	w, x1 = checkBounds(w, x1, 0, self.w, 0xFFFF)
	h, y1 = checkBounds(h, y1, 0, self.h, 0xFFFF)
	for y = y1, y1+h-1 do
		for x = x1, x1+w-1 do
			self:setPixel(x, y, value)
		end
	end
end
BB4_mt.__index.paintRect = BB_mt.__index.paintRect

--[[
paint a circle onto this buffer

@param x1 X coordinate of the circle's center
@param y1 Y coordinate of the circle's center
@param r radius
@param c color value (defaults to black)
@param w width of line (defaults to radius)
--]]
function BB_mt.__index:paintCircle(center_x, center_y, r, c, w)
	-- compatibility:
	if type(c) == "number" then c = Color4L(c) end
	if r == 0 then return end
	if w == nil then w = r end
	if w > r then w = r end

	-- for outer circle
	local x = 0
	local y = r
	local delta = 5/4 - r

	-- for inner circle
	local r2 = r - w
	local x2 = 0
	local y2 = r2
	local delta2 = 5/4 - r

	-- draw two axles
	for tmp_y = r, r2+1, -1 do
		self:setPixelClamped(center_x+0, center_y+tmp_y, c)
		self:setPixelClamped(center_x-0, center_y-tmp_y, c)
		self:setPixelClamped(center_x+tmp_y, center_y+0, c)
		self:setPixelClamped(center_x-tmp_y, center_y-0, c)
	end

	while x < y do
		-- decrease y if we are out of circle
		x = x + 1;
		if delta > 0 then
			y = y - 1
			delta = delta + 2*x - 2*y + 2
		else
			delta = delta + 2*x + 1
		end

		-- inner circle finished drawing, increase y linearly for filling
		if x2 > y2 then
			y2 = y2 + 1
			x2 = x2 + 1
		else
			x2 = x2 + 1
			if delta2 > 0 then
				y2 = y2 - 1
				delta2 = delta2 + 2*x2 - 2*y2 + 2
			else
				delta2 = delta2 + 2*x2 + 1
			end
		end

		for tmp_y = y, y2+1, -1 do
			self:setPixelClamped(center_x+x, center_y+tmp_y, c)
			self:setPixelClamped(center_x+tmp_y, center_y+x, c)

			self:setPixelClamped(center_x+tmp_y, center_y-x, c)
			self:setPixelClamped(center_x+x, center_y-tmp_y, c)

			self:setPixelClamped(center_x-x, center_y-tmp_y, c)
			self:setPixelClamped(center_x-tmp_y, center_y-x, c)

			self:setPixelClamped(center_x-tmp_y, center_y+x, c)
			self:setPixelClamped(center_x-x, center_y+tmp_y, c)
		end
	end
	if r == w then
		self:setPixelClamped(center_x, center_y, c)
	end
end

function BB_mt.__index:paintRoundedCorner(off_x, off_y, w, h, bw, r, c)
	-- compatibility:
	if type(c) == "number" then c = Color4L(c) end
	if 2*r > h
	or 2*r > w
	or r == 0
	then
		-- no operation
		return
	end

	r = math.min(r, h, w)
	if bw > r then
		bw = r
	end

	-- for outer circle
	local x = 0
	local y = r
	local delta = 5/4 - r

	-- for inner circle
	local r2 = r - bw
	local x2 = 0
	local y2 = r2
	local delta2 = 5/4 - r

	while x < y do
		-- decrease y if we are out of circle
		x = x + 1
		if delta > 0 then
			y = y - 1
			delta = delta + 2*x - 2*y + 2
		else
			delta = delta + 2*x + 1
		end

		-- inner circle finished drawing, increase y linearly for filling
		if x2 > y2 then
			y2 = y2 + 1
			x2 = x2 + 1
		else
			x2 = x2 + 1
			if delta2 > 0 then
				y2 = y2 - 1
				delta2 = delta2 + 2*x2 - 2*y2 + 2
			else
				delta2 = delta2 + 2*x2 + 1
			end
		end

		for tmp_y = y, y2+1, -1 do
			self:setPixelClamped((w-r)+off_x+x-1, (h-r)+off_y+tmp_y-1, c)
			self:setPixelClamped((w-r)+off_x+tmp_y-1, (h-r)+off_y+x-1, c)

			self:setPixelClamped((w-r)+off_x+tmp_y-1, (r)+off_y-x, c)
			self:setPixelClamped((w-r)+off_x+x-1, (r)+off_y-tmp_y, c)

			self:setPixelClamped((r)+off_x-x, (r)+off_y-tmp_y, c)
			self:setPixelClamped((r)+off_x-tmp_y, (r)+off_y-x, c)

			self:setPixelClamped((r)+off_x-tmp_y, (h-r)+off_y+x-1, c)
			self:setPixelClamped((r)+off_x-x, (h-r)+off_y+tmp_y-1, c)
		end
	end
end

--[[
Draw a border

@x:  start position in x axis
@y:  start position in y axis
@w:  width of the border
@h:  height of the border
@bw: line width of the border
@c:  color for loading bar
@r:  radius of for border's corner (nil or 0 means right corner border)
--]]
function BB_mt.__index:paintBorder(x, y, w, h, bw, c, r)
	x, y = math.ceil(x), math.ceil(y)
	h, w = math.ceil(h), math.ceil(w)
	if not r or r == 0 then
		self:paintRect(x, y, w, bw, c)
		self:paintRect(x, y+h-bw, w, bw, c)
		self:paintRect(x, y+bw, bw, h - 2*bw, c)
		self:paintRect(x+w-bw, y+bw, bw, h - 2*bw, c)
	else
		if h < 2*r then r = math.floor(h/2) end
		if w < 2*r then r = math.floor(w/2) end
		self:paintRoundedCorner(x, y, w, h, bw, r, c)
		self:paintRect(r+x, y, w-2*r, bw, c)
		self:paintRect(r+x, y+h-bw, w-2*r, bw, c)
		self:paintRect(x, r+y, bw, h-2*r, c)
		self:paintRect(x+w-bw, r+y, bw, h-2*r, c)
	end
end


--[[
Fill a rounded corner rectangular area

@x:  start position in x axis
@y:  start position in y axis
@w:  width of the area
@h:  height of the area
@c:  color used to fill the area
@r:  radius of for four corners
--]]
function BB_mt.__index:paintRoundedRect(x, y, w, h, c, r)
	x, y = math.ceil(x), math.ceil(y)
	h, w = math.ceil(h), math.ceil(w)
	if not r or r == 0 then
		self:paintRect(x, y, w, h, c)
	else
		if h < 2*r then r = math.floor(h/2) end
		if w < 2*r then r = math.floor(w/2) end
		self:paintBorder(x, y, w, h, r, c, r)
		self:paintRect(x+r, y+r, w-2*r, h-2*r, c)
	end
end


--[[
Draw a progress bar according to following args:

@x:  start position in x axis
@y:  start position in y axis
@w:  width for progress bar
@h:  height for progress bar
@load_m_w: width margin for loading bar
@load_m_h: height margin for loading bar
@load_percent: progress in percent
@c:  color for loading bar
--]]
function BB_mt.__index:progressBar(x, y, w, h, load_m_w, load_m_h, load_percent, c)
	if load_m_h*2 > h then
		load_m_h = h/2
	end
	self:paintBorder(x, y, w, h, 2, 15)
	self:paintRect(x+load_m_w, y+load_m_h,
				(w-2*load_m_w)*load_percent, (h-2*load_m_h), c)
end


--[[
dim color values in rectangular area

@param x X coordinate
@param y Y coordinate
@param w width
@param h height
--]]
function BB_mt.__index:dimRect(x, y, w, h)
	self:blitFrom(self, x, y, x, y, w, h, self.setPixelDim)
end

--[[
lighten color values in rectangular area

@param x X coordinate
@param y Y coordinate
@param w width
@param h height
--]]
function BB_mt.__index:lightenRect(x, y, w, h, low)
	self:blitFrom(self, x, y, x, y, w, h, self.setPixelLighten, low)
end

function BB_mt.__index:copy()
	local mytype = ffi.typeof(self)
	local buffer = ffi.C.malloc(self.pitch * self.h)
	assert(buffer, "cannot allocate buffer")
	ffi.copy(buffer, self.data, self.pitch * self.h)
	return mytype(self.w, self.h, self.pitch, buffer, 1)
end

-- if no special case in BB???_mt exists, use function from BB_mt
-- (we do not use BB_mt as metatable for BB???_mt since this causes
--  a major slowdown and would not get properly JIT-compiled)
for name, func in pairs(BB_mt.__index) do
	if not BB4_mt.__index[name] then BB4_mt.__index[name] = func end
	if not BB8_mt.__index[name] then BB8_mt.__index[name] = func end
	if not BBA8_mt.__index[name] then BBA8_mt.__index[name] = func end
	if not BB16_mt.__index[name] then BB16_mt.__index[name] = func end
	if not BBRGB24_mt.__index[name] then BBRGB24_mt.__index[name] = func end
	if not BBRGB32_mt.__index[name] then BBRGB32_mt.__index[name] = func end
	if not BB_rotated_mt.__index[name] then BB_rotated_mt.__index[name] = func end
	if not BB_inverted_mt.__index[name] then BB_inverted_mt.__index[name] = func end
	if not BB_masked_mt.__index[name] then BB_masked_mt.__index[name] = func end
end

-- set metatables for the BlitBuffer types
local BlitBuffer4 = ffi.metatype("BlitBuffer4", BB4_mt)
local BlitBuffer8 = ffi.metatype("BlitBuffer8", BB8_mt)
local BlitBufferA8 = ffi.metatype("BlitBufferA8", BBA8_mt)
local BlitBuffer16 = ffi.metatype("BlitBuffer16", BB16_mt)
local BlitBufferRGB24 = ffi.metatype("BlitBufferRGB24", BBRGB24_mt)
local BlitBufferRGB32 = ffi.metatype("BlitBufferRGB32", BBRGB32_mt)

-- set metatables for the Color types
ffi.metatype("Color4L", Color4L_mt)
ffi.metatype("Color4U", Color4U_mt)
ffi.metatype("Color8", Color8_mt)
ffi.metatype("ColorA8", ColorA8_mt)
ffi.metatype("Color16", Color16_mt)
ffi.metatype("ColorRGB24", ColorRGB24_mt)
ffi.metatype("ColorRGB32", ColorRGB32_mt)

-- combined function for Blitbuffer creation
function BB.new(width, height, pitch, buffer, bpp, is_rgb)
	-- defaults:
	bpp = bpp or 4
	is_rgb = is_rgb or false

	local allocated = 0
	if buffer == nil then
		if pitch == nil then
			local bits = width * bpp
			pitch = bit.rshift(bits, 3)
			if bits % 8 > 0 then pitch = pitch + 1 end
		end
		buffer = ffi.C.malloc(pitch * height)
		assert(buffer, "cannot allocate buffer")
		ffi.fill(buffer, pitch * height)
		allocated = 1
	end
	if bpp == 4 and is_rgb == false then
		return BlitBuffer4(width, height, pitch, buffer, allocated)
	elseif bpp == 8 and is_rgb == false then
		return BlitBuffer8(width, height, pitch, buffer, allocated)
	elseif bpp == 16 and is_rgb == false then
		return BlitBuffer16(width, height, pitch, buffer, allocated)
	elseif bpp == 24 and is_rgb == true then
		return BlitBufferRGB24(width, height, pitch, buffer, allocated)
	elseif bpp == 32 and is_rgb == true then
		return BlitBufferRGB32(width, height, pitch, buffer, allocated)
	else
		error("unsupported format")
	end
end

function BB.compat(oldbuffer)
	return ffi.cast("BlitBuffer4*", oldbuffer)[0]
end

-- accessors for color types:
BB.Color4 = Color4L
BB.Color4L = Color4L
BB.Color4U = Color4U
BB.Color8 = Color8
BB.Color16 = Color16
BB.ColorRGB24 = ColorRGB24
BB.ColorRGB32 = ColorRGB32

-- accessors for Blitbuffer types
BB.BlitBuffer4 = BlitBuffer4
BB.BlitBuffer8 = BlitBuffer8
BB.BlitBufferA8 = BlitBufferA8
BB.BlitBuffer16 = BlitBuffer16
BB.BlitBufferRGB24 = BlitBufferRGB24
BB.BlitBufferRGB32 = BlitBufferRGB32


-- tests:
-- (run as "luajit -e 'require("blitbuffer").test()'"

function BB.test()
	local function print_bits(value)
		local function print_iter(value)
			if value > 0 then
				print_iter(rshift(value, 1))
				if band(value, 1) == 1 then io.stdout:write("1") else io.stdout:write("0") end
			else
				io.stdout:write("0b0")
			end
		end
		print_iter(value)
		io.stdout:write("\n")
	end

	local cRGB32 = ColorRGB32(0xFF, 0xAA, 0x55, 0)
	local cRGB24 = ColorRGB24(0xFF, 0xAA, 0x55)

	local cRGB24_32 = cRGB32:getColorRGB24()
	local c16_32 = cRGB32:getColor16()
	local c8_32 = cRGB32:getColor8()
	local c4l_32 = cRGB32:getColor4L()
	local c4u_32 = cRGB32:getColor4U()

	assert(c16_32.a == 0xAAAA, "conversion failure RGB32 -> gray16")
	assert(c8_32.a == 0xAA, "conversion failure RGB32 -> gray8")
	assert(c4l_32.a == 0x0A, "conversion failure RGB32 -> gray4 (lower nibble)")
	assert(c4u_32.a == 0xA0, "conversion failure RGB32 -> gray4 (upper nibble)")

	-- more tests to be done

	print("test: OK!")
end

return BB
