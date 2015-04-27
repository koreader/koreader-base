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
MUPDF_WRAP(mupdf_count_pages, int, -1,
    ret = fz_count_pages(ctx, doc),
    fz_document *doc)
MUPDF_WRAP(mupdf_load_outline, fz_outline*, NULL,
    ret = fz_load_outline(ctx, doc),
    fz_document *doc)
MUPDF_WRAP(mupdf_load_page, fz_page*, NULL,
    ret = fz_load_page(ctx, doc, pageno),
    fz_document *doc, int pageno)
MUPDF_WRAP(mupdf_new_text_sheet, fz_text_sheet*, NULL,
    ret = fz_new_text_sheet(ctx))
MUPDF_WRAP(mupdf_new_text_page, fz_text_page*, NULL,
    ret = fz_new_text_page(ctx))
MUPDF_WRAP(mupdf_new_text_device, fz_device*, NULL,
    ret = fz_new_text_device(ctx, sheet, page),
    fz_text_sheet *sheet, fz_text_page *page)
MUPDF_WRAP(mupdf_new_bbox_device, fz_device*, NULL,
    ret = fz_new_bbox_device(ctx, rectp),
    fz_rect *rectp)
MUPDF_WRAP(mupdf_new_draw_device, fz_device*, NULL,
    ret = fz_new_draw_device(ctx, dest),
    fz_pixmap *dest)
MUPDF_WRAP(mupdf_run_page, void*, NULL,
    { fz_run_page(ctx, doc, page, dev, transform, cookie); ret = (void*) -1; },
    fz_document *doc, fz_page *page, fz_device *dev, const fz_matrix *transform, fz_cookie *cookie)
MUPDF_WRAP(mupdf_write_document, void*, NULL,
    { fz_write_document(ctx, doc, filename, opts); ret = (void*) -1; },
    fz_document *doc, char* filename, fz_write_options *opts)
MUPDF_WRAP(mupdf_new_pixmap, fz_pixmap*, NULL,
    ret = fz_new_pixmap(ctx, cs, w, h),
    fz_colorspace *cs, int w, int h)
MUPDF_WRAP(mupdf_new_pixmap_with_bbox, fz_pixmap*, NULL,
    ret = fz_new_pixmap_with_bbox(ctx, cs, bbox),
    fz_colorspace *cs, const fz_irect *bbox)
MUPDF_WRAP(mupdf_new_pixmap_with_data, fz_pixmap*, NULL,
    ret = fz_new_pixmap_with_data(ctx, cs, w, h, samples),
    fz_colorspace *cs, int w, int h, unsigned char *samples)
MUPDF_WRAP(mupdf_new_pixmap_with_bbox_and_data, fz_pixmap*, NULL,
    ret = fz_new_pixmap_with_bbox_and_data(ctx, cs, rect, samples),
    fz_colorspace *cs, const fz_irect *rect, unsigned char *samples)
MUPDF_WRAP(mupdf_load_links, fz_link*, NULL,
    ret = fz_load_links(ctx, doc, page),
    fz_document *doc, fz_page *page)
MUPDF_WRAP(mupdf_pdf_create_annot, pdf_annot*, NULL,
    ret = pdf_create_annot(ctx, doc, page, type),
    pdf_document *doc, pdf_page *page, fz_annot_type type)
MUPDF_WRAP(mupdf_pdf_set_markup_annot_quadpoints, void*, NULL,
    { pdf_set_markup_annot_quadpoints(ctx, doc, annot, qp, n); ret = (void*) -1; },
    pdf_document *doc, pdf_annot *annot, fz_point *qp, int n)
MUPDF_WRAP(mupdf_pdf_set_markup_appearance, void*, NULL,
    { pdf_set_markup_appearance(ctx, doc, annot, color, alpha, line_thickness, line_height); ret = (void*) -1; },
    pdf_document *doc, pdf_annot *annot, float color[3], float alpha, float line_thickness, float line_height)
MUPDF_WRAP(mupdf_new_pixmap_from_image, fz_pixmap*, NULL,
    ret = fz_new_pixmap_from_image(ctx, image, w, h),
    fz_image *image, int w, int h)
MUPDF_WRAP(mupdf_new_image_from_data, fz_image*, NULL,
    ret = fz_new_image_from_data(ctx, data, len),
    unsigned char *data, int len)

