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

#include <math.h>
#include <mupdf/fitz.h>
#include <mupdf/pdf.h>

// Symbol visibility
#define DLL_PUBLIC __attribute__((visibility("default")))
#define DLL_LOCAL  __attribute__((visibility("hidden")))

DLL_PUBLIC fz_alloc_context* mupdf_get_my_alloc_context();
DLL_PUBLIC int mupdf_get_cache_size();
DLL_PUBLIC int mupdf_error_code(fz_context *ctx);
DLL_PUBLIC char* mupdf_error_message(fz_context *ctx);

DLL_PUBLIC fz_matrix *mupdf_fz_scale(fz_matrix *m, float sx, float sy);
DLL_PUBLIC fz_matrix *mupdf_fz_translate(fz_matrix *m, float tx, float ty);
DLL_PUBLIC fz_matrix *mupdf_fz_pre_rotate(fz_matrix *m, float theta);
DLL_PUBLIC fz_matrix *mupdf_fz_pre_translate(fz_matrix *m, float tx, float ty);
DLL_PUBLIC fz_rect *mupdf_fz_transform_rect(fz_rect *r, const fz_matrix *m);
DLL_PUBLIC fz_irect *mupdf_fz_round_rect(fz_irect *ir, const fz_rect *r);
DLL_PUBLIC fz_rect *mupdf_fz_union_rect(fz_rect *a, const fz_rect *b);
DLL_PUBLIC fz_rect *mupdf_fz_rect_from_quad(fz_rect *r, const fz_quad *q);
DLL_PUBLIC fz_rect *mupdf_fz_bound_page(fz_context *ctx, fz_page *page, fz_rect *r);

// this will turn the wrappers defined below into their declarations
#define MUPDF_WRAP(wrapper_name, ret_type, failure_value, call, ...) \
    DLL_PUBLIC ret_type wrapper_name(fz_context *ctx, ##__VA_ARGS__);

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
        ret_type ret = failure_value; \
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
MUPDF_WRAP(mupdf_new_bbox_device, fz_device*, NULL,
    ret = fz_new_bbox_device(ctx, rectp),
    fz_rect *rectp)
MUPDF_WRAP(mupdf_new_draw_device, fz_device*, NULL,
    ret = fz_new_draw_device(ctx, transform ? *transform : fz_identity, dest),
    const fz_matrix *transform, fz_pixmap *dest)
MUPDF_WRAP(mupdf_run_page, void*, NULL,
    { fz_run_page(ctx, page, dev, *transform, cookie); ret = (void*) -1; },
    fz_page *page, fz_device *dev, const fz_matrix *transform, fz_cookie *cookie)
MUPDF_WRAP(mupdf_pdf_save_document, void*, NULL,
    { pdf_save_document(ctx, doc, filename, opts); ret = (void*) -1; },
    pdf_document *doc, const char *filename, pdf_write_options *opts)
MUPDF_WRAP(mupdf_new_pixmap_with_bbox, fz_pixmap*, NULL,
    ret = fz_new_pixmap_with_bbox(ctx, cs, *bbox, seps, alpha),
    fz_colorspace *cs, const fz_irect *bbox, fz_separations *seps, int alpha)
MUPDF_WRAP(mupdf_new_pixmap_with_data, fz_pixmap*, NULL,
    ret = fz_new_pixmap_with_data(ctx, cs, w, h, seps, alpha, stride, samples),
    fz_colorspace *cs, int w, int h, fz_separations *seps, int alpha, int stride, unsigned char *samples)
MUPDF_WRAP(mupdf_new_pixmap_with_bbox_and_data, fz_pixmap*, NULL,
    ret = fz_new_pixmap_with_bbox_and_data(ctx, cs, *rect, seps, alpha, samples),
    fz_colorspace *cs, const fz_irect *rect, fz_separations *seps, int alpha, unsigned char *samples)
MUPDF_WRAP(mupdf_load_links, fz_link*, NULL,
    ret = fz_load_links(ctx, page),
    fz_page *page)
MUPDF_WRAP(mupdf_fz_resolve_link, fz_location*, NULL,
    { *loc = fz_resolve_link(ctx, doc, uri, xp, yp);
      if (xp && isnan(*xp)) *xp = 0.0;
      if (yp && isnan(*yp)) *yp = 0.0;
      ret = loc; },
      fz_document *doc, const char *uri, float *xp, float *yp, fz_location *loc)
MUPDF_WRAP(mupdf_fz_page_number_from_location, int, -1,
    ret = fz_page_number_from_location(ctx, doc, *loc),
    fz_document *doc, fz_location *loc)
MUPDF_WRAP(mupdf_fz_location_from_page_number, void *, NULL,
    { *location = fz_location_from_page_number(ctx, doc, number); ret = (void*) -1; },
    fz_document *doc, fz_location *location, int number)
MUPDF_WRAP(mupdf_pdf_create_annot, pdf_annot*, NULL,
    ret = pdf_create_annot(ctx, page, type),
    pdf_page *page, enum pdf_annot_type type)
MUPDF_WRAP(mupdf_pdf_delete_annot, void*, NULL,
    { pdf_delete_annot(ctx, page, annot); ret = (void*) -1; },
    pdf_page *page, pdf_annot *annot)
MUPDF_WRAP(mupdf_pdf_set_annot_quad_points, void*, NULL,
    { pdf_set_annot_quad_points(ctx, annot, n, qv); ret = (void*) -1; },
     pdf_annot *annot, int n, const fz_quad *qv)
MUPDF_WRAP(mupdf_pdf_set_annot_contents, void*, NULL,
    { pdf_set_annot_contents(ctx, annot, text); ret = (void*) -1; },
     pdf_annot *annot, const char *text)
MUPDF_WRAP(mupdf_pdf_first_annot, pdf_annot*, NULL,
     ret = pdf_first_annot(ctx, page),
     pdf_page *page)
MUPDF_WRAP(mupdf_pdf_next_annot, pdf_annot*, NULL,
     ret = pdf_next_annot(ctx, annot),
     pdf_annot *annot)
MUPDF_WRAP(mupdf_pdf_annot_quad_point_count, int, -1,
     ret = pdf_annot_quad_point_count(ctx, annot),
     pdf_annot *annot)
MUPDF_WRAP(mupdf_pdf_annot_quad_point, void*, NULL,
    { *qv = pdf_annot_quad_point(ctx, annot, i); ret = (void*) -1; },
     pdf_annot *annot, int i, fz_quad *qv)
MUPDF_WRAP(mupdf_pdf_set_annot_color, void*, NULL,
    { pdf_set_annot_color(ctx, annot, n, color); ret = (void*) -1; },
    pdf_annot *annot, int n, const float color[4])
MUPDF_WRAP(mupdf_pdf_set_annot_opacity, void*, NULL,
    { pdf_set_annot_opacity(ctx, annot, opacity); ret = (void*) -1; },
    pdf_annot *annot, float opacity)
MUPDF_WRAP(mupdf_get_pixmap_from_image, fz_pixmap*, NULL,
    ret = fz_get_pixmap_from_image(ctx, image, subarea, trans, w, h),
    fz_image *image, const fz_irect *subarea, fz_matrix *trans, int *w, int *h)
MUPDF_WRAP(mupdf_convert_pixmap, fz_pixmap*, NULL,
    ret = fz_convert_pixmap(ctx, pix, ds, prf, default_cs, color_params, keep_alpha),
    const fz_pixmap *pix, fz_colorspace *ds, fz_colorspace *prf, fz_default_colorspaces *default_cs, fz_color_params color_params, int keep_alpha)
MUPDF_WRAP(mupdf_new_image_from_buffer, fz_image*, NULL,
    ret = fz_new_image_from_buffer(ctx, buffer),
    fz_buffer *buffer)
MUPDF_WRAP(mupdf_new_buffer_from_shared_data, fz_buffer*, NULL,
    ret = fz_new_buffer_from_shared_data(ctx, data, size),
    const unsigned char *data, size_t size)
MUPDF_WRAP(mupdf_drop_buffer, void*, NULL,
    { fz_drop_buffer(ctx, buf); ret = (void*) -1; },
    fz_buffer *buf)

