-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
typedef struct {
  float x0, y0;
  float x1, y1;
} BBox;
typedef struct Boxa BOXA;
typedef struct {
  int row;
  int col;
  int type;
} K2PAGEBREAKMARK;
typedef struct {
  int n;
  K2PAGEBREAKMARK k2pagebreakmark[32];
} K2PAGEBREAKMARKS;
typedef struct Numa NUMA;
typedef struct Pix PIX;
typedef struct {
  double x, y;
} POINT2D;
typedef struct {
  int srcpageno;
  int srcwidth;
  int srcheight;
  double srcdpiw;
  double srcdpih;
  int srcrot;
  POINT2D coords[3];
} WRECTMAP;
typedef struct {
  WRECTMAP *wrectmap;
  int n, na;
} WRECTMAPS;
typedef struct {
  int red[256];
  int green[256];
  int blue[256];
  unsigned char *data;
  int width;
  int height;
  int bpp;
  int size_allocated;
  int type;
} WILLUSBITMAP;
typedef struct {
  int ch;
  int c2;
  int r1;
  int r2;
} HYPHENINFO;
typedef struct {
  int c1, c2;
  int r1, r2;
  int rowbase;
  int gap;
  int gapblank;
  int rowheight;
  int capheight;
  int h5050;
  int lcheight;
  int type;
  double rat;
  HYPHENINFO hyphen;
} TEXTROW;
typedef struct {
  TEXTROW *textrow;
  int n, na;
} TEXTROWS;
typedef struct {
  int r1, r2;
  int c1, c2;
  TEXTROWS textrows;
  TEXTROW bbox;
  WRECTMAPS *wrectmaps;
  K2PAGEBREAKMARKS *k2pagebreakmarks;
  int k2pagebreakmarks_allocated;
  int bgcolor;
  int dpi;
  int pageno;
  int rotdeg;
  int *colcount;
  int *rowcount;
  WILLUSBITMAP *bmp;
  WILLUSBITMAP *bmp8;
  WILLUSBITMAP *marked;
} BMPREGION;
typedef struct {
  BMPREGION bmpregion;
  int notes;
  int fullspan;
  int level;
} PAGEREGION;
typedef struct {
  PAGEREGION *pageregion;
  int n, na;
} PAGEREGIONS;
struct KOPTContext {
  int trim;
  int wrap;
  int white_threshold;
  int paint_white_threshold;
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
  BOXA *rboxa;
  NUMA *rnai;
  BOXA *nboxa;
  NUMA *nnai;
  WRECTMAPS rectmaps;
  PAGEREGIONS pageregions;
  BBox bbox;
  char *language;
  WILLUSBITMAP dst;
  WILLUSBITMAP src;
};
typedef struct KOPTContext KOPTContext;
void bmp_init(WILLUSBITMAP *bmap);
void bmp_free(WILLUSBITMAP *bmap);
int bmp_alloc(WILLUSBITMAP *bmap);
int bmp_bytewidth(WILLUSBITMAP *bmp);
int bmp_copy(WILLUSBITMAP *dest, WILLUSBITMAP *src);
void wrectmaps_init(WRECTMAPS *wrectmaps);
void wrectmaps_free(WRECTMAPS *wrectmaps);
int wrectmap_inside(WRECTMAP *wrmap, int xc, int yc);
void k2pdfopt_get_reflowed_word_boxes(KOPTContext *kctx, WILLUSBITMAP *src, int x, int y, int w, int h);
void k2pdfopt_get_native_word_boxes(KOPTContext *kctx, WILLUSBITMAP *src, int x, int y, int w, int h);
int k2pdfopt_tocr_single_word(WILLUSBITMAP *src, int x, int y, int w, int h, int dpi, char *word, int max_length, char *datadir, char *lang, int ocr_type, int allow_spaces, int std_proc);
void k2pdfopt_reflow_bmp(KOPTContext *kctx);
void k2pdfopt_tocr_end(void);
void k2pdfopt_crop_bmp(KOPTContext *kctx);
void k2pdfopt_optimize_bmp(KOPTContext *kctx);
void pixmap_to_bmp(WILLUSBITMAP *bmp, unsigned char *pix_data, int ncomp);
PIX *bitmap2pix(WILLUSBITMAP *src, int x, int y, int w, int h);
]]
