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
  /**
   * 4:4:4 chrominance subsampling (no chrominance subsampling).  The JPEG or
   * YUV image will contain one chrominance component for every pixel in the
   * source image.
   */
  TJSAMP_444 = 0,
  /**
   * 4:2:2 chrominance subsampling.  The JPEG or YUV image will contain one
   * chrominance component for every 2x1 block of pixels in the source image.
   */
  TJSAMP_422,
  /**
   * 4:2:0 chrominance subsampling.  The JPEG or YUV image will contain one
   * chrominance component for every 2x2 block of pixels in the source image.
   */
  TJSAMP_420,
  /**
   * Grayscale.  The JPEG or YUV image will contain no chrominance components.
   */
  TJSAMP_GRAY,
  /**
   * 4:4:0 chrominance subsampling.  The JPEG or YUV image will contain one
   * chrominance component for every 1x2 block of pixels in the source image.
   *
   * @note 4:4:0 subsampling is not fully accelerated in libjpeg-turbo.
   */
  TJSAMP_440,
  /**
   * 4:1:1 chrominance subsampling.  The JPEG or YUV image will contain one
   * chrominance component for every 4x1 block of pixels in the source image.
   * JPEG images compressed with 4:1:1 subsampling will be almost exactly the
   * same size as those compressed with 4:2:0 subsampling, and in the
   * aggregate, both subsampling methods produce approximately the same
   * perceptual quality.  However, 4:1:1 is better able to reproduce sharp
   * horizontal features.
   *
   * @note 4:1:1 subsampling is not fully accelerated in libjpeg-turbo.
   */
  TJSAMP_411
};

int tjDestroy(tjhandle);
tjhandle tjInitDecompress(void);
int tjDecompressHeader2(tjhandle, unsigned char *, long unsigned int, int *, int *, int *);
int tjDecompress2(tjhandle, const unsigned char *, long unsigned int, unsigned char *, int, int, int, int, int);
int tjDecompressToYUV(tjhandle, unsigned char *, long unsigned int, unsigned char *, int);

tjhandle tjInitCompress(void);
void tjFree(unsigned char *buffer);
int tjCompress2(tjhandle handle, const unsigned char *srcBuf,
                          int width, int pitch, int height, int pixelFormat,
                          unsigned char **jpegBuf, unsigned long *jpegSize,
                          int jpegSubsamp, int jpegQual, int flags);

/*int tjCompress2(tjhandle, const unsigned char *,
                          int, int, int, int,
                          unsigned char **, unsigned long *,
                          int, int, int);
*/

]]
