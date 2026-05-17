-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
static const unsigned GIF_OK = 1;
static const unsigned GIF_ERROR = 0;
typedef int GifWord;
typedef unsigned char GifByteType;
typedef struct GifColorType GifColorType;
struct GifColorType {
  GifByteType Red, Green, Blue;
};
typedef struct ColorMapObject ColorMapObject;
struct ColorMapObject {
  int ColorCount;
  int BitsPerPixel;
  bool SortFlag;
  GifColorType *Colors;
};
typedef struct GifImageDesc GifImageDesc;
struct GifImageDesc {
  GifWord Left, Top, Width, Height;
  bool Interlace;
  ColorMapObject *ColorMap;
};
typedef struct ExtensionBlock ExtensionBlock;
struct ExtensionBlock {
  int ByteCount;
  GifByteType *Bytes;
  int Function;
};
typedef struct GraphicsControlBlock GraphicsControlBlock;
struct GraphicsControlBlock {
  int DisposalMode;
  bool UserInputFlag;
  int DelayTime;
  int TransparentColor;
};
typedef struct SavedImage SavedImage;
struct SavedImage {
  GifImageDesc ImageDesc;
  GifByteType *RasterBits;
  int ExtensionBlockCount;
  ExtensionBlock *ExtensionBlocks;
};
typedef struct GifFileType GifFileType;
struct GifFileType {
  GifWord SWidth, SHeight;
  GifWord SColorResolution;
  GifWord SBackGroundColor;
  GifByteType AspectByte;
  ColorMapObject *SColorMap;
  int ImageCount;
  GifImageDesc Image;
  SavedImage *SavedImages;
  int ExtensionBlockCount;
  ExtensionBlock *ExtensionBlocks;
  int Error;
  void *UserData;
  void *Private;
};
GifFileType *DGifOpenFileName(const char *GifFileName, int *Error);
GifFileType *DGifOpenFileHandle(int GifFileHandle, int *Error);
int DGifCloseFile(GifFileType *GifFile, int *ErrorCode);
int DGifSlurp(GifFileType *GifFile);
const char *GifErrorString(int ErrorCode);
int DGifSavedExtensionToGCB(GifFileType *GifFile, int ImageIndex, GraphicsControlBlock *GCB);
static const unsigned DISPOSAL_UNSPECIFIED = 0;
static const unsigned DISPOSE_DO_NOT = 1;
static const unsigned DISPOSE_BACKGROUND = 2;
static const unsigned DISPOSE_PREVIOUS = 3;
static const int NO_TRANSPARENT_COLOR = -1;
typedef int (*InputFunc)(GifFileType *, GifByteType *, int);
GifFileType *DGifOpen(void *userPtr, InputFunc readFunc, int *Error);
]]
