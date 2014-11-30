local ffi = require("ffi")
ffi.cdef[[
typedef signed char             l_int8;
typedef unsigned char           l_uint8;
typedef short                   l_int16;
typedef unsigned short          l_uint16;
typedef int                     l_int32;
typedef unsigned int            l_uint32;
typedef float                   l_float32;
typedef double                  l_float64;

struct Box
{
    l_int32            x;
    l_int32            y;
    l_int32            w;
    l_int32            h;
    l_uint32           refcount;      /* reference count (1 if no clones)  */

};
typedef struct Box    BOX;

struct Boxa
{
    l_int32            n;             /* number of box in ptr array        */
    l_int32            nalloc;        /* number of box ptrs allocated      */
    l_uint32           refcount;      /* reference count (1 if no clones)  */
    struct Box       **box;           /* box ptr array                     */
};
typedef struct Boxa  BOXA;

struct Numa
{
    l_int32          nalloc;    /* size of allocated number array      */
    l_int32          n;         /* number of numbers saved             */
    l_int32          refcount;  /* reference count (1 if no clones)    */
    l_float32        startx;    /* x value assigned to array[0]        */
    l_float32        delx;      /* change in x value as i --> i + 1    */
    l_float32       *array;     /* number array                        */
};
typedef struct Numa  NUMA;

enum {
    L_INSERT = 0,     /* stuff it in; no copy, clone or copy-clone    */
    L_COPY = 1,       /* make/use a copy of the object                */
    L_CLONE = 2,      /* make/use clone (ref count) of the object     */
    L_COPY_CLONE = 3  /* make a new object and fill with with clones  */
                      /* of each object in the array(s)               */
};

struct Pix {
    l_uint32             w;           /* width in pixels                   */
    l_uint32             h;           /* height in pixels                  */
    l_uint32             d;           /* depth in bits                     */
    l_uint32             wpl;         /* 32-bit words/line                 */
    l_uint32             refcount;    /* reference count (1 if no clones)  */
    l_int32              xres;        /* image res (ppi) in x direction    */
                                      /* (use 0 if unknown)                */
    l_int32              yres;        /* image res (ppi) in y direction    */
                                      /* (use 0 if unknown)                */
    l_int32              informat;    /* input file format, IFF_*          */
    char                *text;        /* text string associated with pix   */
    struct PixColormap  *colormap;    /* colormap (may be null)            */
    l_uint32            *data;        /* the image data                    */
};
typedef struct Pix PIX;

/* Leptonica */
BOXA * boxaCreate(l_int32 n);
BOX * boxaGetBox (BOXA *boxa, l_int32 index, l_int32 accessflag);
NUMA * numaCreate(l_int32 n);
NUMA * numaCreateFromFArray(l_float32 *farray, l_int32 size, l_int32 copyflag);
l_int32 boxaAddBox(BOXA *boxa, BOX *box, l_int32 copyflag);
l_int32 numaGetMax (NUMA *na, l_float32 *pmaxval, l_int32 *pimaxloc);
l_int32 numaGetIValue (NUMA *na, l_int32 index, l_int32 *pival);
l_int32 boxaGetCount (BOXA *boxa);
l_int32 numaGetCount (NUMA *na);
void boxaDestroy (BOXA **pboxa);
void numaDestroy (NUMA **pna);
void pixDestroy (PIX **ppix);
l_int32 pixWritePng(const char *filename, PIX *pix, l_float32 gamma);
l_int32 pixWriteMemPng(l_uint8 **pdata, size_t *psize, PIX *pix, l_float32 gamma);
l_uint32 * pixGetData(PIX *pix);
l_int32 pixGetWpl(PIX *pix);
l_int32 pixSetPixel(PIX *pix, l_int32 x, l_int32 y, l_uint32 val);
PIX * pixCreate(l_int32 width, l_int32 height, l_int32 depth);
PIX * pixConvertTo32(PIX *pixs);
PIX * pixMultiplyByColor(PIX *pixd, PIX *pixs, BOX *box, l_uint32 color);
PIX * pixBlendBackgroundToColor(PIX *pixd, PIX *pixs, BOX *box, l_uint32 color, l_float32 gamma, l_int32 minval, l_int32 maxval);
]]
