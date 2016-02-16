#include <lodepng.h>

#include "ffi-cdecl.h"

cdecl_type(LodePNGColorType)
cdecl_enum(LodePNGColorType)
cdecl_func(lodepng_error_text)
cdecl_func(lodepng_decode32_file)
cdecl_func(lodepng_decode32)
cdecl_func(lodepng_decode24_file)
cdecl_func(lodepng_decode24)
cdecl_func(lodepng_decode_memory)
cdecl_func(lodepng_decode_file)
cdecl_func(lodepng_encode32_file)
