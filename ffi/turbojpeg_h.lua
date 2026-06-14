-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
enum TJINIT {
  TJINIT_COMPRESS,
  TJINIT_DECOMPRESS,
  TJINIT_TRANSFORM,
};
enum TJSAMP {
  TJSAMP_444,
  TJSAMP_422,
  TJSAMP_420,
  TJSAMP_GRAY,
  TJSAMP_440,
  TJSAMP_411,
  TJSAMP_441,
  TJSAMP_UNKNOWN = -1,
};
enum TJPF {
  TJPF_RGB,
  TJPF_BGR,
  TJPF_RGBX,
  TJPF_BGRX,
  TJPF_XBGR,
  TJPF_XRGB,
  TJPF_GRAY,
  TJPF_RGBA,
  TJPF_BGRA,
  TJPF_ABGR,
  TJPF_ARGB,
  TJPF_CMYK,
  TJPF_UNKNOWN = -1,
};
enum TJPARAM {
  TJPARAM_STOPONWARNING,
  TJPARAM_BOTTOMUP,
  TJPARAM_NOREALLOC,
  TJPARAM_QUALITY,
  TJPARAM_SUBSAMP,
  TJPARAM_JPEGWIDTH,
  TJPARAM_JPEGHEIGHT,
  TJPARAM_PRECISION,
  TJPARAM_COLORSPACE,
  TJPARAM_FASTUPSAMPLE,
  TJPARAM_FASTDCT,
  TJPARAM_OPTIMIZE,
  TJPARAM_PROGRESSIVE,
  TJPARAM_SCANLIMIT,
  TJPARAM_ARITHMETIC,
  TJPARAM_LOSSLESS,
  TJPARAM_LOSSLESSPSV,
  TJPARAM_LOSSLESSPT,
  TJPARAM_RESTARTBLOCKS,
  TJPARAM_RESTARTROWS,
  TJPARAM_XDENSITY,
  TJPARAM_YDENSITY,
  TJPARAM_DENSITYUNITS,
  TJPARAM_MAXMEMORY,
  TJPARAM_MAXPIXELS,
  TJPARAM_SAVEMARKERS,
};
typedef void *tjhandle;
tjhandle tj3Init(int);
int tj3Set(tjhandle, int, int);
int tj3Get(tjhandle, int);
int tj3Compress8(tjhandle, const unsigned char *, int, int, int, int, unsigned char **, size_t *);
int tj3DecompressHeader(tjhandle, const unsigned char *, size_t);
int tj3Decompress8(tjhandle, const unsigned char *, size_t, unsigned char *, int, int);
void tj3Destroy(tjhandle);
int tj3SaveImage8(tjhandle, const char *, const unsigned char *, int, int, int, int);
void tj3Free(void *);
]]
