--[[
Freetype library interface (text rendering)
--]]

local ffi = require("ffi")
local Blitbuffer = require("ffi/blitbuffer")

-- the header definitions
require("ffi/freetype_h")

local ft2 = ffi.load("libs/libfreetype.so.6")

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

function FTFace_mt.__index:renderGlyph(char, background, foreground)
	assert(ft2.FT_Load_Char(self, char, ft2.FT_LOAD_RENDER) == 0, "freetype error")

	local bitmap = self.glyph.bitmap
	local glyph = {
		bb = Blitbuffer.new(bitmap.width, bitmap.rows),
		l  = self.glyph.bitmap_left,
		t  = self.glyph.bitmap_top,
		r  = tonumber(self.glyph.metrics.horiAdvance / 64),
		ax = tonumber(self.glyph.advance.x / 64),
		ay = tonumber(self.glyph.advance.y / 64)
	}

	for y = 0, bitmap.rows-1 do
		for x = 0, bitmap.width-1 do
			glyph.bb:setPixel(x, y,
				bit.rshift(bitmap.buffer[y * bitmap.pitch + x], 4))
		end
	end

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

local FTFaceType = ffi.metatype("struct FT_FaceRec_", FTFace_mt)

function FT.newFace(filename, pxsize)
	if pxsize == nil then pxsize = 16*64 end

	local facept = ffi.new("FT_Face[1]")

	assert(ft2.FT_New_Face(freetypelib, filename, 0, facept) == 0,
		"freetype error")

	face = facept[0]

	err = ft2.FT_Set_Pixel_Sizes(face, 0, pxsize)
	if err ~= 0 then
		FT_Done_Face(face)
		error("freetype error")
	end

	if face.charmap == nil then
		--TODO
	end

	return face;
end

return FT
