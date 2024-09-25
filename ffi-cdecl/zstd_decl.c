#include <zstd.h>

#include "ffi-cdecl.h"

cdecl_const(ZSTD_CLEVEL_DEFAULT)

cdecl_func(ZSTD_compress)
cdecl_func(ZSTD_decompress)
cdecl_func(ZSTD_getFrameContentSize)
cdecl_func(ZSTD_compressBound)
cdecl_func(ZSTD_isError)
cdecl_func(ZSTD_getErrorName)

cdecl_type(ZSTD_DCtx)
cdecl_type(ZSTD_ResetDirective)
cdecl_func(ZSTD_createDCtx)
cdecl_func(ZSTD_freeDCtx)
cdecl_func(ZSTD_decompressDCtx)
cdecl_func(ZSTD_DCtx_reset)
