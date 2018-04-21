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
struct ExtensionBlock {
    int ByteCount;
    GifByteType *Bytes;
    int Function;
};
typedef struct ExtensionBlock ExtensionBlock;
struct GraphicsControlBlock {
    int DisposalMode;
    bool UserInputFlag;
    int DelayTime;
    int TransparentColor;
};
typedef struct GraphicsControlBlock GraphicsControlBlock;
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
int DGifSavedExtensionToGCB(GifFileType *, int, GraphicsControlBlock *);
static const int DISPOSAL_UNSPECIFIED = 0;
static const int DISPOSE_DO_NOT       = 1;
static const int DISPOSE_BACKGROUND   = 2;
static const int DISPOSE_PREVIOUS     = 3;
static const int NO_TRANSPARENT_COLOR = -1;
typedef int (*GifInputFunc) (GifFileType *, GifByteType *, int);
GifFileType *DGifOpen(void *, GifInputFunc, int *);
]]
