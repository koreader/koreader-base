#include <ft2build.h>

#include "ffi-cdecl.h"

#include <freetype/freetype.h>
#include <freetype/ftmodapi.h>
#include <freetype/ftoutln.h>
#include <freetype/ftsnames.h>
#include <freetype/ftsynth.h>
#include <freetype/ttnameid.h>
#include <freetype/tttables.h>
#include <freetype/tttags.h>

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

cdecl_struct(FT_Generic_)
cdecl_type(FT_Generic)

cdecl_type(FT_ListNode)
cdecl_struct(FT_ListNodeRec_)

cdecl_type(FT_List)
cdecl_struct(FT_ListRec_)

cdecl_struct(FT_BBox_)
cdecl_type(FT_BBox)

cdecl_struct(FT_Bitmap_Size_)
cdecl_type(FT_Bitmap_Size)

cdecl_struct(FT_Bitmap_)
cdecl_type(FT_Bitmap)

cdecl_struct(FT_Vector_)
cdecl_type(FT_Vector)

cdecl_struct(FT_Outline_)
cdecl_type(FT_Outline)

cdecl_type(FT_Memory)
cdecl_struct(FT_MemoryRec_)

cdecl_union(FT_StreamDesc_)
cdecl_type(FT_StreamDesc)

cdecl_type(FT_Stream)
cdecl_struct(FT_StreamRec_)

cdecl_enum(FT_Glyph_Format_)
cdecl_type(FT_Glyph_Format)

cdecl_struct(FT_LibraryRec_)
cdecl_type(FT_Library)

cdecl_type(FT_Face)
cdecl_type(FT_Glyph_Metrics)
cdecl_struct(FT_Glyph_Metrics_)
cdecl_struct(FT_SubGlyphRec_)
cdecl_type(FT_SubGlyph)
cdecl_struct(FT_Slot_InternalRec_)
cdecl_type(FT_Slot_Internal)

cdecl_type(FT_GlyphSlot)
cdecl_struct(FT_GlyphSlotRec_)

cdecl_struct(FT_Size_Metrics_)
cdecl_type(FT_Size_Metrics)

cdecl_type(FT_Size_Internal)
cdecl_struct(FT_Size_InternalRec_)

cdecl_type(FT_Size)
cdecl_struct(FT_SizeRec_)

cdecl_type(FT_CharMap)
cdecl_struct(FT_DriverRec_)
cdecl_type(FT_Driver)
cdecl_struct(FT_Face_InternalRec_)
cdecl_type(FT_Face_Internal)

cdecl_struct(FT_FaceRec_)

cdecl_enum(FT_Encoding_)
cdecl_type(FT_Encoding)

cdecl_struct(FT_CharMapRec_)

cdecl_func(FT_Init_FreeType)
cdecl_func(FT_Reference_Library)
cdecl_func(FT_Done_Library)

cdecl_func(FT_New_Face)
cdecl_func(FT_Set_Pixel_Sizes)
cdecl_func(FT_Done_Face)

cdecl_func(FT_Get_Char_Index)
cdecl_func(FT_Load_Char)

cdecl_func(FT_Get_Kerning)

cdecl_func(FT_GlyphSlot_Embolden)
cdecl_func(FT_GlyphSlot_Oblique)

cdecl_enum(FT_Render_Mode_)
cdecl_type(FT_Render_Mode)

cdecl_func(FT_Load_Glyph)
cdecl_func(FT_Render_Glyph)

cdecl_func(FT_Outline_Embolden)
cdecl_func(FT_Outline_Translate)
cdecl_func(FT_MulFix)

cdecl_func(FT_Get_First_Char)
cdecl_func(FT_Get_Next_Char)

cdecl_const(FT_LOAD_DEFAULT)
cdecl_const(FT_LOAD_NO_SCALE)
cdecl_const(FT_LOAD_NO_HINTING)
cdecl_const(FT_LOAD_RENDER)
cdecl_const(FT_LOAD_NO_BITMAP)
cdecl_const(FT_LOAD_VERTICAL_LAYOUT)
cdecl_const(FT_LOAD_FORCE_AUTOHINT)
cdecl_const(FT_LOAD_CROP_BITMAP)
cdecl_const(FT_LOAD_PEDANTIC)
cdecl_const(FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH)
cdecl_const(FT_LOAD_NO_RECURSE)
cdecl_const(FT_LOAD_IGNORE_TRANSFORM)
cdecl_const(FT_LOAD_MONOCHROME)
cdecl_const(FT_LOAD_LINEAR_DESIGN)

cdecl_const(FT_LOAD_SBITS_ONLY)
cdecl_const(FT_LOAD_NO_AUTOHINT)

cdecl_const(FT_LOAD_TARGET_NORMAL)
cdecl_const(FT_LOAD_TARGET_LIGHT)
cdecl_const(FT_LOAD_TARGET_MONO)
cdecl_const(FT_LOAD_TARGET_LCD)
cdecl_const(FT_LOAD_TARGET_LCD_V)

cdecl_const(FT_FACE_FLAG_SCALABLE)
cdecl_const(FT_FACE_FLAG_FIXED_SIZES)
cdecl_const(FT_FACE_FLAG_FIXED_WIDTH)
cdecl_const(FT_FACE_FLAG_HORIZONTAL)
cdecl_const(FT_FACE_FLAG_VERTICAL)
cdecl_const(FT_FACE_FLAG_SFNT)
cdecl_const(FT_FACE_FLAG_KERNING)
cdecl_const(FT_FACE_FLAG_MULTIPLE_MASTERS)
cdecl_const(FT_FACE_FLAG_GLYPH_NAMES)
cdecl_const(FT_FACE_FLAG_EXTERNAL_STREAM)
cdecl_const(FT_FACE_FLAG_FAST_GLYPHS)
cdecl_const(FT_FACE_FLAG_HINTER)


cdecl_const(FT_STYLE_FLAG_BOLD)
cdecl_const(FT_STYLE_FLAG_ITALIC)


cdecl_const(FT_KERNING_DEFAULT)
cdecl_const(FT_KERNING_UNFITTED)
cdecl_const(FT_KERNING_UNSCALED)

cdecl_struct(TT_OS2_)
cdecl_type(TT_OS2)

cdecl_enum(FT_Sfnt_Tag_)
cdecl_type(FT_Sfnt_Tag)
cdecl_func(FT_Get_Sfnt_Table)

cdecl_struct(FT_SfntName_)
cdecl_type(FT_SfntName)



cdecl_const(TT_NAME_ID_COPYRIGHT)
cdecl_const(TT_NAME_ID_FONT_FAMILY)
cdecl_const(TT_NAME_ID_FONT_SUBFAMILY)
cdecl_const(TT_NAME_ID_UNIQUE_ID)
cdecl_const(TT_NAME_ID_FULL_NAME)
cdecl_const(TT_NAME_ID_VERSION_STRING)
cdecl_const(TT_NAME_ID_PS_NAME)
cdecl_const(TT_NAME_ID_TRADEMARK)
cdecl_const(TT_NAME_ID_MANUFACTURER)
cdecl_const(TT_NAME_ID_DESIGNER)
cdecl_const(TT_NAME_ID_DESCRIPTION)
cdecl_const(TT_NAME_ID_VENDOR_URL)
cdecl_const(TT_NAME_ID_DESIGNER_URL)
cdecl_const(TT_NAME_ID_LICENSE)
cdecl_const(TT_NAME_ID_LICENSE_URL)
cdecl_const(TT_NAME_ID_PREFERRED_FAMILY)
cdecl_const(TT_NAME_ID_PREFERRED_SUBFAMILY)
cdecl_const(TT_NAME_ID_MAC_FULL_NAME)
cdecl_const(TT_NAME_ID_SAMPLE_TEXT)
cdecl_const(TT_NAME_ID_CID_FINDFONT_NAME)
cdecl_const(TT_NAME_ID_WWS_FAMILY)
cdecl_const(TT_NAME_ID_WWS_SUBFAMILY)

cdecl_func(FT_Get_Sfnt_Name_Count)
cdecl_func(FT_Get_Sfnt_Name)
