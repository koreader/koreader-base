--[[
Generic blitbuffer/GFX stuff that works on memory buffers
--]]

local ffi = require("ffi")
local util = require("ffi/util")

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
local debug = debug

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
    uint8_t alpha;
} Color8A;
typedef struct ColorRGB16 {
    uint16_t v;
} ColorRGB16;
typedef struct ColorRGB24 {
    uint8_t r;
    uint8_t g;
    uint8_t b;
} ColorRGB24;
typedef struct ColorRGB32 {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t alpha;
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
typedef struct BlitBufferRGB16 {
    int w;
    int h;
    int pitch;
    ColorRGB16 *data;
    uint8_t config;
} BlitBufferRGB16;
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
]]

-- color value types
local Color4U = ffi.typeof("Color4U")
local Color4L = ffi.typeof("Color4L")
local Color8 = ffi.typeof("Color8")
local Color8A = ffi.typeof("Color8A")
local ColorRGB16 = ffi.typeof("ColorRGB16")
local ColorRGB24 = ffi.typeof("ColorRGB24")
local ColorRGB32 = ffi.typeof("ColorRGB32")

-- color value pointer types
local P_Color4U = ffi.typeof("Color4U*")
local P_Color4L = ffi.typeof("Color4L*")
local P_Color8 = ffi.typeof("Color8*")
local P_Color8A = ffi.typeof("Color8A*")
local P_ColorRGB16 = ffi.typeof("ColorRGB16*")
local P_ColorRGB24 = ffi.typeof("ColorRGB24*")
local P_ColorRGB32 = ffi.typeof("ColorRGB32*")

-- metatables for color types:
local Color4L_mt = {__index={}}
local Color4U_mt = {__index={}}
local Color8_mt = {__index={}}
local Color8A_mt = {__index={}}
local ColorRGB16_mt = {__index={}}
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
function Color8A_mt.__index:set(color)
    local c = color:getColor8A()
    self.a = c.a
    self.alpha = c.alpha
end
function ColorRGB16_mt.__index:set(color) self.v = color:getColorRGB16().v end
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
    self.alpha = c.alpha
end

-- alpha blending (8bit alpha value):
local function div255(value)
    return rshift(value + intt(1) + rshift(value, 8), 8)
end
local function div4080(value)
    return rshift(value + intt(1) + rshift(value, 8), 12)
end
function Color4L_mt.__index:blend(color)
    local alpha = color:getAlpha()
    -- simplified: we expect a 8bit grayscale "color" as parameter
    local value = div4080(band(self.a, 0x0F) * intt(0x11) * (intt(0xFF) - alpha) + color:getR() * alpha)
    self:set(Color4L(value))
end
function Color4U_mt.__index:blend(color)
    local alpha = color:getAlpha()
    local orig = band(self.a, 0xF0)
    -- simplified: we expect a 8bit grayscale "color" as parameter
    local value = div255((orig + rshift(orig, 4)) * (intt(0xFF) - alpha) + color:getR() * alpha)
    self:set(Color4U(value))
end
function Color8_mt.__index:blend(color)
    local alpha = color:getAlpha()
    -- simplified: we expect a 8bit grayscale "color" as parameter
    local value = div255(self.a * (intt(0xFF) - alpha) + color:getR() * alpha)
    self:set(Color8(value))
end
function Color8A_mt.__index:blend(color)
    local alpha = color:getAlpha()
    -- simplified: we expect a 8bit grayscale "color" as parameter
    local value = div255(self.a * (intt(0xFF) - alpha) + color:getR() * alpha)
    self:set(Color8A(value, self:getAlpha()))
end
function ColorRGB16_mt.__index:blend(color)
    local alpha = color:getAlpha()
    local ainv = intt(0xFF) - alpha
    local r = div255(self:getR() * ainv + color:getR() * alpha)
    local g = div255(self:getG() * ainv + color:getG() * alpha)
    local b = div255(self:getB() * ainv + color:getB() * alpha)
    self:set(ColorRGB24(r, g, b))
end
ColorRGB24_mt.__index.blend = ColorRGB16_mt.__index.blend
function ColorRGB32_mt.__index:blend(color)
    local alpha = color:getAlpha()
    local ainv = intt(0xFF) - alpha
    local r = div255(self:getR() * ainv + color:getR() * alpha)
    local g = div255(self:getG() * ainv + color:getG() * alpha)
    local b = div255(self:getB() * ainv + color:getB() * alpha)
    self:set(ColorRGB32(r, g, b, self:getAlpha()))
end

-- color conversions:
-- to Color4L:
function Color4L_mt.__index:getColor4L() return Color4L(band(0x0F, self.a)) end
function Color4U_mt.__index:getColor4L() return Color4L(rshift(self.a, 4)) end
function Color8_mt.__index:getColor4L() return Color4L(rshift(self.a, 4)) end
function Color8A_mt.__index:getColor4L() return Color4L(rshift(self.a, 4)) end
--[[
Uses luminance match for approximating the human perception of colour, as per
http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale

L = 0.299*Red + 0.587*Green + 0.114*Blue
--]]
function ColorRGB16_mt.__index:getColor4L()
    local r = rshift(self.v, 11)
    local g = band(rshift(self.v, 5, 0x3F))
    local b = band(self.v, 0x001F)
    return Color4L(rshift(39190*r + 38469*g + 14942*b, 18))
end
function ColorRGB24_mt.__index:getColor4L()
    return Color4L(rshift(4897*self.r + 9617*self.g + 1868*self.b, 18))
end
ColorRGB32_mt.__index.getColor4L = ColorRGB24_mt.__index.getColor4L

-- to Color4U:
function Color4L_mt.__index:getColor4U() return Color4U(lshift(self.a, 4)) end
function Color4U_mt.__index:getColor4U() return Color4U(band(0xF0, self.a)) end
function Color8_mt.__index:getColor4U() return Color4U(band(0xF0, self.a)) end
function Color8A_mt.__index:getColor4U() return Color4U(band(0xF0, self.a)) end
function ColorRGB16_mt.__index:getColor4U()
    local r = rshift(self.v, 11)
    local g = band(rshift(self.v, 5, 0x3F))
    local b = band(self.v, 0x001F)
    return Color4U(band(0xF0, rshift(39190*r + 38469*g + 14942*b, 14)))
end
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
function ColorRGB16_mt.__index:getColor8()
    local r = rshift(self.v, 11)
    local g = band(rshift(self.v, 5), 0x3F)
    local b = band(self.v, 0x001F)
    return Color8(rshift(39190*r + 38469*g + 14942*b, 14))
end
function ColorRGB24_mt.__index:getColor8()
    return Color8(rshift(4897*self:getR() + 9617*self:getG() + 1868*self:getB(), 14))
end
ColorRGB32_mt.__index.getColor8 = ColorRGB24_mt.__index.getColor8

-- to Color8A:
function Color4L_mt.__index:getColor8A()
    local v = band(0x0F, self.a)
    return Color8A(v*0x11, 0)
end
function Color4U_mt.__index:getColor8A()
    local v = band(0xF0, self.a)
    return Color8A(bor(rshift(v, 4), v), 0)
end
function Color8_mt.__index:getColor8A() return Color8A(self.a, 0) end
function Color8A_mt.__index:getColor8A() return self end
function ColorRGB16_mt.__index:getColor8A()
    local r = rshift(self.v, 11)
    local g = band(rshift(self.v, 5), 0x3F)
    local b = band(self.v, 0x001F)
    return Color8A(rshift(39190*r + 38469*g + 14942*b, 14), 0)
end
function ColorRGB24_mt.__index:getColor8A()
    return Color8A(rshift(4897*self:getR() + 9617*self:getG() + 1868*self:getB(), 14), 0)
end
function ColorRGB32_mt.__index:getColor8A()
    return Color8A(rshift(4897*self:getR() + 9617*self:getG() + 1868*self:getB(), 14), self:getAlpha())
end

-- to ColorRGB16:
function Color4L_mt.__index:getColorRGB16()
    local v = self:getColor8().a
    local v5bit = rshift(v, 3)
    return ColorRGB16(lshift(v5bit, 11) + lshift(band(v, 0xFC), 3) + v5bit)
end
Color4U_mt.__index.getColorRGB16 = Color4L_mt.__index.getColorRGB16
Color8_mt.__index.getColorRGB16 = Color4L_mt.__index.getColorRGB16
Color8A_mt.__index.getColorRGB16 = Color4L_mt.__index.getColorRGB16
function ColorRGB16_mt.__index:getColorRGB16() return self end
function ColorRGB24_mt.__index:getColorRGB16()
    return ColorRGB16(lshift(band(self.r, 0xF8), 8) + lshift(band(self.g, 0xFC), 3)  + rshift(self.b, 3))
end
ColorRGB32_mt.__index.getColorRGB16 = ColorRGB24_mt.__index.getColorRGB16

-- to ColorRGB24:
function Color4L_mt.__index:getColorRGB24()
    local v = self:getColor8()
    return ColorRGB24(v.a, v.a, v.a)
end
Color4U_mt.__index.getColorRGB24 = Color4L_mt.__index.getColorRGB24
Color8_mt.__index.getColorRGB24 = Color4L_mt.__index.getColorRGB24
Color8A_mt.__index.getColorRGB24 = Color4L_mt.__index.getColorRGB24
function ColorRGB16_mt.__index:getColorRGB24()
    local r = rshift(self.v, 11)
    local g = band(rshift(self.v, 5), 0x3F)
    local b = band(self.v, 0x001F)
    return ColorRGB24(lshift(r, 3) + rshift(r, 2), lshift(g, 2) + rshift(g, 4), lshift(b, 3) + rshift(b, 2))
end
function ColorRGB24_mt.__index:getColorRGB24() return self end
function ColorRGB32_mt.__index:getColorRGB24() return ColorRGB24(self.r, self.g, self.b) end

-- to ColorRGB32:
function Color4L_mt.__index:getColorRGB32()
    local v = self:getColor8()
    return ColorRGB32(v.a, v.a, v.a, 0xFF)
end
Color4U_mt.__index.getColorRGB32 = Color4L_mt.__index.getColorRGB32
Color8_mt.__index.getColorRGB32 = Color4L_mt.__index.getColorRGB32
Color8A_mt.__index.getColorRGB32 = Color4L_mt.__index.getColorRGB32
function ColorRGB16_mt.__index:getColorRGB32()
    local r = rshift(self.v, 11)
    local g = band(rshift(self.v, 5), 0x3F)
    local b = band(self.v, 0x001F)
    return ColorRGB32(lshift(r, 3) + rshift(r, 2), lshift(g, 2) + rshift(g, 4), lshift(b, 3) + rshift(b, 2), 0xFF)
end
function ColorRGB24_mt.__index:getColorRGB32() return ColorRGB32(self.r, self.g, self.b, 0xFF) end
function ColorRGB32_mt.__index:getColorRGB32() return self end

-- RGB getters (special case for 4bpp mode)
function Color4L_mt.__index:getR() return self:getColor8().a end
Color4L_mt.__index.getG = Color4L_mt.__index.getR
Color4L_mt.__index.getB = Color4L_mt.__index.getR
function Color4L_mt.__index:getAlpha() return intt(0xFF) end
Color4U_mt.__index.getR = Color4L_mt.__index.getR
Color4U_mt.__index.getG = Color4L_mt.__index.getR
Color4U_mt.__index.getB = Color4L_mt.__index.getR
Color4U_mt.__index.getAlpha = Color4L_mt.__index.getAlpha
Color8_mt.__index.getR = Color4L_mt.__index.getR
Color8_mt.__index.getG = Color4L_mt.__index.getR
Color8_mt.__index.getB = Color4L_mt.__index.getR
Color8_mt.__index.getAlpha = Color4L_mt.__index.getAlpha
Color8A_mt.__index.getR = Color4L_mt.__index.getR
Color8A_mt.__index.getG = Color4L_mt.__index.getR
Color8A_mt.__index.getB = Color4L_mt.__index.getR
function Color8A_mt.__index:getAlpha() return self.alpha end
function ColorRGB16_mt.__index:getR()
    local r = rshift(self.v, 11)
    return lshift(r, 3) + rshift(r, 2)
end
function ColorRGB16_mt.__index:getG()
    local g = band(rshift(self.v, 5), 0x3F)
    return lshift(g, 2) + rshift(g, 4)
end
function ColorRGB16_mt.__index:getB()
    local b = band(self.v, 0x001F)
    return lshift(b, 3) + rshift(b, 2)
end
ColorRGB16_mt.__index.getAlpha = Color4L_mt.__index.getAlpha
function ColorRGB24_mt.__index:getR() return self.r end
function ColorRGB24_mt.__index:getG() return self.g end
function ColorRGB24_mt.__index:getB() return self.b end
ColorRGB24_mt.__index.getAlpha = Color4L_mt.__index.getAlpha
ColorRGB32_mt.__index.getR = ColorRGB24_mt.__index.getR
ColorRGB32_mt.__index.getG = ColorRGB24_mt.__index.getG
ColorRGB32_mt.__index.getB = ColorRGB24_mt.__index.getB
function ColorRGB32_mt.__index:getAlpha() return self.alpha end

-- modifications:
-- inversion:
function Color4L_mt.__index:invert() return Color4L(bxor(self.a, 0x0F)) end
function Color4U_mt.__index:invert() return Color4U(bxor(self.a, 0xF0)) end
function Color8_mt.__index:invert() return Color8(bxor(self.a, 0xFF)) end
function Color8A_mt.__index:invert() return Color8A(bxor(self.a, 0xFF), self.alpha) end
function ColorRGB16_mt.__index:invert() return ColorRGB16(bxor(self.v, 0xFFFF)) end
function ColorRGB24_mt.__index:invert()
    return ColorRGB24(bxor(self.r, 0xFF), bxor(self.g, 0xFF), bxor(self.b, 0xFF))
end
function ColorRGB32_mt.__index:invert()
    return ColorRGB32(bxor(self.r, 0xFF), bxor(self.g, 0xFF), bxor(self.b, 0xFF), self.alpha)
end

-- comparison:
function ColorRGB32_mt:__eq(c)
    c = c:getColorRGB32()
    return (self:getR() == c:getR())
    and (self:getG() == c:getG())
    and (self:getB() == c:getB())
    and (self:getAlpha() == c:getAlpha())
end
Color4L_mt.__eq = ColorRGB32_mt.__eq
Color4U_mt.__eq = ColorRGB32_mt.__eq
Color8_mt.__eq = ColorRGB32_mt.__eq
Color8A_mt.__eq = ColorRGB32_mt.__eq
ColorRGB16_mt.__eq = ColorRGB32_mt.__eq
ColorRGB24_mt.__eq = ColorRGB32_mt.__eq

-- pretty printing
function Color4L_mt:__tostring()
    return "Color4L("..band(self.a, 0x0F)..")"
end
function Color4U_mt:__tostring()
    return "Color4U("..rshift(band(self.a, 0xF0),4)..")"
end
function Color8_mt:__tostring()
    return "Color8("..self.a..")"
end
function Color8A_mt:__tostring()
    return "Color8A("..self.a ..", "..self.alpha..")"
end
function ColorRGB16_mt:__tostring()
    return "ColorRGB16("..self:getR()..", "..self:getG()..", "..self:getB()..")"
end
function ColorRGB24_mt:__tostring()
    return "ColorRGB24("..self:getR()..", "..self:getG()..", "..self:getB()..")"
end
function ColorRGB32_mt:__tostring()
    return "ColorRGB32("..self:getR()..", "..self:getG()..", "..self:getB()..", "..self:getAlpha()..")"
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
local TYPE_BBRGB16 = 3
local TYPE_BBRGB24 = 4
local TYPE_BBRGB32 = 5

local BB = {}

-- metatables for BlitBuffer objects:
local BB4_mt = {__index={}}
local BB8_mt = {__index={}}
local BB8A_mt = {__index={}}
local BBRGB16_mt = {__index={}}
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
function BBRGB16_mt.__index:getBpp() return 16 end
function BBRGB24_mt.__index:getBpp() return 24 end
function BBRGB32_mt.__index:getBpp() return 32 end
function BB_mt.__index:isRGB()
    local bb_type = self:getType()
    if bb_type == TYPE_BBRGB16
        or bb_type == TYPE_BBRGB24
        or bb_type == TYPE_BBRGB32 then
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
        return self.w - y - 1, x
    elseif rotation == 2 then
        return self.w - x - 1, self.h - y - 1
    elseif rotation == 3 then
        return y, self.h - x - 1
    end
end
function BB_mt.__index:getPhysicalRect(x, y, w, h)
    local px1, py1 = self:getPhysicalCoordinates(x, y)
    local px2, py2 = self:getPhysicalCoordinates(x+w-1, y+h-1)
    if self:getRotation() % 2 == 1 then w, h = h, w end
    return math.min(px1, px2), math.min(py1, py2), w, h
end

-- physical coordinate checking
function BB_mt.__index:checkCoordinates(x, y)
    assert(x >= 0, "x coordinate >= 0")
    assert(y >= 0, "y coordinate >= 0")
    assert(x < self:getWidth(), "x coordinate < width")
    assert(y < self:getHeight(), "y coordinate < height")
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
function BBRGB16_mt.__index.getMyColor(color) return color:getColorRGB16() end
function BBRGB24_mt.__index.getMyColor(color) return color:getColorRGB24() end
function BBRGB32_mt.__index.getMyColor(color) return color:getColorRGB32() end

-- set pixel values
function BB_mt.__index:setPixel(x, y, color)
    local px, py = self:getPhysicalCoordinates(x, y)
    if self:getInverse() == 1 then color = color:invert() end
    self:getPixelP(px, py)[0]:set(color)
end
function BB_mt.__index:setPixelAdd(x, y, color, alpha)
    -- fast path:
    if alpha == 0 then return
    elseif alpha == 0xFF then return self:setPixel(x, y, color)
    end
    -- this method works with a grayscale value
    local px, py = self:getPhysicalCoordinates(x, y)
    color = color:getColor8A()
    if self:getInverse() == 1 then color = color:invert() end
    color.alpha = alpha
    self:getPixelP(px, py)[0]:blend(color)
end
function BBRGB16_mt.__index:setPixelAdd(x, y, color, alpha)
    -- fast path:
    if alpha == 0 then return
    elseif alpha == 0xFF then return self:setPixel(x, y, color)
    end
    -- this method uses a RGB color value
    local px, py = self:getPhysicalCoordinates(x, y)
    if self:getInverse() == 1 then color = color:invert() end
    color = color:getColorRGB32()
    color.alpha = alpha
    self:getPixelP(px, py)[0]:blend(color)
end
BBRGB24_mt.__index.setPixelAdd = BBRGB16_mt.__index.setPixelAdd
BBRGB32_mt.__index.setPixelAdd = BBRGB16_mt.__index.setPixelAdd
function BB_mt.__index:setPixelBlend(x, y, color)
    local px, py = self:getPhysicalCoordinates(x, y)
    if self:getInverse() == 1 then color = color:invert() end
    self:getPixelP(px, py)[0]:blend(color)
end
function BB_mt.__index:setPixelColorize(x, y, mask, color)
    -- use 8bit grayscale pixel value as alpha for blitting
    local alpha = mask:getColor8().a
    -- fast path:
    if alpha == 0 then return end
    local px, py = self:getPhysicalCoordinates(x, y)
    if alpha == 0xFF then
        self:getPixelP(px, py)[0]:set(color)
    else
        color.alpha = alpha
        self:getPixelP(px, py)[0]:blend(color)
    end
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
BBRGB16_mt.__index.blitfunc = "blitToRGB16"
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
    local hook, mask, count = debug.gethook()
    debug.sethook()
    local o_y = offs_y
    for y = dest_y, dest_y+height-1 do
        local o_x = offs_x
        for x = dest_x, dest_x+width-1 do
            setter(dest, x, y, self:getPixel(o_x, o_y), set_param)
            o_x = o_x + 1
        end
        o_y = o_y + 1
    end
    debug.sethook(hook, mask)
end
-- no optimized blitting by default:
BB_mt.__index.blitTo4 = BB_mt.__index.blitDefault
BB_mt.__index.blitTo8 = BB_mt.__index.blitDefault
BB_mt.__index.blitTo8A = BB_mt.__index.blitDefault
BB_mt.__index.blitToRGB16 = BB_mt.__index.blitDefault
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

-- blitting with a per-blit alpha value
function BB_mt.__index:addblitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, intensity)
    self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixelAdd, intt(intensity*0xFF))
end

-- alpha-pane aware blitting
function BB_mt.__index:alphablitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height)
    self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixelBlend)
end

-- colorize area using source blitbuffer as a alpha-map
function BB_mt.__index:colorblitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, color)
    -- we need color with alpha later:
    color = color:getColorRGB32()
    if self:getInverse() == 1 then color = color:invert() end
    self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixelColorize, color)
end

function BB_mt.__index:blitFromRotate(source, degree)
    self:rotate(degree)
    self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, self.setPixel, intensity)
    self:rotate(-degree)
end

-- scale method does not modify the original blitbuffer, instead, it allocates
-- and returns a new scaled blitbuffer.
function BB_mt.__index:scale(new_width, new_height)
    local self_w, self_h = self:getWidth(), self:getHeight()
    local scaled_bb = BB.new(new_width, new_height, self:getType())
    -- uses very simple nearest neighbour scaling
    for y=0, new_height-1 do
        for x=0, new_width-1 do
            scaled_bb:setPixel(x, y,
            self:getPixel(util.idiv(x*self_w, new_width),
                          util.idiv(y*self_h, new_height)))
        end
    end
    return scaled_bb
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
fill the whole blitbuffer with a given color value
--]]
function BB_mt.__index:fill(value)
    local hook, mask, count = debug.gethook()
    debug.sethook()
    local w = self:getWidth()
    local h = self:getHeight()
    for y = 0, h-1 do
        for x = 0, w-1 do
            self:setPixel(x, y, value)
        end
    end
    debug.sethook(hook, mask)
end
function BB4_mt.__index:fill(value)
    local v = value:getColor4L().a
    v = bor(lshift(v, 4), v)
    ffi.fill(self.data, self.pitch*self.h, v)
end
function BB8_mt.__index:fill(value)
    ffi.fill(self.data, self.pitch*self.h, value:getColor8().a)
end

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
@param setter function used to set pixels (defaults to normal setPixel)
--]]
function BB_mt.__index:paintRect(x, y, w, h, value, setter)
    local hook, mask, count = debug.gethook()
    debug.sethook()
    setter = setter or self.setPixel
    value = value or Color8(0)
    if w <= 0 or h <= 0 then return end
    w, x = BB.checkBounds(w, x, 0, self:getWidth(), 0xFFFF)
    h, y = BB.checkBounds(h, y, 0, self:getHeight(), 0xFFFF)
    for y = y, y+h-1 do
        for x = x, x+w-1 do
            setter(self, x, y, value)
        end
    end
    debug.sethook(hook, mask)
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
    c = c or Color8(0)
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
    if 2*r > h or 2*r > w or r == 0 then
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
@param by dim by this factor (default: 0.5)
--]]
function BB_mt.__index:dimRect(x, y, w, h, by)
    return self:paintRect(x, y, w, h,
        Color8A(255, 255*(by or 0.5)),
        self.setPixelBlend)
end

--[[
lighten color values in rectangular area

@param x X coordinate
@param y Y coordinate
@param w width
@param h height
@param by lighten by this factor (default: 0.5)
--]]
function BB_mt.__index:lightenRect(x, y, w, h, by)
    return self:paintRect(x, y, w, h,
        Color8A(0, 255*(by or 0.5)),
        self.setPixelBlend)
end

--[[
make a full copy of the current buffer, with its own memory
--]]
function BB_mt.__index:copy()
    local mytype = ffi.typeof(self)
    local buffer = ffi.C.malloc(self.pitch * self.h)
    assert(buffer, "cannot allocate buffer")
    ffi.copy(buffer, self.data, self.pitch * self.h)
    local copy = mytype(self.w, self.h, self.pitch, buffer, self.config)
    copy:setAllocated(1)
    return copy
end

--[[
return a new Blitbuffer object that works on a rectangular
subset of the current Blitbuffer

Note that the caller has to make sure that the underlying memory
(of the Blitbuffer this method is called on) stays in place. In other
words, a viewport does not create a new buffer with memory.
--]]
function BB_mt.__index:viewport(x, y, w, h)
    x, y, w, h = self:getPhysicalRect(x, y, w, h)
    local viewport = BB.new(w, h, self:getType(), self:getPixelP(x, y), self.pitch)
    viewport:setRotation(self:getRotation())
    viewport:setInverse(self:getInverse())
    return viewport
end

--[[
write blitbuffer contents to a PAM file

see http://netpbm.sourceforge.net/doc/pam.html for PAM file specs.

@param filename the name of the file to be created
--]]
function BB_mt.__index:writePAM(filename)
    local hook, mask, count = debug.gethook()
    debug.sethook()
    local f = io.open(filename, "w")
    f:write("P7\n")
    f:write("# written by blitbuffer.lua\n")
    f:write("WIDTH ", self:getWidth(), "\n")
    f:write("HEIGHT ", self:getHeight(), "\n")
    local bb_type = self:getType()
    if bb_type == TYPE_BB4 then
        f:write("DEPTH 1\n", "MAXVAL 15\n", "TUPLTYPE GRAYSCALE\n")
    elseif bb_type == TYPE_BB8 then
        f:write("DEPTH 1\n", "MAXVAL 255\n", "TUPLTYPE GRAYSCALE\n")
    elseif bb_type == TYPE_BB8A then
        f:write("DEPTH 2\n", "MAXVAL 255\n", "TUPLTYPE GRAYSCALE_ALPHA\n")
    elseif bb_type == TYPE_BBRGB16 then
        -- this is not supported by PAM since the tuple consists of different bit widths
        -- so we convert to RGB24 in this case
        f:write("DEPTH 3\n", "MAXVAL 255\n", "TUPLTYPE RGB\n")
    elseif bb_type == TYPE_BBRGB24 then
        f:write("DEPTH 3\n", "MAXVAL 255\n", "TUPLTYPE RGB\n")
    elseif bb_type == TYPE_BBRGB32 then
        f:write("DEPTH 4\n", "MAXVAL 255\n", "TUPLTYPE RGB_ALPHA\n")
    end
    f:write("ENDHDR\n")
    for y = 0, self:getHeight()-1 do
        for x = 0, self:getWidth()-1 do
            local v = self:getPixel(x, y)
            if bb_type == TYPE_BB4 or bb_type == TYPE_BB8 then
                ffi.C.fputc(v.a, f)
            elseif bb_type == TYPE_BB8A then
                ffi.C.fputc(v.a, f)
                -- note that other functions do not support
                -- alpha values for now
                -- TODO: use correct alpha value of struct here
                ffi.C.fputc(255, f)
            elseif bb_type == TYPE_BBRGB16 then
                v = v:getColorRGB24()
                ffi.C.fputc(v.r, f)
                ffi.C.fputc(v.g, f)
                ffi.C.fputc(v.b, f)
            elseif bb_type == TYPE_BBRGB24 then
                ffi.C.fputc(v.r, f)
                ffi.C.fputc(v.g, f)
                ffi.C.fputc(v.b, f)
            elseif bb_type == TYPE_BBRGB32 then
                ffi.C.fputc(v.r, f)
                ffi.C.fputc(v.g, f)
                ffi.C.fputc(v.b, f)
                -- note that other functions do not support
                -- alpha values for now
                -- TODO: use correct alpha value of struct here
                ffi.C.fputc(255, f)
            end
        end
    end
    f:close()
    debug.sethook(hook, mask)
end

--[[
write blitbuffer contents to a PNG file

@param filename the name of the file to be created
--]]
local Png  -- lazy load ffi/png
function BB_mt.__index:writePNG(filename)
    if not Png then Png = require("ffi/png") end
    local hook, mask, _ = debug.gethook()
    debug.sethook()
    local w, h = self:getWidth(), self:getHeight()
    local cdata = ffi.C.malloc(w * h * 4)
    local mem = ffi.cast("char*", cdata)
    for y = 0, h-1 do
        local offset = 4 * w * y
        for x = 0, w-1 do
            local c = self:getPixel(x, y):getColorRGB32()
            mem[offset] = c.r
            mem[offset + 1] = c.g
            mem[offset + 2] = c.b
            mem[offset + 3] = 0xFF
            offset = offset + 4
        end
    end
    Png.encodeToFile(filename, mem, w, h)
    ffi.C.free(cdata)
    debug.sethook(hook, mask)
end

-- if no special case in BB???_mt exists, use function from BB_mt
-- (we do not use BB_mt as metatable for BB???_mt since this causes
--  a major slowdown and would not get properly JIT-compiled)
for name, func in pairs(BB_mt.__index) do
    if not BB4_mt.__index[name] then BB4_mt.__index[name] = func end
    if not BB8_mt.__index[name] then BB8_mt.__index[name] = func end
    if not BB8A_mt.__index[name] then BB8A_mt.__index[name] = func end
    if not BBRGB16_mt.__index[name] then BBRGB16_mt.__index[name] = func end
    if not BBRGB24_mt.__index[name] then BBRGB24_mt.__index[name] = func end
    if not BBRGB32_mt.__index[name] then BBRGB32_mt.__index[name] = func end
end

-- set metatables for the BlitBuffer types
local BlitBuffer4 = ffi.metatype("BlitBuffer4", BB4_mt)
local BlitBuffer8 = ffi.metatype("BlitBuffer8", BB8_mt)
local BlitBuffer8A = ffi.metatype("BlitBuffer8A", BB8A_mt)
local BlitBufferRGB16 = ffi.metatype("BlitBufferRGB16", BBRGB16_mt)
local BlitBufferRGB24 = ffi.metatype("BlitBufferRGB24", BBRGB24_mt)
local BlitBufferRGB32 = ffi.metatype("BlitBufferRGB32", BBRGB32_mt)

-- set metatables for the Color types
ffi.metatype("Color4L", Color4L_mt)
ffi.metatype("Color4U", Color4U_mt)
ffi.metatype("Color8", Color8_mt)
ffi.metatype("Color8A", Color8A_mt)
ffi.metatype("ColorRGB16", ColorRGB16_mt)
ffi.metatype("ColorRGB24", ColorRGB24_mt)
ffi.metatype("ColorRGB32", ColorRGB32_mt)

function BB.new(width, height, buffertype, dataptr, pitch)
    local bb = nil
    buffertype = buffertype or TYPE_BB8
    if pitch == nil then
        if buffertype == TYPE_BB4 then pitch = band(1, width) + rshift(width, 1)
        elseif buffertype == TYPE_BB8 then pitch = width
        elseif buffertype == TYPE_BB8A then pitch = lshift(width, 1)
        elseif buffertype == TYPE_BBRGB16 then pitch = lshift(width, 1)
        elseif buffertype == TYPE_BBRGB24 then pitch = width * 3
        elseif buffertype == TYPE_BBRGB32 then pitch = lshift(width, 2)
        end
    end
    if buffertype == TYPE_BB4 then bb = BlitBuffer4(width, height, pitch, nil, 0)
    elseif buffertype == TYPE_BB8 then bb = BlitBuffer8(width, height, pitch, nil, 0)
    elseif buffertype == TYPE_BB8A then bb = BlitBuffer8A(width, height, pitch, nil, 0)
    elseif buffertype == TYPE_BBRGB16 then bb = BlitBufferRGB16(width, height, pitch, nil, 0)
    elseif buffertype == TYPE_BBRGB24 then bb = BlitBufferRGB24(width, height, pitch, nil, 0)
    elseif buffertype == TYPE_BBRGB32 then bb = BlitBufferRGB32(width, height, pitch, nil, 0)
    else error("unknown blitbuffer type")
    end
    bb:setType(buffertype)
    if dataptr == nil then
        dataptr = ffi.C.malloc(pitch*height)
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

function BB.fromstring(width, height, buffertype, str, pitch)
    local dataptr = ffi.C.malloc(#str)
    ffi.copy(dataptr, str, #str)
    return BB.new(width, height, buffertype, dataptr, pitch)
end

function BB.tostring(bb)
    return ffi.string(bb.data, bb.pitch * bb.h)
end

--[[
return a Color value resembling a given level of blackness/gray

0 is white, 1.0 is black
--]]
function BB.gray(level)
    return Color8(0xFF - floor(0xFF * level))
end

-- some generic color values:
BB.COLOR_BLACK = Color8(0)
BB.COLOR_WHITE = Color8(0xFF)
BB.COLOR_GREY = Color8(0x80)
BB.COLOR_LIGHT_GREY = Color8(0xD0)

-- accessors for color types:
BB.Color4 = Color4L
BB.Color4L = Color4L
BB.Color4U = Color4U
BB.Color8 = Color8
BB.Color8A = Color8A
BB.ColorRGB16 = ColorRGB16
BB.ColorRGB24 = ColorRGB24
BB.ColorRGB32 = ColorRGB32

-- accessors for Blitbuffer types
BB.BlitBuffer4 = BlitBuffer4
BB.BlitBuffer8 = BlitBuffer8
BB.BlitBuffer8A = BlitBuffer8A
BB.BlitBufferRGB16 = BlitBufferRGB16
BB.BlitBufferRGB24 = BlitBufferRGB24
BB.BlitBufferRGB32 = BlitBufferRGB32
BB.TYPE_BB4 = TYPE_BB4
BB.TYPE_BB8 = TYPE_BB8
BB.TYPE_BB8A = TYPE_BB8A
BB.TYPE_BBRGB16 = TYPE_BBRGB16
BB.TYPE_BBRGB24 = TYPE_BBRGB24
BB.TYPE_BBRGB32 = TYPE_BBRGB32

return BB
