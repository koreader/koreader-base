local ffi = require("ffi")

ffi.cdef[[
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
};
typedef void *tjhandle;
int tjDestroy(tjhandle);
tjhandle tjInitDecompress(void);
int tjDecompressHeader2(tjhandle, unsigned char *, long unsigned int, int *, int *, int *);
int tjDecompress2(tjhandle, unsigned char *, long unsigned int, unsigned char *, int, int, int, int, int);
int tjDecompressToYUV(tjhandle, unsigned char *, long unsigned int, unsigned char *, int);
]]
