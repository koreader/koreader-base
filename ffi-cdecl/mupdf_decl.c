#include <mupdf/fitz.h>
#include "wrap-mupdf.h"

#include "ffi-cdecl.h"

cdecl_const(FZ_PAGE_BLOCK_TEXT)

/* math */
cdecl_type(fz_point)
cdecl_struct(fz_point_s)

cdecl_type(fz_rect)
cdecl_struct(fz_rect_s)
cdecl_const(fz_unit_rect)
cdecl_const(fz_empty_rect)
cdecl_const(fz_infinite_rect)
cdecl_func(fz_intersect_rect)
cdecl_func(fz_union_rect)

cdecl_type(fz_irect)
cdecl_struct(fz_irect_s)
cdecl_const(fz_empty_irect)
cdecl_const(fz_infinite_irect)
cdecl_func(fz_intersect_irect)

cdecl_func(fz_irect_from_rect)
cdecl_func(fz_round_rect)

cdecl_type(fz_matrix)
cdecl_struct(fz_matrix_s)
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
cdecl_type(fz_context)
cdecl_type(fz_storable)
cdecl_type(fz_store_drop_fn)
cdecl_struct(fz_storable_s)

/* context */
cdecl_type(fz_alloc_context)
cdecl_type(fz_colorspace)
cdecl_func(fz_new_context_imp)
cdecl_func(fz_drop_context) // FIXME: libk2pdfopt uses old fz_free_context symbol
cdecl_func(fz_register_document_handlers)

/* images */
cdecl_type(fz_image)
cdecl_type(fz_pixmap)
cdecl_struct(fz_image_s)
cdecl_struct(fz_pixmap_s)
cdecl_func(fz_new_image_from_data) // compat, use wrapper instead:
cdecl_func(mupdf_new_image_from_data)
cdecl_func(fz_new_pixmap_from_image) // compat, use wrapper instead:
cdecl_func(mupdf_new_pixmap_from_image)
cdecl_func(fz_keep_image)
cdecl_func(fz_drop_image)

cdecl_func(fz_load_png)
cdecl_func(fz_runetochar)

/* document */
cdecl_enum(fz_link_kind_e)
cdecl_type(fz_link_dest)
cdecl_struct(fz_link_dest_s)
cdecl_type(fz_outline)
cdecl_struct(fz_outline_s)
cdecl_type(fz_document)
cdecl_type(fz_page)
cdecl_type(fz_write_options)
cdecl_struct(fz_document_s)
cdecl_type(fz_link)
cdecl_struct(fz_page_s)

cdecl_func(mupdf_open_document)
cdecl_func(fz_needs_password)
cdecl_func(fz_authenticate_password)
cdecl_func(fz_drop_document) // FIXME: libk2pdfopt uses old fz_free_document symbol
cdecl_func(mupdf_count_pages)

/* page */
cdecl_func(mupdf_load_page)
cdecl_func(fz_bound_page)
cdecl_func(fz_drop_page) // FIXME: libk2pdfopt uses old fz_free_page symbol

/* links */
cdecl_struct(fz_link_s)
cdecl_func(mupdf_load_links)
cdecl_func(fz_drop_link)

/* outline */
cdecl_func(mupdf_load_outline)
cdecl_func(fz_drop_outline) // FIXME: libk2pdfopt uses old fz_free_outline symbol

/* structured text */
cdecl_type(fz_text_style)
cdecl_struct(fz_text_style_s)

cdecl_type(fz_text_char)
cdecl_struct(fz_text_char_s)

cdecl_type(fz_text_span)
cdecl_struct(fz_text_span_s)

cdecl_type(fz_text_line)
cdecl_struct(fz_text_line_s)

cdecl_type(fz_text_sheet)
cdecl_struct(fz_text_sheet_s)
cdecl_func(mupdf_new_text_sheet)
cdecl_func(fz_drop_text_sheet) // FIXME: libk2pdfopt uses old fz_free_text_sheet symbol

cdecl_type(fz_text_page)
cdecl_type(fz_page_block)
cdecl_struct(fz_text_page_s)
cdecl_func(mupdf_new_text_page)
cdecl_func(fz_drop_text_page) // FIXME: libk2pdfopt uses old fz_free_text_page symbol
cdecl_type(fz_text_block)
cdecl_struct(fz_page_block_s)
cdecl_struct(fz_text_block_s)

cdecl_func(fz_text_char_bbox)

/* pixmaps */
cdecl_func(mupdf_new_pixmap)
cdecl_func(fz_new_pixmap) // compat
cdecl_func(mupdf_new_pixmap_with_bbox)
cdecl_func(mupdf_new_pixmap_with_data)
cdecl_func(mupdf_new_pixmap_with_bbox_and_data)
cdecl_func(fz_convert_pixmap)
cdecl_func(fz_keep_pixmap)
cdecl_func(fz_drop_pixmap)
cdecl_func(fz_clear_pixmap_with_value)
cdecl_func(fz_gamma_pixmap)
cdecl_func(fz_pixmap_width)
cdecl_func(fz_pixmap_height)
cdecl_func(fz_pixmap_components)
cdecl_func(fz_pixmap_samples)

cdecl_func(fz_device_gray)
cdecl_func(fz_device_rgb)

/* device, rendering */
cdecl_func(mupdf_new_draw_device)
cdecl_func(mupdf_new_text_device)
cdecl_func(mupdf_new_bbox_device)
cdecl_func(mupdf_run_page)
cdecl_func(fz_drop_device) // FIXME: libk2pdfopt uses old fz_free_device symbol

/* pdf specifics */
cdecl_type(pdf_hotspot)
cdecl_struct(pdf_hotspot_s)
cdecl_type(pdf_lexbuf)
cdecl_struct(pdf_lexbuf_s)
cdecl_type(pdf_lexbuf_large)
cdecl_struct(pdf_lexbuf_large_s)
cdecl_type(pdf_annot)
cdecl_type(pdf_page)
cdecl_struct(pdf_annot_s)
cdecl_type(pdf_document)
cdecl_struct(pdf_document_s)
cdecl_func(pdf_specifics)
cdecl_func(mupdf_pdf_create_annot)
cdecl_func(mupdf_pdf_set_markup_annot_quadpoints)
cdecl_func(mupdf_pdf_set_markup_appearance)

/* saving documents */
cdecl_struct(fz_write_options_s)
cdecl_func(mupdf_write_document)

/* the following is for our own wrapper lib: */
cdecl_func(mupdf_get_my_alloc_context)
cdecl_func(mupdf_get_cache_size)
cdecl_func(mupdf_error_code)
cdecl_func(mupdf_error_message)
