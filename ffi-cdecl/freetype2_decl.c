#include <ft2build.h>

#include "ffi-cdecl.h"

#include <freetype/freetype.h>
#include <freetype/ftmodapi.h>
#include <freetype/ftoutln.h>
#include <freetype/ftsizes.h>
#include <freetype/ftsnames.h>
#include <freetype/ftsynth.h>
#include <freetype/ttnameid.h>
#include <freetype/tttables.h>
#include <freetype/tttags.h>

// Constants.
cdecl_const(FT_FACE_FLAG_EXTERNAL_STREAM)
cdecl_const(FT_FACE_FLAG_FAST_GLYPHS)
cdecl_const(FT_FACE_FLAG_FIXED_SIZES)
cdecl_const(FT_FACE_FLAG_FIXED_WIDTH)
cdecl_const(FT_FACE_FLAG_GLYPH_NAMES)
cdecl_const(FT_FACE_FLAG_HINTER)
cdecl_const(FT_FACE_FLAG_HORIZONTAL)
cdecl_const(FT_FACE_FLAG_KERNING)
cdecl_const(FT_FACE_FLAG_MULTIPLE_MASTERS)
cdecl_const(FT_FACE_FLAG_SCALABLE)
cdecl_const(FT_FACE_FLAG_SFNT)
cdecl_const(FT_FACE_FLAG_VERTICAL)
cdecl_const(FT_KERNING_DEFAULT)
cdecl_const(FT_KERNING_UNFITTED)
cdecl_const(FT_KERNING_UNSCALED)
cdecl_const(FT_LOAD_CROP_BITMAP)
cdecl_const(FT_LOAD_DEFAULT)
cdecl_const(FT_LOAD_FORCE_AUTOHINT)
cdecl_const(FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH)
cdecl_const(FT_LOAD_IGNORE_TRANSFORM)
cdecl_const(FT_LOAD_LINEAR_DESIGN)
cdecl_const(FT_LOAD_MONOCHROME)
cdecl_const(FT_LOAD_NO_AUTOHINT)
cdecl_const(FT_LOAD_NO_BITMAP)
cdecl_const(FT_LOAD_NO_HINTING)
cdecl_const(FT_LOAD_NO_RECURSE)
cdecl_const(FT_LOAD_NO_SCALE)
cdecl_const(FT_LOAD_PEDANTIC)
cdecl_const(FT_LOAD_RENDER)
cdecl_const(FT_LOAD_SBITS_ONLY)
cdecl_const(FT_LOAD_TARGET_LCD)
cdecl_const(FT_LOAD_TARGET_LCD_V)
cdecl_const(FT_LOAD_TARGET_LIGHT)
cdecl_const(FT_LOAD_TARGET_MONO)
cdecl_const(FT_LOAD_TARGET_NORMAL)
cdecl_const(FT_LOAD_VERTICAL_LAYOUT)
cdecl_const(FT_STYLE_FLAG_BOLD)
cdecl_const(FT_STYLE_FLAG_ITALIC)

// Basic types.
cdecl_type(FT_String)
cdecl_type(FT_Byte)
cdecl_type(FT_UShort)
cdecl_type(FT_Short)
cdecl_type(FT_Int)
cdecl_type(FT_UInt)
cdecl_type(FT_Long)
cdecl_type(FT_ULong)
cdecl_type(FT_Error)
cdecl_type(FT_Pos)

// Enums.
cdecl_type(FT_Encoding)
cdecl_enum(FT_Encoding_)
cdecl_type(FT_Glyph_Format)
cdecl_enum(FT_Glyph_Format_)
cdecl_type(FT_Render_Mode)
cdecl_enum(FT_Render_Mode_)
cdecl_type(FT_Sfnt_Tag)
cdecl_enum(FT_Sfnt_Tag_)

// Opaque (pointer) types.
cdecl_type(FT_BBox)
cdecl_type(FT_Bitmap)
cdecl_type(FT_Bitmap_Size)
cdecl_type(FT_CharMap)
cdecl_type(FT_Driver)
cdecl_type(FT_Face)
cdecl_type(FT_Face_Internal)
cdecl_type(FT_Generic)
cdecl_type(FT_GlyphSlot)
cdecl_type(FT_Glyph_Metrics)
cdecl_type(FT_Library)
cdecl_type(FT_List)
cdecl_type(FT_ListNode)
cdecl_type(FT_Memory)
cdecl_type(FT_Outline)
cdecl_type(FT_Size)
cdecl_type(FT_Size_Internal)
cdecl_type(FT_Size_Metrics)
cdecl_type(FT_Slot_Internal)
cdecl_type(FT_Stream)
cdecl_type(FT_SubGlyph)
cdecl_type(FT_Vector)
cdecl_type(TT_OS2)

cdecl_struct(FT_BBox_)
cdecl_struct(FT_Bitmap_)
cdecl_struct(FT_CharMapRec_)
cdecl_struct(FT_Generic_)
cdecl_struct(FT_Outline_)
cdecl_struct(FT_Vector_)
cdecl_struct(FT_Glyph_Metrics_)
cdecl_struct(FT_GlyphSlotRec_)
cdecl_struct(FT_ListRec_)
cdecl_struct(FT_Size_Metrics_)
cdecl_struct(FT_SizeRec_)
cdecl_struct(FT_FaceRec_)
cdecl_struct(TT_OS2_)

cdecl_func(FT_Done_Library)
cdecl_func(FT_Init_FreeType)
cdecl_func(FT_Reference_Library)

cdecl_func(FT_Done_Face)
cdecl_func(FT_New_Face)
cdecl_func(FT_Reference_Face)
cdecl_func(FT_Set_Pixel_Sizes)

cdecl_func(FT_Activate_Size)
cdecl_func(FT_Done_Size)
cdecl_func(FT_New_Size)

cdecl_func(FT_Get_Char_Index)
cdecl_func(FT_Load_Char)

cdecl_func(FT_Get_Kerning)

cdecl_func(FT_GlyphSlot_Embolden)
cdecl_func(FT_GlyphSlot_Oblique)

cdecl_func(FT_Load_Glyph)
cdecl_func(FT_Render_Glyph)

cdecl_func(FT_MulFix)
cdecl_func(FT_Outline_Embolden)
cdecl_func(FT_Outline_Translate)

cdecl_func(FT_Get_Sfnt_Table)
