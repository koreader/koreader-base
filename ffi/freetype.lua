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
freetypelib = ffi.gc(freetypelib[0], ft2.FT_Done_Library)

local function done_face(face)
    local lib = face.generic.data
    assert(ft2.FT_Done_Face(face) == 0, "freetype error when freeing face")
    ft2.FT_Done_Library(lib)
end

local function new_face(filename, faceindex)
    local facept = ffi.new("FT_Face[1]")
    local err = ft2.FT_New_Face(freetypelib, filename, faceindex, facept)
    if err ~= 0 then
        error("Failed to load font '"..filename.."', freetype error code: "..err)
    end
    local face = ffi.gc(facept[0], done_face)
    ft2.FT_Reference_Library(freetypelib)
    face.generic.data = freetypelib
    return face
end

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

-- For use with glyph index and metrics returned by Harfbuzz
-- These flags should be sync'ed with those used in xtext.cpp getHbFontData()
local FT_Load_Glyph_flags = bit.bor(ft2.FT_LOAD_DEFAULT, ft2.FT_LOAD_TARGET_LIGHT)
-- FT_Load_Glyph_flags = bit.bor(FT_Load_Glyph_flags, ft2.FT_LOAD_FORCE_AUTOHINT)
-- (No hinting, as it would mess synthetized bold)
FT_Load_Glyph_flags = bit.bor(FT_Load_Glyph_flags, ft2.FT_LOAD_NO_HINTING, ft2.FT_LOAD_NO_AUTOHINT)

function FTFace_mt.__index:renderGlyphByIndex(index, embolden_half_strength)
    assert(ft2.FT_Load_Glyph(self, index, FT_Load_Glyph_flags) == 0, "freetype error")

    -- We can't use FT_GlyphSlot_Embolden() as it updates the
    -- glyph metrics from the font, and would mess the adjusments
    -- provided by Harfbuzz. We need to use FT_Outline_Embolden
    -- and FT_Outline_Translate in a way to not move metrics.
    if embolden_half_strength and self.glyph.format == ft2.FT_GLYPH_FORMAT_OUTLINE then
        ft2.FT_Outline_Embolden(self.glyph.outline, 2*embolden_half_strength);
        ft2.FT_Outline_Translate(self.glyph.outline, -embolden_half_strength, -embolden_half_strength);
    end
    ft2.FT_Render_Glyph(self.glyph, ft2.FT_RENDER_MODE_NORMAL);
    local bitmap = self.glyph.bitmap
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

function FTFace_mt.__index:getEmboldenHalfStrength(factor)
    -- See crengine/src/lvfntman.cpp setEmbolden() for details
    if not factor then
        factor = 1/2 -- (a bit bolder than crengine which uses 3/8)
    end
    local strength = ft2.FT_MulFix(self.units_per_EM, self.size.metrics.y_scale) / 24
        -- Note: this is a 64bit integer cdata, that we need to return
        -- as such. So, we need to do C arithmetic with it, or we'll
        -- have it converted to a Lua number.
    local factor_int64 = ffi.new("int64_t", 1024*factor)
    strength = strength * factor_int64 / 1024
    return strength
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
    ffi.gc(self, nil)
    done_face(self)
end

function FTFace_mt.__index:getInfo()
    local finfo = {
        name = ffi.string(self.family_name),
        -- Style
        mono = bit.band(tonumber(self.face_flags), ft2.FT_FACE_FLAG_FIXED_WIDTH) ~= 0,
        hint = bit.band(tonumber(self.face_flags), ft2.FT_FACE_FLAG_HINTER) ~= 0,
        bold = bit.band(tonumber(self.style_flags), ft2.FT_STYLE_FLAG_BOLD) ~= 0,
        italic = bit.band(tonumber(self.style_flags), ft2.FT_STYLE_FLAG_ITALIC) ~= 0,
        serif = nil,
        ui = false,
        names = nil,
    }

    -- In practice, just going by latin name can tell us more than the depressingly absent tags
    finfo.ui = finfo.name:match("UI$") ~= nil
    local lname = finfo.name:lower()
    if lname:match("serif") then
        finfo.serif = true
    elseif lname:match("sans") then
        finfo.serif = false
    elseif bit.band(tonumber(self.face_flags), ft2.FT_FACE_FLAG_SFNT) ~= 0 then
        local os2 = ft2.FT_Get_Sfnt_Table(self, ft2.FT_SFNT_OS2)
        if os2 ~= nil then
            local kls = tonumber(ffi.cast("TT_OS2*", os2).sFamilyClass)
            if kls ~= 0 then -- 0 is usually bogus
                -- class 8 = sans, otherwise serif
                finfo.serif = bit.band(kls, 0x0800) == 0
            end
        end
        if finfo.serif == nil then
            --TODO: Maybe it's worth to consult panose tables too?
            finfo.serif = true
        end
    end
    return finfo
end

local FTFaceType = ffi.metatype("struct FT_FaceRec_", FTFace_mt) -- luacheck: ignore 211

function FT.newFace(filename, pxsize, faceindex)
    if pxsize == nil then pxsize = 16*64 end
    if faceindex == nil then faceindex = 0 end
    local face = new_face(filename, faceindex)
    if ft2.FT_Set_Pixel_Sizes(face, 0, pxsize) ~= 0 then
        face:done()
        error("freetype error")
    end
    -- if face.charmap == nil then
        --TODO
    -- end
    return face
end

function FT.getFaceCount(filename, info)
    -- Probes number of faces available within the font file
    local success, face = pcall(new_face, filename, -1)
    if not success then return nil end
    local nfaces = tonumber(face.num_faces)
    face:done()
    return nfaces
end

return FT
