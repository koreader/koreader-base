-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
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
  unsigned ignore_adler32;
  unsigned ignore_nlen;
  size_t max_output_size;
  unsigned (*custom_zlib)(unsigned char **, size_t *, const unsigned char *, size_t, const LodePNGDecompressSettings *);
  unsigned (*custom_inflate)(unsigned char **, size_t *, const unsigned char *, size_t, const LodePNGDecompressSettings *);
  const void *custom_context;
};
struct LodePNGDecoderSettings {
  LodePNGDecompressSettings zlibsettings;
  unsigned ignore_crc;
  unsigned ignore_critical;
  unsigned ignore_end;
  unsigned color_convert;
};
typedef struct LodePNGDecoderSettings LodePNGDecoderSettings;
enum LodePNGFilterStrategy {
  LFS_ZERO = 0,
  LFS_ONE = 1,
  LFS_TWO = 2,
  LFS_THREE = 3,
  LFS_FOUR = 4,
  LFS_MINSUM,
  LFS_ENTROPY,
  LFS_BRUTE_FORCE,
  LFS_PREDEFINED,
};
typedef enum LodePNGFilterStrategy LodePNGFilterStrategy;
typedef struct LodePNGCompressSettings LodePNGCompressSettings;
struct LodePNGCompressSettings {
  unsigned btype;
  unsigned use_lz77;
  unsigned windowsize;
  unsigned minmatch;
  unsigned nicematch;
  unsigned lazymatching;
  unsigned (*custom_zlib)(unsigned char **, size_t *, const unsigned char *, size_t, const LodePNGCompressSettings *);
  unsigned (*custom_deflate)(unsigned char **, size_t *, const unsigned char *, size_t, const LodePNGCompressSettings *);
  const void *custom_context;
};
struct LodePNGEncoderSettings {
  LodePNGCompressSettings zlibsettings;
  unsigned auto_convert;
  unsigned filter_palette_zero;
  LodePNGFilterStrategy filter_strategy;
  const unsigned char *predefined_filters;
  unsigned force_palette;
};
typedef struct LodePNGEncoderSettings LodePNGEncoderSettings;
struct LodePNGColorMode {
  LodePNGColorType colortype;
  unsigned bitdepth;
  unsigned char *palette;
  size_t palettesize;
  unsigned key_defined;
  unsigned key_r;
  unsigned key_g;
  unsigned key_b;
};
typedef struct LodePNGColorMode LodePNGColorMode;
struct LodePNGInfo {
  unsigned compression_method;
  unsigned filter_method;
  unsigned interlace_method;
  LodePNGColorMode color;
};
typedef struct LodePNGInfo LodePNGInfo;
struct LodePNGState {
  LodePNGDecoderSettings decoder;
  LodePNGEncoderSettings encoder;
  LodePNGColorMode info_raw;
  LodePNGInfo info_png;
  unsigned error;
};
typedef struct LodePNGState LodePNGState;
const char *lodepng_error_text(unsigned code);
unsigned lodepng_decode32_file(unsigned char **out, unsigned *w, unsigned *h, const char *filename);
unsigned lodepng_decode32(unsigned char **out, unsigned *w, unsigned *h, const unsigned char *in, size_t insize);
unsigned lodepng_decode24_file(unsigned char **out, unsigned *w, unsigned *h, const char *filename);
unsigned lodepng_decode24(unsigned char **out, unsigned *w, unsigned *h, const unsigned char *in, size_t insize);
unsigned lodepng_decode_memory(unsigned char **out, unsigned *w, unsigned *h, const unsigned char *in, size_t insize, LodePNGColorType colortype, unsigned bitdepth);
unsigned lodepng_decode_file(unsigned char **out, unsigned *w, unsigned *h, const char *filename, LodePNGColorType colortype, unsigned bitdepth);
unsigned lodepng_encode32_file(const char *filename, const unsigned char *image, unsigned w, unsigned h);
unsigned lodepng_encode_file(const char *filename, const unsigned char *image, unsigned w, unsigned h, LodePNGColorType colortype, unsigned bitdepth);
void lodepng_state_init(LodePNGState *state);
void lodepng_state_cleanup(LodePNGState *state);
void lodepng_state_copy(LodePNGState *dest, const LodePNGState *source);
unsigned lodepng_decode(unsigned char **out, unsigned *w, unsigned *h, LodePNGState *state, const unsigned char *in, size_t insize);
unsigned lodepng_inspect(unsigned *w, unsigned *h, LodePNGState *state, const unsigned char *in, size_t insize);
unsigned lodepng_encode(unsigned char **out, size_t *outsize, const unsigned char *image, unsigned w, unsigned h, LodePNGState *state);
]]
