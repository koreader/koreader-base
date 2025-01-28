#define K2PDFOPT_EXPORT
#define WILLUS_EXPORT

#include "koptcrop.h"
#include "koptimize.h"
#include "koptocr.h"
#include "koptreflow.h"

#include "ffi-cdecl.h"

// FIXME: only declared in `koptocr.c`…
PIX* bitmap2pix(WILLUSBITMAP *src, int x, int y, int w, int h);

cdecl_type(BBox)
cdecl_type(BOXA)
cdecl_type(NUMA)
cdecl_type(PIX)
cdecl_type(POINT2D)
cdecl_type(WRECTMAP)
cdecl_type(WRECTMAPS)
cdecl_type(WILLUSBITMAP)
cdecl_type(HYPHENINFO)
cdecl_type(TEXTROW)
cdecl_type(TEXTROWS)
cdecl_type(BMPREGION)
cdecl_type(PAGEREGION)
cdecl_type(PAGEREGIONS)
cdecl_struct(KOPTContext)
cdecl_type(KOPTContext)

cdecl_func(bmp_init)
cdecl_func(bmp_free)
cdecl_func(bmp_alloc)
cdecl_func(bmp_bytewidth)
cdecl_func(bmp_copy)
cdecl_func(wrectmaps_init)
cdecl_func(wrectmaps_free)
cdecl_func(wrectmap_inside)
cdecl_func(k2pdfopt_get_reflowed_word_boxes)
cdecl_func(k2pdfopt_get_native_word_boxes)
cdecl_func(k2pdfopt_tocr_single_word)
cdecl_func(k2pdfopt_reflow_bmp)
cdecl_func(k2pdfopt_tocr_end)
cdecl_func(k2pdfopt_crop_bmp)
cdecl_func(k2pdfopt_optimize_bmp)
cdecl_func(pixmap_to_bmp)
cdecl_func(bitmap2pix)
