-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
static const unsigned ZSTD_CLEVEL_DEFAULT = 3;
size_t ZSTD_compress(void *dst, size_t dstCapacity, const void *src, size_t srcSize, int compressionLevel);
size_t ZSTD_decompress(void *dst, size_t dstCapacity, const void *src, size_t compressedSize);
unsigned long long ZSTD_getFrameContentSize(const void *src, size_t srcSize);
size_t ZSTD_compressBound(size_t srcSize);
unsigned ZSTD_isError(size_t result);
const char *ZSTD_getErrorName(size_t result);
typedef struct ZSTD_DCtx_s ZSTD_DCtx;
typedef enum {
  ZSTD_reset_session_only = 1,
  ZSTD_reset_parameters = 2,
  ZSTD_reset_session_and_parameters = 3,
} ZSTD_ResetDirective;
ZSTD_DCtx *ZSTD_createDCtx(void);
size_t ZSTD_freeDCtx(ZSTD_DCtx *dctx);
size_t ZSTD_decompressDCtx(ZSTD_DCtx *dctx, void *dst, size_t dstCapacity, const void *src, size_t srcSize);
size_t ZSTD_DCtx_reset(ZSTD_DCtx *dctx, ZSTD_ResetDirective reset);
]]
