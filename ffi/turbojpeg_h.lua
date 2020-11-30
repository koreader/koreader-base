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
enum TJSAMP {
  TJSAMP_444 = 0,
  TJSAMP_422,
  TJSAMP_420,
  TJSAMP_GRAY,
  TJSAMP_440,
  TJSAMP_411
};

int tjDestroy(tjhandle handle);

tjhandle tjInitDecompress(void);

int tjDecompressHeader2(tjhandle handle, unsigned char *jpegBuf, unsigned long jpegSize,
                        int *width, int *height, int *jpegSubsamp);

int tjDecompressHeader3(tjhandle handle, const unsigned char *jpegBuf, unsigned long jpegSize,
                        int *width, int *height, int *jpegSubsamp, int *jpegColorspace);

int tjDecompress2(tjhandle handle, const unsigned char *jpegBuf, unsigned long jpegSize,
                  unsigned char *dstBuf, int width, int pitch, int height, int pixelFormat,
                  int flags);

int tjDecompressToYUV2(tjhandle handle, const unsigned char *jpegBuf, unsigned long jpegSize,
                       unsigned char *dstBuf, int width, int pad, int height, int flags);

tjhandle tjInitCompress(void);
void tjFree(unsigned char *buffer);
int tjCompress2(tjhandle, const unsigned char *, int, int, int, int, unsigned char **, unsigned long *, int, int, int);
int tjCompress2(tjhandle handle, const unsigned char *srcBuf, int width, int pitch, int height,
                int pixelFormat, unsigned char **jpegBuf, unsigned long *jpegSize, int jpegSubsamp,
                int jpegQual, int flags);

int tjSaveImage(const char *filename, unsigned char *buffer, int width, int pitch, int height,
                int pixelFormat, int flags);
]]

