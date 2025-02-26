-- Automatically generated with ffi-cdecl.

local ffi = require("ffi")

ffi.cdef[[
typedef signed char l_int8;
typedef unsigned char l_uint8;
typedef short int l_int16;
typedef short unsigned int l_uint16;
typedef int l_int32;
typedef unsigned int l_uint32;
typedef float l_float32;
typedef double l_float64;
typedef struct Box BOX;
typedef struct Boxa BOXA;
typedef struct Numa NUMA;
typedef struct Pix PIX;
typedef struct Pixa PIXA;
static const int L_NOCOPY = 0;
static const int L_COPY = 1;
static const int L_CLONE = 2;
BOX *boxAdjustSides(BOX *, BOX *, l_int32, l_int32, l_int32, l_int32);
BOX *boxCreate(l_int32, l_int32, l_int32, l_int32);
void boxDestroy(BOX **);
int boxGetGeometry(const BOX *, l_int32 *, l_int32 *, l_int32 *, l_int32 *);
BOX *boxOverlapRegion(BOX *, BOX *);
int boxaAddBox(BOXA *, BOX *, l_int32);
BOXA *boxaClipToBox(BOXA *, BOX *);
BOXA *boxaCombineOverlaps(BOXA *, PIXA *);
BOXA *boxaCreate(l_int32);
void boxaDestroy(BOXA **);
BOX *boxaGetBox(BOXA *, l_int32, l_int32);
int boxaGetBoxGeometry(BOXA *, l_int32, l_int32 *, l_int32 *, l_int32 *, l_int32 *);
l_int32 boxaGetCount(const BOXA *);
NUMA *numaCreateFromFArray(l_float32 *, l_int32, l_int32);
void numaDestroy(NUMA **);
l_int32 numaGetCount(NUMA *);
l_float32 *numaGetFArray(NUMA *, l_int32);
int numaGetIValue(NUMA *, l_int32, l_int32 *);
PIX *pixClipRectangle(PIX *, BOX *, BOX **);
PIX *pixClone(PIX *);
BOXA *pixConnCompBB(PIX *, l_int32);
PIX *pixConvertRGBToGrayFast(PIX *);
PIX *pixConvertTo32(PIX *);
void pixDestroy(PIX **);
PIX *pixDrawBoxaRandom(PIX *, BOXA *, l_int32);
l_int32 pixGetDepth(const PIX *);
l_int32 pixGetHeight(const PIX *);
int pixGetRegionsBinary(PIX *, PIX **, PIX **, PIX **, PIXA *);
l_int32 pixGetWidth(const PIX *);
PIX *pixInvert(PIX *, PIX *);
PIX *pixMultiplyByColor(PIX *, PIX *, BOX *, l_uint32);
BOXA *pixSplitIntoBoxa(PIX *, l_int32, l_int32, l_int32, l_int32, l_int32, l_int32);
PIX *pixThresholdToBinary(PIX *, l_int32);
int pixWriteMemPng(l_uint8 **, size_t *, PIX *, l_float32);
int pixWritePng(const char *, PIX *, l_float32);
]]
