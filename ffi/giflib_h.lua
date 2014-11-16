local ffi = require("ffi")

ffi.cdef[[
typedef unsigned char GifByteType;
typedef int GifWord;
struct GifColorType {
  GifByteType Red;
  GifByteType Green;
  GifByteType Blue;
};
typedef struct GifColorType GifColorType;
struct ColorMapObject {
  int ColorCount;
  int BitsPerPixel;
  _Bool SortFlag;
  GifColorType *Colors;
};
typedef struct ColorMapObject ColorMapObject;
struct GifImageDesc {
  GifWord Left;
  GifWord Top;
  GifWord Width;
  GifWord Height;
  _Bool Interlace;
  ColorMapObject *ColorMap;
};
typedef struct GifImageDesc GifImageDesc;
struct SavedImage {
  GifImageDesc ImageDesc;
  GifByteType *RasterBits;
  int ExtensionBlockCount;
  struct ExtensionBlock *ExtensionBlocks;
};
typedef struct SavedImage SavedImage;
struct GifFileType {
  GifWord SWidth;
  GifWord SHeight;
  GifWord SColorResolution;
  GifWord SBackGroundColor;
  GifByteType AspectByte;
  ColorMapObject *SColorMap;
  int ImageCount;
  GifImageDesc Image;
  SavedImage *SavedImages;
  int ExtensionBlockCount;
  struct ExtensionBlock *ExtensionBlocks;
  int Error;
  void *UserData;
  void *Private;
};
typedef struct GifFileType GifFileType;
static const int GIF_OK = 1;
static const int GIF_ERROR = 0;
GifFileType *DGifOpenFileName(const char *, int *);
GifFileType *DGifOpenFileHandle(int, int *);
int DGifCloseFile(GifFileType *, int *);
int DGifSlurp(GifFileType *);
const char *GifErrorString(int);
]]
