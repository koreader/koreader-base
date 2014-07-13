#include <mupdf/fitz.h>

#include "ffi-cdecl.h"
#include "ffi-cdecl-luajit.h"

cdecl_type(fz_alloc_context)
cdecl_type(fz_colorspace)
cdecl_type(fz_context)
cdecl_type(fz_store_free_fn)

cdecl_struct(fz_storable_s)
cdecl_type(fz_storable)

cdecl_struct(fz_pixmap_s)
cdecl_type(fz_pixmap)

cdecl_func(fz_new_context_imp)
cdecl_func(fz_new_pixmap)
cdecl_func(fz_convert_pixmap)
cdecl_func(fz_drop_pixmap)
cdecl_func(fz_device_gray)
cdecl_func(fz_free_context)

cdecl_func(fz_load_png)
