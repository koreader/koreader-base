// CPPFLAGS="-I/usr/include/freetype2"

#include <harfbuzz/hb.h>
#include <harfbuzz/hb-ft.h>
#include <harfbuzz/hb-ot.h>
#include "ffi-cdecl.h"

// The few bits we actually rely on for ffi/harfbuzz.lua
cdecl_c99_type(hb_codepoint_t, uint32_t)
cdecl_union(_hb_var_int_t)
cdecl_type(hb_var_int_t)

cdecl_type(hb_face_t)
cdecl_type(hb_language_t)
cdecl_type(hb_ot_name_id_t)
cdecl_struct(hb_ot_name_entry_t)
cdecl_type(hb_ot_name_entry_t)
cdecl_type(hb_set_t)

cdecl_func(hb_ot_name_list_names)
cdecl_func(hb_language_to_string)
cdecl_func(hb_ot_name_get_utf8)
cdecl_func(hb_set_create)
cdecl_func(hb_face_collect_unicodes)
cdecl_func(hb_set_set)
cdecl_func(hb_set_intersect)
cdecl_func(hb_set_get_population)
cdecl_func(hb_set_destroy)
cdecl_func(hb_face_destroy)
cdecl_func(hb_set_add_range)

// And in front (frontend/fontlist.lua)
cdecl_type(hb_blob_t)
cdecl_type(hb_memory_mode_t)
cdecl_type(hb_destroy_func_t)

cdecl_const(HB_OT_NAME_ID_FONT_FAMILY)
cdecl_const(HB_OT_NAME_ID_FONT_SUBFAMILY)
cdecl_const(HB_OT_NAME_ID_FULL_NAME)

cdecl_type(FT_Face)

cdecl_func(hb_blob_create)
cdecl_func(hb_face_create)
cdecl_func(hb_blob_destroy)
cdecl_func(hb_face_get_glyph_count)
cdecl_func(hb_ft_face_create_referenced)
