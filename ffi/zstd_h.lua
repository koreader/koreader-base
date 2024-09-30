local ffi = require("ffi")

ffi.cdef[[
static const int ZSTD_CLEVEL_DEFAULT = 3;
size_t ZSTD_compress(void *, size_t, const void *, size_t, int);
size_t ZSTD_decompress(void *, size_t, const void *, size_t);
long long unsigned int ZSTD_getFrameContentSize(const void *, size_t);
size_t ZSTD_compressBound(size_t);
unsigned int ZSTD_isError(size_t);
const char *ZSTD_getErrorName(size_t);
typedef struct ZSTD_DCtx_s ZSTD_DCtx;
typedef enum {
  ZSTD_reset_session_only = 1,
  ZSTD_reset_parameters = 2,
  ZSTD_reset_session_and_parameters = 3,
} ZSTD_ResetDirective;
ZSTD_DCtx *ZSTD_createDCtx(void);
size_t ZSTD_freeDCtx(ZSTD_DCtx *);
size_t ZSTD_decompressDCtx(ZSTD_DCtx *, void *, size_t, const void *, size_t);
size_t ZSTD_DCtx_reset(ZSTD_DCtx *, ZSTD_ResetDirective);
]]
