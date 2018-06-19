local ffi = require("ffi")

ffi.cdef[[
typedef enum LodePNGColorType LodePNGColorType;
enum LodePNGColorType {
  LCT_GREY = 0,
  LCT_RGB = 2,
  LCT_PALETTE = 3,
  LCT_GREY_ALPHA = 4,
  LCT_RGBA = 6,
};
const char *lodepng_error_text(unsigned int);
unsigned int lodepng_decode32_file(unsigned char **, unsigned int *, unsigned int *, const char *);
unsigned int lodepng_decode32(unsigned char **, unsigned int *, unsigned int *, const unsigned char *, unsigned int);
unsigned int lodepng_decode24_file(unsigned char **, unsigned int *, unsigned int *, const char *);
unsigned int lodepng_decode24(unsigned char **, unsigned int *, unsigned int *, const unsigned char *, unsigned int);
unsigned int lodepng_decode_memory(unsigned char **, unsigned int *, unsigned int *, const unsigned char *, unsigned int, LodePNGColorType, unsigned int);
unsigned int lodepng_decode_file(unsigned char **, unsigned int *, unsigned int *, const char *, LodePNGColorType, unsigned int);
unsigned int lodepng_encode32_file(const char *, const unsigned char *, unsigned int, unsigned int);
]]
