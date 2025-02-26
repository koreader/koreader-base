-- Automatically generated with ffi-cdecl.

local ffi = require("ffi")

ffi.cdef[[
enum LodePNGColorType {
  LCT_GREY = 0,
  LCT_RGB = 2,
  LCT_PALETTE = 3,
  LCT_GREY_ALPHA = 4,
  LCT_RGBA = 6,
  LCT_MAX_OCTET_VALUE = 255,
};
typedef enum LodePNGColorType LodePNGColorType;
typedef struct LodePNGDecompressSettings LodePNGDecompressSettings;
struct LodePNGDecompressSettings {
  unsigned int ignore_adler32;
  unsigned int ignore_nlen;
  size_t max_output_size;
  unsigned int (*custom_zlib)(unsigned char **, size_t *, const unsigned char *, size_t, const LodePNGDecompressSettings *);
  unsigned int (*custom_inflate)(unsigned char **, size_t *, const unsigned char *, size_t, const LodePNGDecompressSettings *);
  const void *custom_context;
};
struct LodePNGDecoderSettings {
  LodePNGDecompressSettings zlibsettings;
  unsigned int ignore_crc;
  unsigned int ignore_critical;
  unsigned int ignore_end;
  unsigned int color_convert;
};
typedef struct LodePNGDecoderSettings LodePNGDecoderSettings;
enum LodePNGFilterStrategy {
  LFS_ZERO = 0,
  LFS_ONE = 1,
  LFS_TWO = 2,
  LFS_THREE = 3,
  LFS_FOUR = 4,
  LFS_MINSUM = 5,
  LFS_ENTROPY = 6,
  LFS_BRUTE_FORCE = 7,
  LFS_PREDEFINED = 8,
};
typedef enum LodePNGFilterStrategy LodePNGFilterStrategy;
typedef struct LodePNGCompressSettings LodePNGCompressSettings;
struct LodePNGCompressSettings {
  unsigned int btype;
  unsigned int use_lz77;
  unsigned int windowsize;
  unsigned int minmatch;
  unsigned int nicematch;
  unsigned int lazymatching;
  unsigned int (*custom_zlib)(unsigned char **, size_t *, const unsigned char *, size_t, const LodePNGCompressSettings *);
  unsigned int (*custom_deflate)(unsigned char **, size_t *, const unsigned char *, size_t, const LodePNGCompressSettings *);
  const void *custom_context;
};
struct LodePNGEncoderSettings {
  LodePNGCompressSettings zlibsettings;
  unsigned int auto_convert;
  unsigned int filter_palette_zero;
  LodePNGFilterStrategy filter_strategy;
  const unsigned char *predefined_filters;
  unsigned int force_palette;
};
typedef struct LodePNGEncoderSettings LodePNGEncoderSettings;
struct LodePNGColorMode {
  LodePNGColorType colortype;
  unsigned int bitdepth;
  unsigned char *palette;
  size_t palettesize;
  unsigned int key_defined;
  unsigned int key_r;
  unsigned int key_g;
  unsigned int key_b;
};
typedef struct LodePNGColorMode LodePNGColorMode;
struct LodePNGInfo {
  unsigned int compression_method;
  unsigned int filter_method;
  unsigned int interlace_method;
  LodePNGColorMode color;
};
typedef struct LodePNGInfo LodePNGInfo;
struct LodePNGState {
  LodePNGDecoderSettings decoder;
  LodePNGEncoderSettings encoder;
  LodePNGColorMode info_raw;
  LodePNGInfo info_png;
  unsigned int error;
};
typedef struct LodePNGState LodePNGState;
const char *lodepng_error_text(unsigned int);
unsigned int lodepng_decode32_file(unsigned char **, unsigned int *, unsigned int *, const char *);
unsigned int lodepng_decode32(unsigned char **, unsigned int *, unsigned int *, const unsigned char *, size_t);
unsigned int lodepng_decode24_file(unsigned char **, unsigned int *, unsigned int *, const char *);
unsigned int lodepng_decode24(unsigned char **, unsigned int *, unsigned int *, const unsigned char *, size_t);
unsigned int lodepng_decode_memory(unsigned char **, unsigned int *, unsigned int *, const unsigned char *, size_t, LodePNGColorType, unsigned int);
unsigned int lodepng_decode_file(unsigned char **, unsigned int *, unsigned int *, const char *, LodePNGColorType, unsigned int);
unsigned int lodepng_encode32_file(const char *, const unsigned char *, unsigned int, unsigned int);
unsigned int lodepng_encode_file(const char *, const unsigned char *, unsigned int, unsigned int, LodePNGColorType, unsigned int);
void lodepng_state_init(LodePNGState *);
void lodepng_state_cleanup(LodePNGState *);
void lodepng_state_copy(LodePNGState *, const LodePNGState *);
unsigned int lodepng_decode(unsigned char **, unsigned int *, unsigned int *, LodePNGState *, const unsigned char *, size_t);
unsigned int lodepng_inspect(unsigned int *, unsigned int *, LodePNGState *, const unsigned char *, size_t);
unsigned int lodepng_encode(unsigned char **, size_t *, const unsigned char *, unsigned int, unsigned int, LodePNGState *);
]]
