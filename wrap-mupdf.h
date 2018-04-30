/*
    KindlePDFViewer: MuPDF abstraction for Lua
    Copyright (C) 2011 Hans-Werner Hilse <hilse@web.de>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#ifndef MUPDF_DO_WRAP
#ifndef _PDF_H
#define _PDF_H

#include <mupdf/fitz.h>
#include <mupdf/pdf.h>

extern fz_alloc_context* mupdf_get_my_alloc_context();
extern int mupdf_get_cache_size();
extern int mupdf_error_code(fz_context *ctx);
extern char* mupdf_error_message(fz_context *ctx);

// this will turn the wrappers defined below into their declarations
#define MUPDF_WRAP(wrapper_name, ret_type, failure_value, call, ...) \
    ret_type wrapper_name(fz_context *ctx, ##__VA_ARGS__);

#else // _PDF_H
// this will silence the wrappers
#define MUPDF_WRAP(...)
#endif

#else // MUPDF_DO_WRAP
#ifdef MUPDF_WRAP
#undef MUPDF_WRAP
#endif

// this will create actual implementations of the wrappers
// note that we must not return from within fz_try/fz_catch blocks,
// otherwise, we will leave information on the exception stack and
// it will overflow.
#define MUPDF_WRAP(wrapper_name, ret_type, failure_value, call, ...) \
    extern ret_type wrapper_name(fz_context *ctx, ##__VA_ARGS__) { \
        ret_type ret; \
        fz_try(ctx) { call; } \
        fz_catch(ctx) { ret = failure_value; } \
        return ret; \
    }

#endif

// definitions of the wrappers:

MUPDF_WRAP(mupdf_open_document, fz_document*, NULL,
    ret = fz_open_document(ctx, filename),
    const char* filename)
MUPDF_WRAP(mupdf_open_document_with_stream, fz_document*, NULL,
    ret = fz_open_document_with_stream(ctx, magic, stream),
    const char *magic, fz_stream *stream)
MUPDF_WRAP(mupdf_open_memory, fz_stream*, NULL,
    ret = fz_open_memory(ctx, data, len),
    const unsigned char *data, size_t len)
MUPDF_WRAP(mupdf_drop_stream, void*, NULL,
    { fz_drop_stream(ctx, stm); ret = (void*) -1; },
    fz_stream *stm)
MUPDF_WRAP(mupdf_count_pages, int, -1,
    ret = fz_count_pages(ctx, doc),
    fz_document *doc)
MUPDF_WRAP(mupdf_layout_document, void*, NULL,
    { fz_layout_document(ctx, doc, w, h, em); ret = (void*) -1; },
    fz_document *doc, float w, float h, float em)
MUPDF_WRAP(mupdf_load_outline, fz_outline*, NULL,
    ret = fz_load_outline(ctx, doc),
    fz_document *doc)
MUPDF_WRAP(mupdf_load_page, fz_page*, NULL,
    ret = fz_load_page(ctx, doc, pageno),
    fz_document *doc, int pageno)
MUPDF_WRAP(mupdf_new_stext_page_from_page, fz_stext_page*, NULL,
    ret = fz_new_stext_page_from_page(ctx, page, options),
    fz_page *page, const fz_stext_options *options)
MUPDF_WRAP(mupdf_new_text_device, fz_device*, NULL,
    ret = fz_new_stext_device(ctx, page, options),
    fz_stext_page *page, const fz_stext_options *options)
MUPDF_WRAP(mupdf_new_bbox_device, fz_device*, NULL,
    ret = fz_new_bbox_device(ctx, rectp),
    fz_rect *rectp)
MUPDF_WRAP(mupdf_new_draw_device, fz_device*, NULL,
    ret = fz_new_draw_device(ctx, transform, dest),
    const fz_matrix *transform, fz_pixmap *dest)
MUPDF_WRAP(mupdf_run_page, void*, NULL,
    { fz_run_page(ctx, page, dev, transform, cookie); ret = (void*) -1; },
    fz_page *page, fz_device *dev, const fz_matrix *transform, fz_cookie *cookie)
MUPDF_WRAP(mupdf_pdf_save_document, void*, NULL,
    { pdf_save_document(ctx, doc, filename, opts); ret = (void*) -1; },
    pdf_document *doc, const char *filename, pdf_write_options *opts)
MUPDF_WRAP(mupdf_new_pixmap, fz_pixmap*, NULL,
    ret = fz_new_pixmap(ctx, cs, w, h, seps, alpha),
    fz_colorspace *cs, int w, int h, fz_separations *seps, int alpha)
MUPDF_WRAP(mupdf_new_pixmap_with_bbox, fz_pixmap*, NULL,
    ret = fz_new_pixmap_with_bbox(ctx, cs, bbox, seps, alpha),
    fz_colorspace *cs, const fz_irect *bbox, fz_separations *seps, int alpha)
MUPDF_WRAP(mupdf_new_pixmap_with_data, fz_pixmap*, NULL,
    ret = fz_new_pixmap_with_data(ctx, cs, w, h, seps, alpha, stride, samples),
    fz_colorspace *cs, int w, int h, fz_separations *seps, int alpha, int stride, unsigned char *samples)
MUPDF_WRAP(mupdf_new_pixmap_with_bbox_and_data, fz_pixmap*, NULL,
    ret = fz_new_pixmap_with_bbox_and_data(ctx, cs, rect, seps, alpha, samples),
    fz_colorspace *cs, const fz_irect *rect, fz_separations *seps, int alpha, unsigned char *samples)
MUPDF_WRAP(mupdf_load_links, fz_link*, NULL,
    ret = fz_load_links(ctx, page),
    fz_page *page)
MUPDF_WRAP(mupdf_pdf_create_annot, pdf_annot*, NULL,
    ret = pdf_create_annot(ctx,  page, type),
    pdf_page *page, enum pdf_annot_type type)
MUPDF_WRAP(mupdf_pdf_set_annot_quad_points, void*, NULL,
    { pdf_set_annot_quad_points(ctx, annot, n, v); ret = (void*) -1; },
     pdf_annot *annot, int n, const float *v)
MUPDF_WRAP(mupdf_pdf_set_text_annot_position, void*, NULL,
    { pdf_set_text_annot_position(ctx, annot, pt); ret = (void*) -1; },
    pdf_annot *annot, fz_point pt)
MUPDF_WRAP(mupdf_pdf_set_markup_appearance, void*, NULL,
    { pdf_set_markup_appearance(ctx, doc, annot, color, alpha, line_thickness, line_height); ret = (void*) -1; },
    pdf_document *doc, pdf_annot *annot, float color[3], float alpha, float line_thickness, float line_height)
MUPDF_WRAP(mupdf_get_pixmap_from_image, fz_pixmap*, NULL,
    ret = fz_get_pixmap_from_image(ctx, image, subarea, trans, w, h),
    fz_image *image, const fz_irect *subarea, fz_matrix *trans, int *w, int *h)
MUPDF_WRAP(mupdf_save_pixmap_as_png, void*, NULL,
    { fz_save_pixmap_as_png(ctx, pixmap, filename); ret = (void*) -1; },
    fz_pixmap *pixmap, const char *filename)
MUPDF_WRAP(mupdf_new_image_from_buffer, fz_image*, NULL,
    ret = fz_new_image_from_buffer(ctx, buffer),
    fz_buffer *buffer)
MUPDF_WRAP(mupdf_new_buffer_from_shared_data, fz_buffer*, NULL,
    ret = fz_new_buffer_from_shared_data(ctx, data, size),
    const unsigned char *data, size_t size)
MUPDF_WRAP(mupdf_drop_buffer, void*, NULL,
    { fz_drop_buffer(ctx, buf); ret = (void*) -1; },
    fz_buffer *buf)

