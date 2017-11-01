local ffi = require("ffi")
require("ffi/leptonica_h")
ffi.cdef[[
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

/* K2pdfopt */
void bmp_init(WILLUSBITMAP *bmap);
void bmp_free(WILLUSBITMAP *bmap);
int  bmp_alloc(WILLUSBITMAP *bmap);
int  bmp_copy(WILLUSBITMAP *dest,WILLUSBITMAP *src);
unsigned char *bmp_rowptr_from_top(WILLUSBITMAP *bmp,int row);
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
void k2pdfopt_reflow_bmp(KOPTContext *kctx);
void k2pdfopt_tocr_end();
void pageregions_init(PAGEREGIONS *regions);
void pageregions_free(PAGEREGIONS *regions);
void k2pdfopt_crop_bmp(KOPTContext *kctx);
void k2pdfopt_part_bmp(KOPTContext *kctx);
void k2pdfopt_optimize_bmp(KOPTContext *kctx);
void pixmap_to_bmp(WILLUSBITMAP *bmp, unsigned char *pix_data, int ncomp);
PIX* bitmap2pix(WILLUSBITMAP *src, int x, int y, int w, int h);
]]
