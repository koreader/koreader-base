local ffi = require("ffi")

ffi.cdef[[
enum LodePNGColorType {
  LCT_GREY = 0,
  LCT_RGB = 2,
  LCT_PALETTE = 3,
  LCT_GREY_ALPHA = 4,
  LCT_RGBA = 6,
};
typedef enum LodePNGColorType LodePNGColorType;
typedef struct LodePNGDecompressSettings LodePNGDecompressSettings;
struct LodePNGDecompressSettings {
  unsigned int ignore_adler32;
  unsigned int (*custom_zlib)(unsigned char **, unsigned int *, const unsigned char *, unsigned int, const LodePNGDecompressSettings *);
  unsigned int (*custom_inflate)(unsigned char **, unsigned int *, const unsigned char *, unsigned int, const LodePNGDecompressSettings *);
  const void *custom_context;
};
struct LodePNGDecoderSettings {
  LodePNGDecompressSettings zlibsettings;
  unsigned int ignore_crc;
  unsigned int ignore_critical;
  unsigned int ignore_end;
  unsigned int color_convert;
  unsigned int read_text_chunks;
  unsigned int remember_unknown_chunks;
};
typedef struct LodePNGDecoderSettings LodePNGDecoderSettings;
enum LodePNGFilterStrategy {
  LFS_ZERO = 0,
  LFS_MINSUM = 1,
  LFS_ENTROPY = 2,
  LFS_BRUTE_FORCE = 3,
  LFS_PREDEFINED = 4,
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
  unsigned int (*custom_zlib)(unsigned char **, unsigned int *, const unsigned char *, unsigned int, const LodePNGCompressSettings *);
  unsigned int (*custom_deflate)(unsigned char **, unsigned int *, const unsigned char *, unsigned int, const LodePNGCompressSettings *);
  const void *custom_context;
};
struct LodePNGEncoderSettings {
  LodePNGCompressSettings zlibsettings;
  unsigned int auto_convert;
  unsigned int filter_palette_zero;
  LodePNGFilterStrategy filter_strategy;
  const unsigned char *predefined_filters;
  unsigned int force_palette;
  unsigned int add_id;
  unsigned int text_compression;
};
typedef struct LodePNGEncoderSettings LodePNGEncoderSettings;
struct LodePNGColorMode {
  LodePNGColorType colortype;
  unsigned int bitdepth;
  unsigned char *palette;
  unsigned int palettesize;
  unsigned int key_defined;
  unsigned int key_r;
  unsigned int key_g;
  unsigned int key_b;
};
typedef struct LodePNGColorMode LodePNGColorMode;
struct LodePNGTime {
  unsigned int year;
  unsigned int month;
  unsigned int day;
  unsigned int hour;
  unsigned int minute;
  unsigned int second;
};
typedef struct LodePNGTime LodePNGTime;
struct LodePNGInfo {
  unsigned int compression_method;
  unsigned int filter_method;
  unsigned int interlace_method;
  LodePNGColorMode color;
  unsigned int background_defined;
  unsigned int background_r;
  unsigned int background_g;
  unsigned int background_b;
  unsigned int text_num;
  char **text_keys;
  char **text_strings;
  unsigned int itext_num;
  char **itext_keys;
  char **itext_langtags;
  char **itext_transkeys;
  char **itext_strings;
  unsigned int time_defined;
  LodePNGTime time;
  unsigned int phys_defined;
  unsigned int phys_x;
  unsigned int phys_y;
  unsigned int phys_unit;
  unsigned int gama_defined;
  unsigned int gama_gamma;
  unsigned int chrm_defined;
  unsigned int chrm_white_x;
  unsigned int chrm_white_y;
  unsigned int chrm_red_x;
  unsigned int chrm_red_y;
  unsigned int chrm_green_x;
  unsigned int chrm_green_y;
  unsigned int chrm_blue_x;
  unsigned int chrm_blue_y;
  unsigned int srgb_defined;
  unsigned int srgb_intent;
  unsigned int iccp_defined;
  char *iccp_name;
  unsigned char *iccp_profile;
  unsigned int iccp_profile_size;
  unsigned char *unknown_chunks_data[3];
  unsigned int unknown_chunks_size[3];
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
unsigned int lodepng_load_file(unsigned char **, unsigned int *, const char *);
unsigned int lodepng_decode32_file(unsigned char **, unsigned int *, unsigned int *, const char *);
unsigned int lodepng_decode32(unsigned char **, unsigned int *, unsigned int *, const unsigned char *, unsigned int);
unsigned int lodepng_decode24_file(unsigned char **, unsigned int *, unsigned int *, const char *);
unsigned int lodepng_decode24(unsigned char **, unsigned int *, unsigned int *, const unsigned char *, unsigned int);
unsigned int lodepng_decode_memory(unsigned char **, unsigned int *, unsigned int *, const unsigned char *, unsigned int, LodePNGColorType, unsigned int);
unsigned int lodepng_decode_file(unsigned char **, unsigned int *, unsigned int *, const char *, LodePNGColorType, unsigned int);
unsigned int lodepng_encode32_file(const char *, const unsigned char *, unsigned int, unsigned int);
void lodepng_state_init(LodePNGState *);
void lodepng_state_cleanup(LodePNGState *);
void lodepng_state_copy(LodePNGState *, const LodePNGState *);
unsigned int lodepng_decode(unsigned char **, unsigned int *, unsigned int *, LodePNGState *, const unsigned char *, unsigned int);
unsigned int lodepng_inspect(unsigned int *, unsigned int *, LodePNGState *, const unsigned char *, unsigned int);
unsigned int lodepng_encode(unsigned char **, unsigned int *, const unsigned char *, unsigned int, unsigned int, LodePNGState *);
]]
