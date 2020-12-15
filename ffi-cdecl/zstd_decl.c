#include <zstd.h>

#include "ffi-cdecl.h"

// c.f., https://facebook.github.io/zstd/zstd_manual.html
cdecl_func(ZSTD_versionNumber)
cdecl_func(ZSTD_versionString)

// Simple API
cdecl_const(ZSTD_CLEVEL_DEFAULT)
cdecl_func(ZSTD_compress)

cdecl_func(ZSTD_decompress)
cdecl_const(ZSTD_CONTENTSIZE_UNKNOWN)
cdecl_const(ZSTD_CONTENTSIZE_ERROR)
cdecl_func(ZSTD_getFrameContentSize)
cdecl_func(ZSTD_findFrameCompressedSize)

//cdecl_func(ZSTD_COMPRESSBOUND)
cdecl_func(ZSTD_compressBound)
cdecl_func(ZSTD_isError)
cdecl_func(ZSTD_getErrorName)
cdecl_func(ZSTD_minCLevel)
cdecl_func(ZSTD_maxCLevel)

// Explicit context
cdecl_struct(ZSTD_CCtx_s)
cdecl_type(ZSTD_CCtx)
cdecl_func(ZSTD_createCCtx)
cdecl_func(ZSTD_freeCCtx)
cdecl_func(ZSTD_compressCCtx)

cdecl_struct(ZSTD_DCtx_s)
cdecl_type(ZSTD_DCtx)
cdecl_func(ZSTD_createDCtx)
cdecl_func(ZSTD_freeDCtx)
cdecl_func(ZSTD_decompressDCtx)

// Advanced compression API
cdecl_type(ZSTD_strategy)
cdecl_type(ZSTD_cParameter)
cdecl_type(ZSTD_bounds)
cdecl_func(ZSTD_cParam_getBounds)
cdecl_func(ZSTD_CCtx_setParameter)
cdecl_func(ZSTD_CCtx_setPledgedSrcSize)
cdecl_type(ZSTD_ResetDirective)
cdecl_func(ZSTD_CCtx_reset)
cdecl_func(ZSTD_compress2)

// Advanced decompression API
cdecl_type(ZSTD_dParameter)
cdecl_func(ZSTD_dParam_getBounds)
cdecl_func(ZSTD_DCtx_setParameter)
cdecl_func(ZSTD_DCtx_reset)

// Streaming API
cdecl_struct(ZSTD_inBuffer_s)
cdecl_type(ZSTD_inBuffer)
cdecl_struct(ZSTD_outBuffer_s)
cdecl_type(ZSTD_outBuffer)

cdecl_type(ZSTD_EndDirective)
cdecl_func(ZSTD_compressStream2)
cdecl_func(ZSTD_CStreamInSize)
cdecl_func(ZSTD_CStreamOutSize)

cdecl_func(ZSTD_decompressStream)
cdecl_func(ZSTD_DStreamInSize)
cdecl_func(ZSTD_DStreamOutSize)

// Simple dictionary API
cdecl_func(ZSTD_compress_usingDict)
cdecl_func(ZSTD_decompress_usingDict)

// Bulk processing dictionary API
cdecl_struct(ZSTD_CDict_s)
cdecl_type(ZSTD_CDict)
cdecl_func(ZSTD_createCDict)
cdecl_func(ZSTD_freeCDict)
cdecl_func(ZSTD_compress_usingCDict)

cdecl_struct(ZSTD_DDict_s)
cdecl_type(ZSTD_DDict)
cdecl_func(ZSTD_createDDict)
cdecl_func(ZSTD_freeDDict)
cdecl_func(ZSTD_decompress_usingDDict)

cdecl_func(ZSTD_getDictID_fromDict)
cdecl_func(ZSTD_getDictID_fromDDict)
cdecl_func(ZSTD_getDictID_fromFrame)

// Advanced dictionary and prefix API
cdecl_func(ZSTD_CCtx_loadDictionary)
cdecl_func(ZSTD_CCtx_refCDict)
cdecl_func(ZSTD_CCtx_refPrefix)
cdecl_func(ZSTD_DCtx_loadDictionary)
cdecl_func(ZSTD_DCtx_refDDict)
cdecl_func(ZSTD_DCtx_refPrefix)

cdecl_func(ZSTD_sizeof_CCtx)
cdecl_func(ZSTD_sizeof_DCtx)
cdecl_func(ZSTD_sizeof_CDict)
cdecl_func(ZSTD_sizeof_DDict)
