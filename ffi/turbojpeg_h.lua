local ffi = require("ffi")

ffi.cdef[[
typedef void *tjhandle;
enum TJPF {
  TJPF_RGB = 0,
  TJPF_BGR = 1,
  TJPF_RGBX = 2,
  TJPF_BGRX = 3,
  TJPF_XBGR = 4,
  TJPF_XRGB = 5,
  TJPF_GRAY = 6,
  TJPF_RGBA = 7,
  TJPF_BGRA = 8,
  TJPF_ABGR = 9,
  TJPF_ARGB = 10,
  TJPF_CMYK = 11,
  TJPF_UNKNOWN = -1,
};
int tjDestroy(tjhandle);
tjhandle tjInitDecompress(void);
int tjDecompressHeader2(tjhandle, unsigned char *, long unsigned int, int *, int *, int *);
int tjDecompress2(tjhandle, const unsigned char *, long unsigned int, unsigned char *, int, int, int, int, int);
int tjDecompressToYUV(tjhandle, unsigned char *, long unsigned int, unsigned char *, int);
]]
