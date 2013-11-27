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
local uint8pt = ffi.typeof("uint8_t*")
local posix = require("ffi/posix_h")

-- the following definitions are redundant.
-- they need to be since only this way we can set
-- different metatables for them.
ffi.cdef[[
typedef struct Color4L {
	uint8_t a;
} Color4L;
typedef struct Color4U {
	uint8_t a;
} Color4U;
typedef struct Color8 {
	uint8_t a;
} Color8;
typedef struct Color8A {
	uint8_t a;
	uint8_t dummy; // only support pre-multiplied for now
} Color8A;
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

typedef struct BlitBuffer4 {
        int w; 
        int h; 
        int pitch;
        uint8_t *data;
        uint8_t config;
} BlitBuffer4;
typedef struct BlitBuffer8 {
        int w; 
        int h; 
        int pitch;
        Color8 *data;
        uint8_t config;
} BlitBuffer8;
typedef struct BlitBuffer8A {
        int w; 
        int h; 
        int pitch;
        Color8A *data;
        uint8_t config;
} BlitBuffer8A;
typedef struct BlitBuffer16 {
        int w; 
        int h; 
        int pitch;
        Color16 *data;
        uint8_t config;
} BlitBuffer16;
typedef struct BlitBufferRGB24 {
        int w; 
        int h; 
        int pitch;
        ColorRGB24 *data;
        uint8_t config;
} BlitBufferRGB24;
typedef struct BlitBufferRGB32 {
        int w; 
        int h; 
        int pitch;
        ColorRGB32 *data;
        uint8_t config;
} BlitBufferRGB32;

void *malloc(int size);
void free(void *ptr);
void *memset(void *s, int c, int n);
]]

-- color value types
local Color4U = ffi.typeof("Color4U")
local Color4L = ffi.typeof("Color4L")
local Color8 = ffi.typeof("Color8")
local Color8A = ffi.typeof("Color8A")
local Color16 = ffi.typeof("Color16")
local ColorRGB24 = ffi.typeof("ColorRGB24")
local ColorRGB32 = ffi.typeof("ColorRGB32")

-- metatables for color pointers
local P_Color4U_mt = {__index={}}

function P_Color4U_mt.__index:set(color)
end

-- color value pointer types
local P_Color4U = ffi.typeof("Color4U*")
local P_Color4L = ffi.typeof("Color4L*")
local P_Color8 = ffi.typeof("Color8*")
local P_Color8A = ffi.typeof("Color8A*")
local P_Color16 = ffi.typeof("Color16*")
local P_ColorRGB24 = ffi.typeof("ColorRGB24*")
local P_ColorRGB32 = ffi.typeof("ColorRGB32*")

-- metatables for color types:
local Color4L_mt = {__index={}}
local Color4U_mt = {__index={}}
local Color8_mt = {__index={}}
local Color8A_mt = {__index={}}
local Color16_mt = {__index={}}
local ColorRGB24_mt = {__index={}}
local ColorRGB32_mt = {__index={}}

-- color setting
function Color4L_mt.__index:set(color)
	self.a = bor(band(0xF0, self.a), color:getColor4L().a)
end
function Color4U_mt.__index:set(color)
	self.a = bor(band(0x0F, self.a), color:getColor4U().a)
end
function Color8_mt.__index:set(color) self.a = color:getColor8().a end
function Color8A_mt.__index:set(color) self.a = color:getColor8A().a end
function Color16_mt.__index:set(color) self.a = color:getColor16().a end
function ColorRGB24_mt.__index:set(color)
	local c = color:getColorRGB24()
	self.r = c.r
	self.g = c.g
	self.b = c.b
end
function ColorRGB32_mt.__index:set(color)
	local c = color:getColorRGB32()
	self.r = c.r
	self.g = c.g
	self.b = c.b
end
-- adding two colors:
function Color4L_mt.__index:add(color, intensity)
	local value = tonumber(self.a) * (1-intensity) + tonumber(color:getColor4L().a) * intensity
	if value > 0x0F then value = 0x0F end
	self:set(Color4L(value))
end
function Color4U_mt.__index:add(color, intensity)
	local orig = band(self.a, 0xF0)
	local value = tonumber(orig) * (1-intensity) + tonumber(color:getColor4U().a) * intensity
	if value > 0xF0 then value = 0xF0 end
	self:set(Color4U(band(0xF0, value)))
end
function Color8_mt.__index:add(color, intensity)
	local value = tonumber(self.a) * (1-intensity) + tonumber(color:getColor8().a) * intensity
	if value > 0xFF then value = 0xFF end
	self:set(Color8(value))
end
Color8A_mt.__index.add = Color8_mt.__index.add
function Color16_mt.__index:add(color, intensity)
	local value = tonumber(self.a) * (1-intensity) + tonumber(color:getColor16().a) * intensity
	if value > 0xFFFF then value = 0xFFFF end
	self:set(Color16(value))
end
function ColorRGB24_mt.__index:add(color, intensity)
	local r = tonumber(self:getR()) * (1-intensity) + tonumber(color:getR()) * intensity
	if r > 255 then r = 255 end
	local g = tonumber(self:getG()) * (1-intensity) + tonumber(color:getG()) * intensity
	if g > 255 then g = 255 end
	local b = tonumber(self:getB()) * (1-intensity) + tonumber(color:getB()) * intensity
	if b > 255 then b = 255 end
	self:set(ColorRGB24(r, g, b))
end
ColorRGB32_mt.__index.add = ColorRGB24_mt.__index.add

-- dimming
function Color4L_mt.__index:dim()
	return Color8(rshift(self:getColor8().a, 1))
end
Color4U_mt.__index.dim = Color4L_mt.__index.dim
Color8_mt.__index.dim = Color4L_mt.__index.dim
Color8A_mt.__index.dim = Color4L_mt.__index.dim
Color16_mt.__index.dim = Color4L_mt.__index.dim
ColorRGB24_mt.__index.dim = Color4L_mt.__index.dim
ColorRGB32_mt.__index.dim = Color4L_mt.__index.dim
-- lighten up
function Color4L_mt.__index:lighten(low)
	local value = self:getColor4L().a
	low = low * 0x0F
	if value < low then
		return Color4L(low)
	else
		return self
	end
end
Color4U_mt.__index.lighten = Color4L_mt.__index.lighten
Color8_mt.__index.lighten = Color4L_mt.__index.lighten
Color8A_mt.__index.lighten = Color4L_mt.__index.lighten
Color16_mt.__index.lighten = Color4L_mt.__index.lighten
ColorRGB24_mt.__index.lighten = Color4L_mt.__index.lighten
ColorRGB32_mt.__index.lighten = Color4L_mt.__index.lighten

-- color conversions:
-- to Color4L:
function Color4L_mt.__index:getColor4L() return Color4L(band(0x0F, self.a)) end
function Color4U_mt.__index:getColor4L() return Color4L(rshift(self.a, 4)) end
function Color8_mt.__index:getColor4L() return Color4L(rshift(self.a, 4)) end
function Color8A_mt.__index:getColor4L() return Color4L(rshift(self.a, 4)) end
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
function Color4U_mt.__index:getColor4U() return Color4U(band(0xF0, self.a)) end
function Color8_mt.__index:getColor4U() return Color4U(band(0xF0, self.a)) end
function Color8A_mt.__index:getColor4U() return Color4U(band(0xF0, self.a)) end
function Color16_mt.__index:getColor4U() return Color4U(band(0xF0, rshift(self.a,8))) end
function ColorRGB24_mt.__index:getColor4U()
	return Color4U(band(0xF0, rshift(4897*self.r + 9617*self.g + 1868*self.b, 14)))
end
ColorRGB32_mt.__index.getColor4U = ColorRGB24_mt.__index.getColor4U

-- to Color8:
function Color4L_mt.__index:getColor8()
	local v = band(0x0F, self.a)
	return Color8(v*0x11)
end
function Color4U_mt.__index:getColor8()
	local v = band(0xF0, self.a)
	return Color8(bor(rshift(v, 4), v))
end
function Color8_mt.__index:getColor8() return self end
function Color8A_mt.__index:getColor8() return Color8(self.a) end
function Color16_mt.__index:getColor8() return Color8(self.a) end
function ColorRGB24_mt.__index:getColor8()
	return Color8(rshift(4897*self:getR() + 9617*self:getG() + 1868*self:getB(), 14))
end
ColorRGB32_mt.__index.getColor8 = ColorRGB24_mt.__index.getColor8

-- to Color8A:
function Color4L_mt.__index:getColor8A()
	local v = band(0x0F, self.a)
	return Color8A(v*0x11)
end
function Color4U_mt.__index:getColor8A()
	local v = band(0xF0, self.a)
	return Color8A(bor(rshift(v, 4), v))
end
function Color8_mt.__index:getColor8A() return Color8A(self.a) end
function Color8A_mt.__index:getColor8A() return self end
function Color16_mt.__index:getColor8A() return Color8A(self.a) end
function ColorRGB24_mt.__index:getColor8A()
	return Color8A(rshift(4897*self:getR() + 9617*self:getG() + 1868*self:getB(), 14))
end
ColorRGB32_mt.__index.getColor8A = ColorRGB24_mt.__index.getColor8A

-- to Color16:
function Color4L_mt.__index:getColor16()
	local v = self:getColor8().a
	return Color16(bor(v, lshift(v, 8)))
end
Color4U_mt.__index.getColor16 = Color4L_mt.__index.getColor16
Color8_mt.__index.getColor16 = Color4L_mt.__index.getColor16
Color8A_mt.__index.getColor16 = Color4L_mt.__index.getColor16
function Color16_mt.__index:getColor16() return self end
ColorRGB24_mt.__index.getColor16 = Color4L_mt.__index.getColor16
ColorRGB32_mt.__index.getColor16 = Color4L_mt.__index.getColor16

-- to ColorRGB24:
function Color4L_mt.__index:getColorRGB24()
	local v = self:getColor8()
	return ColorRGB24(v.a, v.a, v.a)
end
Color4U_mt.__index.getColorRGB24 = Color4L_mt.__index.getColorRGB24
Color8_mt.__index.getColorRGB24 = Color4L_mt.__index.getColorRGB24
Color8A_mt.__index.getColorRGB24 = Color4L_mt.__index.getColorRGB24
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
Color8A_mt.__index.getColorRGB32 = Color4L_mt.__index.getColorRGB32
Color16_mt.__index.getColorRGB32 = Color4L_mt.__index.getColorRGB32
function ColorRGB24_mt.__index:getColorRGB32() return ColorRGB32(self.r, self.g, self.b) end
function ColorRGB32_mt.__index:getColorRGB32() return self end

-- RGB getters (special case for 4bpp mode)
function Color4L_mt.__index:getR() return self:getColor8().a end
Color4L_mt.__index.getG = Color4L_mt.__index.getR
Color4L_mt.__index.getB = Color4L_mt.__index.getR
Color4U_mt.__index.getR = Color4L_mt.__index.getR
Color4U_mt.__index.getG = Color4L_mt.__index.getR
Color4U_mt.__index.getB = Color4L_mt.__index.getR
Color8_mt.__index.getR = Color4L_mt.__index.getR
Color8_mt.__index.getG = Color4L_mt.__index.getR
Color8_mt.__index.getB = Color4L_mt.__index.getR
Color8A_mt.__index.getR = Color4L_mt.__index.getR
Color8A_mt.__index.getG = Color4L_mt.__index.getR
Color8A_mt.__index.getB = Color4L_mt.__index.getR
Color16_mt.__index.getR = Color4L_mt.__index.getR
Color16_mt.__index.getG = Color4L_mt.__index.getR
Color16_mt.__index.getB = Color4L_mt.__index.getR
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
function Color8A_mt.__index:invert() return Color8A(bxor(self.a, 0xFF)) end
function Color16_mt.__index:invert() return Color16(bxor(self.a, 0xFFFF)) end
function ColorRGB24_mt.__index:invert()
	return ColorRGB24(bxor(self.r, 0xFF), bxor(self.g, 0xFF), bxor(self.b, 0xFF))
end
function ColorRGB32_mt.__index:invert()
	return ColorRGB32(bxor(self.r, 0xFF), bxor(self.g, 0xFF), bxor(self.b, 0xFF))
end




local MASK_ALLOCATED = 0x01
local SHIFT_ALLOCATED = 0
local MASK_INVERSE = 0x02
local SHIFT_INVERSE = 1
local MASK_ROTATED = 0x0C
local SHIFT_ROTATED = 2
local MASK_TYPE = 0xF0
local SHIFT_TYPE = 4

local TYPE_BB4 = 0
local TYPE_BB8 = 1
local TYPE_BB8A = 2
local TYPE_BB16 = 3
local TYPE_BBRGB24 = 4
local TYPE_BBRGB32 = 5

local BB = {}

-- metatables for BlitBuffer objects:
local BB4_mt = {__index={}}
local BB8_mt = {__index={}}
local BB8A_mt = {__index={}}
local BB16_mt = {__index={}}
local BBRGB24_mt = {__index={}}
local BBRGB32_mt = {__index={}}

-- this is like a metatable for the others,
-- but we don't make it a metatable because LuaJIT
-- doesn't cope well with ctype metatables with
-- metatables on them
-- we just replicate what's in the following table
-- when we set the other metatables for their types
local BB_mt = {__index={}}

function BB_mt.__index:getRotation()
	return rshift(band(MASK_ROTATED, self.config), SHIFT_ROTATED)
end
function BB_mt.__index:setRotation(rotation_mode)
	self.config = bor(band(self.config, bxor(MASK_ROTATED, 0xFF)), lshift(rotation_mode, SHIFT_ROTATED))
end
function BB_mt.__index:rotateAbsolute(degree)
	local mode = (degree % 360) / 90
	self:setRotation(mode)
	return self
end
function BB_mt.__index:rotate(degree)
	degree = degree + self:getRotation()*90
	return self:rotateAbsolute(degree)
end
function BB_mt.__index:getInverse()
	return rshift(band(MASK_INVERSE, self.config), SHIFT_INVERSE)
end
function BB_mt.__index:setInverse(inverse)
	self.config = bor(band(self.config, bxor(MASK_INVERSE, 0xFF)), lshift(inverse, SHIFT_INVERSE))
end
function BB_mt.__index:invert()
	self:setInverse((self:getInverse() + 1) % 2)
	return self
end
function BB_mt.__index:getAllocated()
	return rshift(band(MASK_ALLOCATED, self.config), SHIFT_ALLOCATED)
end
function BB_mt.__index:setAllocated(allocated)
	self.config = bor(band(self.config, bxor(MASK_ALLOCATED, 0xFF)), lshift(allocated, SHIFT_ALLOCATED))
end
function BB_mt.__index:getType()
	return rshift(band(MASK_TYPE, self.config), SHIFT_TYPE)
end
function BB4_mt.__index:getBpp() return 4 end
function BB8_mt.__index:getBpp() return 8 end
function BB8A_mt.__index:getBpp() return 8 end
function BB16_mt.__index:getBpp() return 16 end
function BBRGB24_mt.__index:getBpp() return 24 end
function BBRGB32_mt.__index:getBpp() return 32 end
function BB_mt.__index:isRGB()
	local bb_type = self:getType()
	if bb_type == TYPE_BBRGB24 then
		return true
	elseif bb_type == TYPE_BBRGB32 then
		return true
	end
	return false
end
function BB_mt.__index:setType(type_id)
	self.config = bor(band(self.config, bxor(MASK_TYPE, 0xFF)), lshift(type_id, SHIFT_TYPE))
end
function BB_mt.__index:getPhysicalCoordinates(x, y)
	local rotation = self:getRotation()
	if rotation == 0 then
		return x, y
	elseif rotation == 1 then
		return self.w - y, x
	elseif rotation == 2 then
		return self.w - x, self.h - y
	elseif rotation == 3 then
		return y, self.h - x
	end
end
function BB_mt.__index:getPhysicalRect(x, y, w, h)
	local px1, py1 = self:getPhysicalCoordinates(x, y)
	local px2, py2 = self:getPhysicalCoordinates(x+w, y+h)
	local rotation = self:getRotation()
	if rotation == 1 or rotation == 3 then
		w, h = h, w
	end
	return math.min(px1, px2), math.min(py1, py2), w, h
end

-- physical coordinate checking
function BB_mt.__index:checkCoordinates(x, y)
	assert(x >= 0, "x coordinate >= 0")
	assert(y >= 0, "y coordinate >= 0")
	assert(x < self.w, "x coordinate < width")
	assert(y < self.h, "y coordinate < height")
end

-- getPixelP (pointer) routines, working on physical coordinates
function BB_mt.__index:getPixelP(x, y)
	--self:checkCoordinates(x, y)
	return ffi.cast(self.data, ffi.cast(uint8pt, self.data) + self.pitch*y) + x
end
function BB4_mt.__index:getPixelP(x, y)
	--self:checkCoordinates(x, y)
	local p = self.data + self.pitch*y + rshift(x, 1)
	if band(x, 1) == 0 then 
		return ffi.cast(P_Color4U, p)
	else
		return ffi.cast(P_Color4L, p)
	end
end

function BB_mt.__index:getPixel(x, y)
	local px, py = self:getPhysicalCoordinates(x, y)
	local color = self:getPixelP(px, py)[0]
	if self:getInverse() == 1 then color = color:invert() end
	return color
end

-- blitbuffer specific color conversions
function BB4_mt.__index.getMyColor(color) return color:getColor4L() end
function BB8_mt.__index.getMyColor(color) return color:getColor8() end
function BB8A_mt.__index.getMyColor(color) return color:getColor8A() end
function BB16_mt.__index.getMyColor(color) return color:getColor16() end
function BBRGB24_mt.__index.getMyColor(color) return color:getColorRGB24() end
function BBRGB32_mt.__index.getMyColor(color) return color:getColorRGB32() end

-- set pixel values
function BB_mt.__index:setPixel(x, y, color)
	local px, py = self:getPhysicalCoordinates(x, y)
	if self:getInverse() == 1 then color = color:invert() end
	self:getPixelP(px, py)[0]:set(color)
end
function BB_mt.__index:setPixelAdd(x, y, color, intensity)
	local px, py = self:getPhysicalCoordinates(x, y)
	if self:getInverse() == 1 then color = color:invert() end
	self:getPixelP(px, py)[0]:add(color, intensity)
end
function BB_mt.__index:setPixelInverted(x, y, color)
	self:setPixel(x, y, color:invert())
end

-- checked Pixel setting:
function BB_mt.__index:setPixelClamped(x, y, color)
	if x >= 0 and x < self:getWidth() and y >= 0 and y < self:getHeight() then
		self:setPixel(x, y, color)
	end
end

-- functions for accessing dimensions
function BB_mt.__index:getWidth()
	if 0 == bit.band(1, self:getRotation()) then
		return self.w
	else
		return self.h
	end
end
function BB_mt.__index:getHeight()
	if 0 == bit.band(1, self:getRotation()) then
		return self.h
	else
		return self.w
	end
end

-- names of optimized blitting routines
BB_mt.__index.blitfunc = "blitDefault" -- not optimized
BB4_mt.__index.blitfunc = "blitTo4"
BB8_mt.__index.blitfunc = "blitTo8"
BB8A_mt.__index.blitfunc = "blitTo8A"
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
function BB.checkBounds(length, target_offset, source_offset, target_size, source_size)
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
BB_mt.__index.blitTo8A = BB_mt.__index.blitDefault
BB_mt.__index.blitTo16 = BB_mt.__index.blitDefault
BB_mt.__index.blitToRGB24 = BB_mt.__index.blitDefault
BB_mt.__index.blitToRGB32 = BB_mt.__index.blitDefault

function BB_mt.__index:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
	width, height = width or source:getWidth(), height or source:getHeight()
	width, dest_x, offs_x = BB.checkBounds(width, dest_x or 0, offs_x or 0, self:getWidth(), source:getWidth())
	height, dest_y, offs_y = BB.checkBounds(height, dest_y or 0, offs_y or 0, self:getHeight(), source:getHeight())
	if not setter then setter = self.setPixel end

	if width <= 0 or height <= 0 then return end
	return source[self.blitfunc](source, self, dest_x, dest_y, offs_x, offs_y, width, height, setter, set_param)
end
BB_mt.__index.blitFullFrom = BB_mt.__index.blitFrom

function BB_mt.__index:addblitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, intensity)
	self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixelAdd, intensity)
end

function BB_mt.__index:blitFromRotate(source, degree)
	self:rotate(degree)
	self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixel, intensity)
	self:rotate(-degree)
end

--[[
explicit unset

will free resources immediately
this is also called upon garbage collection
--]]
function BB_mt.__index:free()
	if band(lshift(1, SHIFT_ALLOCATED), self.config) ~= 0 then
		self.config = band(self.config, bxor(0xFF, lshift(1, SHIFT_ALLOCATED)))
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

@param x X coordinate
@param y Y coordinate
@param w width
@param h height
@param value color value
--]]
function BB_mt.__index:paintRect(x, y, w, h, value)
	-- compatibility:
	if type(value) == "number" then value = Color4L(value) end
	if w <= 0 or h <= 0 then return end
	w, x = BB.checkBounds(w, x, 0, self:getWidth(), 0xFFFF)
	h, y = BB.checkBounds(h, y, 0, self:getHeight(), 0xFFFF)
	for y = y, y+h-1 do
		for x = x, x+w-1 do
			self:setPixel(x, y, value)
		end
	end
end

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
	if w <= 0 or h <= 0 then return end
	w, x = BB.checkBounds(w, x, 0, self:getWidth(), 0xFFFF)
	h, y = BB.checkBounds(h, y, 0, self:getHeight(), 0xFFFF)
	for y = y, y+h-1 do
		for x = x, x+w-1 do
			self:setPixel(x, y, self:getPixel(x, y):dim())
		end
	end
end

--[[
lighten color values in rectangular area

@param x X coordinate
@param y Y coordinate
@param w width
@param h height
--]]
function BB_mt.__index:lightenRect(x, y, w, h, low)
	if w <= 0 or h <= 0 then return end
	w, x = BB.checkBounds(w, x, 0, self:getWidth(), 0xFFFF)
	h, y = BB.checkBounds(h, y, 0, self:getHeight(), 0xFFFF)
	x, y, w, h = self:getPhysicalRect(x, y, w, h)
	for y = y, y+h-1 do
		for x = x, x+w-1 do
			self:setPixel(x, y, self:getPixel(x, y):lighten(low))
		end
	end
end

function BB_mt.__index:copy()
	local mytype = ffi.typeof(self)
	local buffer = ffi.C.malloc(self.pitch * self.h)
	assert(buffer, "cannot allocate buffer")
	ffi.copy(buffer, self.data, self.pitch * self.h)
	local copy = mytype(self.w, self.h, self.pitch, buffer, self.config)
	copy:setAllocated(1)
	return copy
end

-- if no special case in BB???_mt exists, use function from BB_mt
-- (we do not use BB_mt as metatable for BB???_mt since this causes
--  a major slowdown and would not get properly JIT-compiled)
for name, func in pairs(BB_mt.__index) do
	if not BB4_mt.__index[name] then BB4_mt.__index[name] = func end
	if not BB8_mt.__index[name] then BB8_mt.__index[name] = func end
	if not BB8A_mt.__index[name] then BB8A_mt.__index[name] = func end
	if not BB16_mt.__index[name] then BB16_mt.__index[name] = func end
	if not BBRGB24_mt.__index[name] then BBRGB24_mt.__index[name] = func end
	if not BBRGB32_mt.__index[name] then BBRGB32_mt.__index[name] = func end
end

-- set metatables for the BlitBuffer types
local BlitBuffer4 = ffi.metatype("BlitBuffer4", BB4_mt)
local BlitBuffer8 = ffi.metatype("BlitBuffer8", BB8_mt)
local BlitBuffer8A = ffi.metatype("BlitBuffer8A", BB8A_mt)
local BlitBuffer16 = ffi.metatype("BlitBuffer16", BB16_mt)
local BlitBufferRGB24 = ffi.metatype("BlitBufferRGB24", BBRGB24_mt)
local BlitBufferRGB32 = ffi.metatype("BlitBufferRGB32", BBRGB32_mt)

-- set metatables for the Color types
ffi.metatype("Color4L", Color4L_mt)
ffi.metatype("Color4U", Color4U_mt)
ffi.metatype("Color8", Color8_mt)
ffi.metatype("Color8A", Color8A_mt)
ffi.metatype("Color16", Color16_mt)
ffi.metatype("ColorRGB24", ColorRGB24_mt)
ffi.metatype("ColorRGB32", ColorRGB32_mt)

function BB.new(width, height, buffertype, dataptr, pitch)
	local bb = nil
	buffertype = buffertype or TYPE_BB4
	if pitch == nil then
		if buffertype == TYPE_BB4 then pitch = band(1, width) + rshift(width, 1)
		elseif buffertype == TYPE_BB8 then pitch = width
		elseif buffertype == TYPE_BB8A then pitch = lshift(width, 1)
		elseif buffertype == TYPE_BB16 then pitch = lshift(width, 1)
		elseif buffertype == TYPE_BBRGB24 then pitch = width * 3
		elseif buffertype == TYPE_BBRGB32 then pitch = lshift(width, 2)
		end
	end
	if buffertype == TYPE_BB4 then bb = BlitBuffer4(width, height, pitch, nil, 0)
	elseif buffertype == TYPE_BB8 then bb = BlitBuffer8(width, height, pitch, nil, 0)
	elseif buffertype == TYPE_BB8A then bb = BlitBuffer8A(width, height, pitch, nil, 0)
	elseif buffertype == TYPE_BB16 then bb = BlitBuffer16(width, height, pitch, nil, 0)
	elseif buffertype == TYPE_BBRGB24 then bb = BlitBufferRGB24(width, height, pitch, nil, 0)
	elseif buffertype == TYPE_BBRGB32 then bb = BlitBufferRGB32(width, height, pitch, nil, 0)
	else error("unknown blitbuffer type")
	end
	bb:setType(buffertype)
	if dataptr == nil then
		dataptr = ffi.C.malloc(pitch * height)
		assert(dataptr, "cannot allocate memory for blitbuffer")
		ffi.fill(dataptr, pitch*height)
		bb:setAllocated(1)
	end
	bb.data = ffi.cast(bb.data, dataptr)
	return bb
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
BB.BlitBuffer8A = BlitBuffer8A
BB.BlitBuffer16 = BlitBuffer16
BB.BlitBufferRGB24 = BlitBufferRGB24
BB.BlitBufferRGB32 = BlitBufferRGB32
BB.TYPE_BB4 = TYPE_BB4
BB.TYPE_BB8 = TYPE_BB8
BB.TYPE_BB8A = TYPE_BB8A
BB.TYPE_BB16 = TYPE_BB16
BB.TYPE_BBRGB24 = TYPE_BBRGB24
BB.TYPE_BBRGB32 = TYPE_BBRGB32

return BB
