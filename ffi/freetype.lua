--[[--
Freetype library interface (text rendering)

@module ffi.freetype
--]]

local bit = require("bit")
local ffi = require("ffi")
local Blitbuffer = require("ffi/blitbuffer")

-- the header definitions
require("ffi/freetype_h")

local ft2
if ffi.os == "Windows" then
    ft2 = ffi.load("libs/libfreetype-6.dll")
elseif ffi.os == "OSX" then
    ft2 = ffi.load("libs/libfreetype.6.dylib")
else
    ft2 = ffi.load("libs/libfreetype.so.6")
end

local freetypelib = ffi.new("FT_Library[1]")
assert(ft2.FT_Init_FreeType(freetypelib) == 0, "Couldn't initialize Freetype!")
freetypelib = freetypelib[0]

local FT = {}

-- metatable for BlitBuffer objects:
local FTFace_mt = {__index={}}

function FTFace_mt.__index:checkGlyph(char)
    if ft2.FT_Get_Char_Index(self, char) == 0 then
        return 0
    else
        return 1
    end
end

function FTFace_mt.__index:renderGlyph(char, bold)
    assert(ft2.FT_Load_Char(self, char, ft2.FT_LOAD_RENDER) == 0, "freetype error")

    if bold then ft2.FT_GlyphSlot_Embolden(self.glyph) end
    local bitmap = self.glyph.bitmap
    -- NOTE: depending on the char, bitmap_top (bearingY) can be larger than
    -- bb:getHeight(). For example: ×. This means the char needs to be drawn
    -- above baseline.
    local glyph = {
        bb = Blitbuffer.new(bitmap.width, bitmap.rows, Blitbuffer.TYPE_BB8, bitmap.buffer, bitmap.pitch):copy(),
        l  = self.glyph.bitmap_left,
        t  = self.glyph.bitmap_top,
        r  = tonumber(self.glyph.metrics.horiAdvance / 64),
        ax = tonumber(self.glyph.advance.x / 64),
        ay = tonumber(self.glyph.advance.y / 64)
    }

    return glyph
end

function FTFace_mt.__index:hasKerning()
    if bit.band(self.face_flags, ft2.FT_FACE_FLAG_KERNING) ~= 0 then
        return 1
    else
        return 0
    end
end

function FTFace_mt.__index:getKerning(leftcharcode, rightcharcode)
    local kerning = ffi.new("FT_Vector")
    assert(ft2.FT_Get_Kerning(self, leftcharcode, rightcharcode,
        ft2.FT_KERNING_DEFAULT, kerning) == 0,
        "freetype error when getting kerning.")
    return tonumber(kerning.x / 64)
end

function FTFace_mt.__index:getHeightAndAscender()
    local y_scale = self.size.metrics.y_ppem / self.units_per_EM
    return self.height * y_scale, self.ascender * y_scale
end

function FTFace_mt.__index:done()
    assert(ft2.FT_Done_Face(self) == 0, "freetype error when freeing face")
end

FTFace_mt.__gc = FTFace_mt.__index.done;

local FTFaceType = ffi.metatype("struct FT_FaceRec_", FTFace_mt) -- luacheck: ignore 211

function FT.newFace(filename, pxsize)
    if pxsize == nil then pxsize = 16*64 end

    local facept = ffi.new("FT_Face[1]")

    local err = ft2.FT_New_Face(freetypelib, filename, 0, facept)
    if err ~= 0 then
        error("Failed to load font '"..filename.."', freetype error code: "..err)
    end

    local face = facept[0]

    if ft2.FT_Set_Pixel_Sizes(face, 0, pxsize) ~= 0 then
        ft2.FT_Done_Face(face)
        error("freetype error")
    end

    -- if face.charmap == nil then
        --TODO
    -- end

    return face
end

return FT
