// We need to make generate first...
// CPPFLAGS="-I../koreader-base -I/var/tmp/niluje/mupdf/include"
#include <mupdf/fitz.h>
#include <mupdf/pdf.h>

#include "ffi-cdecl.h"

cdecl_const(FZ_STEXT_BLOCK_TEXT)

/* math */
cdecl_type(fz_point)
cdecl_type(fz_quad)
cdecl_type(fz_rect)

cdecl_const(fz_unit_rect)
cdecl_const(fz_empty_rect)
cdecl_const(fz_infinite_rect)
cdecl_func(fz_intersect_rect)
cdecl_func(fz_union_rect)

cdecl_type(fz_irect)
cdecl_const(fz_empty_irect)
cdecl_const(fz_infinite_irect)
cdecl_func(fz_intersect_irect)

cdecl_func(fz_irect_from_rect)
cdecl_func(fz_rect_from_quad)
cdecl_func(fz_round_rect)

cdecl_type(fz_matrix)
cdecl_const(fz_identity)
cdecl_func(fz_concat)
cdecl_func(fz_scale)
cdecl_func(fz_pre_scale)
cdecl_func(fz_rotate)
cdecl_func(fz_pre_rotate)
cdecl_func(fz_translate)
cdecl_func(fz_pre_translate)

cdecl_func(fz_transform_rect)

/* misc/assorted */
cdecl_type(fz_alloc_context)
cdecl_type(fz_locks_context)
cdecl_struct(fz_colorspace_context)
//cdecl_struct(fz_context)
cdecl_type(fz_context)
cdecl_type(fz_font)
cdecl_type(fz_hash_table)
cdecl_type(fz_storable)
cdecl_type(fz_store_drop_fn)
cdecl_struct(fz_storable)
cdecl_type(fz_key_storable)

/* buffer */
cdecl_type(fz_buffer)
cdecl_func(fz_new_buffer_from_shared_data)
cdecl_func(fz_drop_buffer)

/* context */
cdecl_type(fz_colorspace)
cdecl_func(fz_new_context_imp)
cdecl_func(fz_drop_context) // NOTE: libk2pdfopt uses old fz_free_context symbol
cdecl_func(fz_register_document_handlers)

/* images */
cdecl_struct(fz_separations)
cdecl_type(fz_separations)
cdecl_type(fz_image)
cdecl_type(fz_pixmap)
cdecl_struct(fz_pixmap)
cdecl_func(fz_new_image_from_buffer)
cdecl_func(fz_new_image_from_file)
cdecl_func(fz_get_pixmap_from_image)
cdecl_func(fz_save_pixmap_as_png)
cdecl_func(fz_keep_image)
cdecl_func(fz_drop_image)

cdecl_func(fz_runetochar)

/* document */
cdecl_struct(fz_outline)
cdecl_type(fz_outline)
//cdecl_struct(fz_document)
cdecl_type(fz_document)
//cdecl_struct(fz_page)
cdecl_type(fz_page)
cdecl_struct(fz_link)
cdecl_type(fz_link)
cdecl_type(fz_location)

cdecl_func(fz_open_document)
cdecl_func(fz_open_document_with_stream)
cdecl_func(fz_is_document_reflowable)
cdecl_func(fz_needs_password)
cdecl_func(fz_authenticate_password)
cdecl_func(fz_drop_document) // NOTE: libk2pdfopt uses old fz_free_document symbol
cdecl_func(fz_count_pages)
cdecl_func(fz_layout_document)
cdecl_func(fz_lookup_metadata)
cdecl_func(fz_resolve_link)

/* page */
cdecl_func(fz_load_page)
cdecl_func(fz_bound_page)
cdecl_func(fz_drop_page) // NOTE: libk2pdfopt uses old fz_free_page symbol

/* links */
//cdecl_struct(fz_link_s)
cdecl_func(fz_load_links)
cdecl_func(fz_drop_link)

/* outline */
cdecl_func(fz_load_outline)
cdecl_func(fz_drop_outline) // NOTE: libk2pdfopt uses old fz_free_outline symbol

/* stream */
cdecl_func(fz_drop_stream)
cdecl_func(fz_open_memory)

/* structured text */
cdecl_type(fz_stext_char)
cdecl_struct(fz_stext_char)

cdecl_type(fz_stext_line)
cdecl_struct(fz_stext_line)

cdecl_type(fz_stext_block)
cdecl_struct(fz_stext_block)
cdecl_type(fz_stext_options)
//cdecl_struct(fz_stext_options)
cdecl_type(fz_stext_page)
//cdecl_struct(fz_stext_page)
cdecl_func(fz_new_stext_page_from_page)
cdecl_func(fz_drop_stext_page) // NOTE: libk2pdfopt uses old fz_free_text_page symbol

/* pixmaps */
cdecl_type(fz_color_params)
cdecl_type(fz_default_colorspaces)
cdecl_func(fz_default_color_params)

cdecl_func(fz_new_pixmap)
cdecl_func(fz_new_pixmap_with_bbox)
cdecl_func(fz_new_pixmap_with_data)
cdecl_func(fz_new_pixmap_with_bbox_and_data)
cdecl_func(fz_convert_pixmap)
cdecl_func(fz_keep_pixmap)
cdecl_func(fz_drop_pixmap)
cdecl_func(fz_clear_pixmap_with_value)
cdecl_func(fz_gamma_pixmap)
cdecl_func(fz_scale_pixmap)
cdecl_func(fz_pixmap_width)
cdecl_func(fz_pixmap_height)
cdecl_func(fz_pixmap_components)
cdecl_func(fz_pixmap_samples)

cdecl_func(fz_device_gray)
cdecl_func(fz_device_rgb)
cdecl_func(fz_device_bgr)

/* device, rendering */
cdecl_func(fz_new_draw_device)
cdecl_func(fz_new_stext_device)
cdecl_func(fz_new_bbox_device)
cdecl_type(fz_cookie)
cdecl_func(fz_run_page)
cdecl_func(fz_close_device)
cdecl_func(fz_drop_device) // NOTE: libk2pdfopt uses old fz_free_device symbol

/* pdf specifics */
cdecl_enum(pdf_annot_type)
//cdecl_type(pdf_hotspot)
//cdecl_struct(pdf_hotspot_s)
cdecl_type(pdf_lexbuf)
//cdecl_struct(pdf_lexbuf_s)
cdecl_type(pdf_lexbuf_large)
//cdecl_struct(pdf_lexbuf_large_s)
cdecl_type(pdf_obj)
cdecl_type(pdf_annot)
cdecl_type(pdf_page)
//cdecl_struct(pdf_annot_s)
cdecl_type(pdf_document)
//cdecl_struct(pdf_document_s)
cdecl_func(pdf_specifics)
cdecl_func(mupdf_pdf_create_annot)
cdecl_func(mupdf_pdf_delete_annot)
cdecl_func(mupdf_pdf_set_annot_quad_points)
cdecl_func(mupdf_pdf_set_annot_contents)
cdecl_func(mupdf_pdf_first_annot)
cdecl_func(mupdf_pdf_next_annot)
cdecl_func(mupdf_pdf_annot_quad_point_count)
cdecl_func(mupdf_pdf_annot_quad_point)
cdecl_func(mupdf_pdf_set_text_annot_position)
cdecl_func(mupdf_pdf_set_markup_appearance)

/* saving documents */
cdecl_type(pdf_write_options)
//cdecl_struct(pdf_write_options)
cdecl_func(pdf_save_document)

cdecl_type(fz_load_system_font_fn)
cdecl_type(fz_load_system_cjk_font_fn)
cdecl_type(fz_load_system_fallback_font_fn)

cdecl_func(fz_install_load_system_font_funcs)
