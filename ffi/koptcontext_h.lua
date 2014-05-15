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

typedef struct BBox {
    float x0, y0;
    float x1, y1;
} BBox;

typedef struct POINT2D {
    double  x,y;
} POINT2D;

typedef struct {
    int srcpageno;
    int srcwidth;  /* pixels */
    int srcheight; /* pixels */
    double srcdpiw;
    double srcdpih;
    int srcrot;    /* deg */
    POINT2D coords[3];     /* [0]=top left corner of source page bitmap (pixels) */
                           /* [1]=top left corner of wrapbmp bitmap (pixels) */
                           /* [2]=width,height of region (pixels) */
} WRECTMAP;

typedef struct {
    WRECTMAP *wrectmap;
    int n,na;
} WRECTMAPS;

typedef struct {
    int     red[256];
    int     green[256];
    int     blue[256];
    unsigned char *data;  /* Top to bottom in native type, bottom to */
                          /* top in Win32 type.                      */
    int     width;      /* Width of image in pixels */
    int     height;     /* Height of image in pixels */
    int     bpp;        /* Bits per pixel (only 8 or 24 allowed) */
    int     size_allocated;
    int     type;  /* See defines above for WILLUSBITMAP_TYPE_... */
} WILLUSBITMAP;

typedef struct {
    int ch;    /* Hyphen starting point -- < 0 for no hyphen */
    int c2;    /* End of end region if hyphen is erased */
    int r1;    /* Top of hyphen */
    int r2;    /* Bottom of hyphen */
} HYPHENINFO;

typedef struct {
    int c1,c2;   /* Left and right columns */
    int r1,r2;   /* Top and bottom of region in pixels */
    int rowbase; /* Baseline of row */
    int gap;     /* Gap between next region and this region's rowbase. */
    int gapblank;  /* Actual blank area between next region and this region. */
    int rowheight; /* text + gap (delta between rowbases) */
    int capheight;
    int h5050;
    int lcheight;
    int type;    /* See region type #defines above */
    double rat;  /* If found with find_doubles, this is > 0 (the figure of merit) */
    HYPHENINFO hyphen;
} TEXTROW;

typedef struct {
    TEXTROW *textrow;
    int n,na;
} TEXTROWS;

typedef struct {
    int r1,r2;      /* row position from top of bmp, inclusive */
    int c1,c2;      /* column positions, inclusive */
    TEXTROWS textrows; /* If nrows>0, top and bottom (if nrows>11) text row of region */
    TEXTROW bbox;   /* Bounding box of region.  type==REGION_TYPE_UNDETERMINED if not calced yet */
    WRECTMAPS *wrectmaps; /* If region consists of multiple, separated source rectangles
                          ** (like from wrapbmp structure), then this is non-null and maps
                          ** the bitmap region to the source page.
                          */
    int bgcolor;    /* Background color of region, 0 - 255 */
    int dpi;        /* dpi of bitmap */
    int pageno;     /* Source page number, -1 if unknown */
    int rotdeg;     /* Source rotation, degrees, counterclockwise */
    int *colcount;  /* Always check for NULL before using */
    int *rowcount;  /* Always check for NULL before using */
    WILLUSBITMAP *bmp;
    WILLUSBITMAP *bmp8;
    WILLUSBITMAP *marked;
} BMPREGION;

typedef struct {
    BMPREGION bmpregion;
    int fullspan;
    int level;
} PAGEREGION;

typedef struct {
    PAGEREGION *pageregion;
    int n,na;
} PAGEREGIONS;

typedef struct KOPTContext {
    int trim;
    int wrap;
    int white;
    int indent;
    int rotate;
    int columns;
    int offset_x;
    int offset_y;
    int dev_dpi;
    int dev_width;
    int dev_height;
    int page_width;
    int page_height;
    int straighten;
    int justification;
    int read_max_width;
    int read_max_height;
    int writing_direction;

    double zoom;
    double margin;
    double quality;
    double contrast;
    double defect_size;
    double line_spacing;
    double word_spacing;
    double shrink_factor;

    int precache;
    int debug;
    int cjkchar;
    BOXA *rboxa;    // word boxes in reflowed page
    NUMA *rnai;     // word boxes indices in reflowed page
    BOXA *nboxa;    // word boxes in native page
    NUMA *nnai;     // word boxes indices in native page
    WRECTMAPS rectmaps; // rect maps between reflowed and native pages
    PAGEREGIONS pageregions; // sorted region list by display order
    BBox bbox;
    char *language;
    WILLUSBITMAP dst;
    WILLUSBITMAP src;

} KOPTContext;

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
l_int32 pixWritePng(char *filename, PIX *pix, l_float32 gamma);
l_int32 pixWriteMemPng(l_uint8 **pdata, size_t *psize, PIX *pix, l_float32 gamma);
PIX * pixConvertTo32(PIX *pixs);
PIX * pixMultiplyByColor(PIX *pixd, PIX *pixs, BOX *box, l_uint32 color);
PIX * pixBlendBackgroundToColor(PIX *pixd, PIX *pixs, BOX *box, l_uint32 color, l_float32 gamma, l_int32 minval, l_int32 maxval);

/* K2pdfopt */
void bmp_init(WILLUSBITMAP *bmap);
void bmp_free(WILLUSBITMAP *bmap);
int  bmp_copy(WILLUSBITMAP *dest,WILLUSBITMAP *src);
void wrectmaps_init(WRECTMAPS *wrectmaps);
void wrectmaps_free(WRECTMAPS *wrectmaps);
int  wrectmap_inside(WRECTMAP *wrmap,int xc,int yc);
void k2pdfopt_get_reflowed_word_boxes(KOPTContext *kctx, WILLUSBITMAP *src,
        int x, int y, int w, int h);
void k2pdfopt_get_native_word_boxes(KOPTContext *kctx, WILLUSBITMAP *src,
        int x, int y, int w, int h);
void k2pdfopt_tocr_single_word(WILLUSBITMAP *src,
        int x, int y, int w, int h,
        char *word, int max_length,
        char *datadir, char *lang, int ocr_type,
        int allow_spaces, int std_proc);
int bmpmupdf_pdffile_to_bmp(WILLUSBITMAP *bmp,char *filename,int pageno,double dpi,int bpp);
void k2pdfopt_reflow_bmp(KOPTContext *kctx);
void k2pdfopt_tocr_end();
void pageregions_init(PAGEREGIONS *regions);
void pageregions_free(PAGEREGIONS *regions);
void k2pdfopt_crop_bmp(KOPTContext *kctx);
void k2pdfopt_part_bmp(KOPTContext *kctx);
void k2pdfopt_optimize_bmp(KOPTContext *kctx);
PIX* bitmap2pix(WILLUSBITMAP *src, int x, int y, int w, int h);
]]
