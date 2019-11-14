#include <ft2build.h>

#include "ffi-cdecl.h"

#include FT_FREETYPE_H
#include FT_SYNTHESIS_H
#include FT_OUTLINE_H

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

cdecl_const(FT_LOAD_RENDER)
cdecl_const(FT_LOAD_DEFAULT)
cdecl_const(FT_LOAD_TARGET_LIGHT)
cdecl_const(FT_LOAD_NO_AUTOHINT)
cdecl_const(FT_LOAD_NO_HINTING)
cdecl_const(FT_LOAD_FORCE_AUTOHINT)
cdecl_const(FT_FACE_FLAG_KERNING)
cdecl_const(FT_KERNING_DEFAULT)
