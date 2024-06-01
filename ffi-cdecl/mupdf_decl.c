// We need to make generate first...
// CPPFLAGS="-I../koreader-base -I/var/tmp/niluje/mupdf/include"

#include "wrap-mupdf.h"

#include "ffi-cdecl.h"

cdecl_const(FZ_STEXT_BLOCK_TEXT)

/* math */
cdecl_type(fz_point)
cdecl_type(fz_quad)
cdecl_type(fz_rect)
cdecl_type(fz_irect)
cdecl_type(fz_matrix)
cdecl_var(fz_identity)
cdecl_var(fz_empty_rect)

/* misc/assorted */
cdecl_type(fz_context)
cdecl_type(fz_font)
cdecl_func(fz_install_external_font_funcs)

/* buffer */
cdecl_type(fz_buffer)
cdecl_func(mupdf_new_buffer_from_shared_data)
cdecl_func(mupdf_drop_buffer)

/* context */
cdecl_type(fz_alloc_context)
cdecl_type(fz_colorspace)
cdecl_type(fz_locks_context)
cdecl_func(fz_new_context_imp)
cdecl_func(fz_drop_context)
cdecl_func(fz_register_document_handlers)

/* images */
cdecl_type(fz_image)
cdecl_type(fz_pixmap)
cdecl_func(mupdf_new_image_from_buffer)
cdecl_func(mupdf_get_pixmap_from_image)
cdecl_func(fz_drop_image)

cdecl_func(fz_runetochar)

/* document */
cdecl_type(fz_stream)
cdecl_type(fz_location)
cdecl_type(fz_outline)
cdecl_struct(fz_outline)
cdecl_type(fz_cookie)
cdecl_type(fz_separations)
cdecl_type(fz_page)
cdecl_type(fz_document)
cdecl_type(fz_device)

cdecl_func(mupdf_open_document)
cdecl_func(mupdf_open_document_with_stream)
cdecl_func(fz_is_document_reflowable)
cdecl_func(fz_needs_password)
cdecl_func(fz_authenticate_password)
cdecl_func(fz_drop_document)
cdecl_func(mupdf_count_pages)
cdecl_func(mupdf_layout_document)
cdecl_func(fz_lookup_metadata)

/* page */
cdecl_func(mupdf_load_page)
cdecl_func(mupdf_fz_bound_page)
cdecl_func(fz_drop_page)

/* links */
cdecl_type(fz_link)
cdecl_struct(fz_link)
cdecl_func(mupdf_load_links)
cdecl_func(mupdf_fz_resolve_link)
cdecl_func(fz_drop_link)

/* location */
cdecl_func(mupdf_fz_page_number_from_location)
cdecl_func(mupdf_fz_location_from_page_number)

/* outline */
cdecl_func(mupdf_load_outline)
cdecl_func(fz_drop_outline)

/* stream */
cdecl_func(mupdf_drop_stream)
cdecl_func(mupdf_open_memory)

/* structured text */
cdecl_type(fz_stext_char)
cdecl_struct(fz_stext_char)

cdecl_type(fz_stext_line)
cdecl_struct(fz_stext_line)

cdecl_type(fz_stext_block)
cdecl_struct(fz_stext_block)
cdecl_type(fz_stext_options)
cdecl_type(fz_stext_page)
cdecl_func(mupdf_new_stext_page_from_page)
cdecl_func(fz_drop_stext_page)

cdecl_type(fz_color_params)
cdecl_type(fz_default_colorspaces)
cdecl_const(fz_default_color_params)

/* pixmaps */
cdecl_func(fz_new_pixmap) // compat
cdecl_func(mupdf_new_pixmap_with_bbox)
cdecl_func(mupdf_new_pixmap_with_data)
cdecl_func(mupdf_new_pixmap_with_bbox_and_data)
cdecl_func(mupdf_convert_pixmap)
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
cdecl_func(mupdf_new_draw_device)
cdecl_func(mupdf_new_bbox_device)
cdecl_func(mupdf_run_page)
cdecl_func(fz_close_device)
cdecl_func(fz_drop_device)

/* pdf specifics */
cdecl_enum(pdf_annot_type)
cdecl_type(pdf_annot)
cdecl_type(pdf_page)
cdecl_type(pdf_document)

/* annotations */
cdecl_func(mupdf_pdf_create_annot)
cdecl_func(mupdf_pdf_delete_annot)
cdecl_func(mupdf_pdf_set_annot_quad_points)
cdecl_func(mupdf_pdf_set_annot_contents)
cdecl_func(mupdf_pdf_set_annot_color)
cdecl_func(mupdf_pdf_set_annot_opacity)
cdecl_func(mupdf_pdf_first_annot)
cdecl_func(mupdf_pdf_next_annot)
cdecl_func(mupdf_pdf_annot_quad_point_count)
cdecl_func(mupdf_pdf_annot_quad_point)

/* saving documents */
cdecl_type(pdf_write_options)
cdecl_func(mupdf_pdf_save_document)

/* the following is for our own wrapper lib: */
cdecl_func(mupdf_get_my_alloc_context)
cdecl_func(mupdf_get_cache_size)
cdecl_func(mupdf_error_code)
cdecl_func(mupdf_error_message)

/* geometry */
cdecl_func(mupdf_fz_scale)
cdecl_func(mupdf_fz_translate)
cdecl_func(mupdf_fz_pre_rotate)
cdecl_func(mupdf_fz_pre_translate)
cdecl_func(mupdf_fz_transform_rect)
cdecl_func(mupdf_fz_round_rect)
cdecl_func(mupdf_fz_union_rect)
cdecl_func(mupdf_fz_rect_from_quad)
