-- Automatically generated with ffi-cdecl.

local ffi = require("ffi")

ffi.cdef[[
static const int FZ_STEXT_BLOCK_TEXT = 0;
typedef struct {
  float x;
  float y;
} fz_point;
typedef struct {
  fz_point ul;
  fz_point ur;
  fz_point ll;
  fz_point lr;
} fz_quad;
typedef struct {
  float x0;
  float y0;
  float x1;
  float y1;
} fz_rect;
typedef struct {
  int x0;
  int y0;
  int x1;
  int y1;
} fz_irect;
typedef struct {
  float a;
  float b;
  float c;
  float d;
  float e;
  float f;
} fz_matrix;
extern const fz_matrix fz_identity;
extern const fz_rect fz_empty_rect;
typedef struct fz_context fz_context;
typedef struct fz_font fz_font;
void fz_install_external_font_funcs(fz_context *);
typedef struct fz_archive fz_archive;
fz_archive *mupdf_open_directory(fz_context *, const char *);
void *mupdf_drop_archive(fz_context *, fz_archive *);
typedef struct {
  int refs;
  unsigned char *data;
  size_t cap;
  size_t len;
  int unused_bits;
  int shared;
} fz_buffer;
fz_buffer *mupdf_new_buffer_from_shared_data(fz_context *, const unsigned char *, size_t);
void *mupdf_drop_buffer(fz_context *, fz_buffer *);
typedef struct {
  void *user;
  void *(*malloc)(void *, size_t);
  void *(*realloc)(void *, void *, size_t);
  void (*free)(void *, void *);
} fz_alloc_context;
typedef struct fz_colorspace fz_colorspace;
typedef struct {
  void *user;
  void (*lock)(void *, int);
  void (*unlock)(void *, int);
} fz_locks_context;
fz_context *fz_new_context_imp(const fz_alloc_context *, const fz_locks_context *, size_t, const char *);
void fz_drop_context(fz_context *);
void fz_register_document_handlers(fz_context *);
void fz_set_user_context(fz_context *, void *);
void *fz_user_context(fz_context *);
typedef struct fz_image fz_image;
typedef struct fz_pixmap fz_pixmap;
fz_image *mupdf_new_image_from_buffer(fz_context *, fz_buffer *);
fz_pixmap *mupdf_get_pixmap_from_image(fz_context *, fz_image *, const fz_irect *, fz_matrix *, int *, int *);
void fz_drop_image(fz_context *, fz_image *);
int fz_runetochar(char *, int);
typedef struct fz_stream fz_stream;
typedef struct {
  int chapter;
  int page;
} fz_location;
typedef struct fz_outline fz_outline;
struct fz_outline {
  int refs;
  char *title;
  char *uri;
  fz_location page;
  float x;
  float y;
  struct fz_outline *next;
  struct fz_outline *down;
  unsigned int is_open : 1;
  unsigned int flags : 7;
  unsigned char r;
  unsigned char g;
  unsigned char b;
};
typedef struct {
  int abort;
  int progress;
  size_t progress_max;
  int errors;
  int incomplete;
} fz_cookie;
typedef struct fz_separations fz_separations;
typedef struct fz_page fz_page;
typedef struct fz_document fz_document;
typedef struct fz_device fz_device;
fz_document *mupdf_open_document(fz_context *, const char *);
fz_document *mupdf_open_document_with_stream_and_dir(fz_context *, const char *, fz_stream *, fz_archive *);
int fz_is_document_reflowable(fz_context *, fz_document *);
int fz_needs_password(fz_context *, fz_document *);
int fz_authenticate_password(fz_context *, fz_document *, const char *);
void fz_drop_document(fz_context *, fz_document *);
int mupdf_count_pages(fz_context *, fz_document *);
void *mupdf_layout_document(fz_context *, fz_document *, float, float, float);
int fz_lookup_metadata(fz_context *, fz_document *, const char *, char *, size_t);
fz_page *mupdf_load_page(fz_context *, fz_document *, int);
fz_rect *mupdf_fz_bound_page(fz_context *, fz_page *, fz_rect *);
void fz_drop_page(fz_context *, fz_page *);
typedef struct fz_link fz_link;
struct fz_link {
  int refs;
  struct fz_link *next;
  fz_rect rect;
  char *uri;
  void (*set_rect_fn)(fz_context *, fz_link *, fz_rect);
  void (*set_uri_fn)(fz_context *, fz_link *, const char *);
  void (*drop)(fz_context *, fz_link *);
};
fz_link *mupdf_load_links(fz_context *, fz_page *);
fz_location *mupdf_fz_resolve_link(fz_context *, fz_document *, const char *, float *, float *, fz_location *);
void fz_drop_link(fz_context *, fz_link *);
int mupdf_fz_page_number_from_location(fz_context *, fz_document *, fz_location *);
void *mupdf_fz_location_from_page_number(fz_context *, fz_document *, fz_location *, int);
fz_outline *mupdf_load_outline(fz_context *, fz_document *);
void fz_drop_outline(fz_context *, fz_outline *);
void *mupdf_drop_stream(fz_context *, fz_stream *);
fz_stream *mupdf_open_memory(fz_context *, const unsigned char *, size_t);
typedef struct fz_stext_char fz_stext_char;
struct fz_stext_char {
  int c;
  uint16_t bidi;
  uint16_t flags;
  uint32_t argb;
  fz_point origin;
  fz_quad quad;
  float size;
  fz_font *font;
  fz_stext_char *next;
};
typedef struct fz_stext_line fz_stext_line;
struct fz_stext_line {
  int wmode;
  fz_point dir;
  fz_rect bbox;
  fz_stext_char *first_char;
  fz_stext_char *last_char;
  fz_stext_line *prev;
  fz_stext_line *next;
};
typedef struct fz_stext_block fz_stext_block;
struct fz_stext_block {
  int type;
  fz_rect bbox;
  union {
    struct {
      fz_stext_line *first_line;
      fz_stext_line *last_line;
      int flags;
    } t;
    struct {
      fz_matrix transform;
      fz_image *image;
    } i;
    struct {
      struct fz_stext_struct *down;
      int index;
    } s;
    struct {
      uint32_t flags;
      uint32_t argb;
    } v;
    struct {
      struct fz_stext_grid_positions *xs;
      struct fz_stext_grid_positions *ys;
    } b;
  } u;
  fz_stext_block *prev;
  fz_stext_block *next;
};
typedef struct {
  int flags;
  float scale;
  fz_rect clip;
} fz_stext_options;
typedef struct {
  struct fz_pool *pool;
  fz_rect mediabox;
  fz_stext_block *first_block;
  fz_stext_block *last_block;
  struct fz_stext_struct *last_struct;
} fz_stext_page;
fz_stext_page *mupdf_new_stext_page_from_page(fz_context *, fz_page *, const fz_stext_options *);
void fz_drop_stext_page(fz_context *, fz_stext_page *);
typedef struct {
  uint8_t ri;
  uint8_t bp;
  uint8_t op;
  uint8_t opm;
} fz_color_params;
typedef struct {
  int refs;
  fz_colorspace *gray;
  fz_colorspace *rgb;
  fz_colorspace *cmyk;
  fz_colorspace *oi;
} fz_default_colorspaces;
extern const fz_color_params fz_default_color_params;
fz_pixmap *fz_new_pixmap(fz_context *, fz_colorspace *, int, int, fz_separations *, int);
fz_pixmap *mupdf_new_pixmap_with_bbox(fz_context *, fz_colorspace *, const fz_irect *, fz_separations *, int);
fz_pixmap *mupdf_new_pixmap_with_data(fz_context *, fz_colorspace *, int, int, fz_separations *, int, int, unsigned char *);
fz_pixmap *mupdf_new_pixmap_with_bbox_and_data(fz_context *, fz_colorspace *, const fz_irect *, fz_separations *, int, unsigned char *);
fz_pixmap *mupdf_convert_pixmap(fz_context *, const fz_pixmap *, fz_colorspace *, fz_colorspace *, fz_default_colorspaces *, fz_color_params, int);
void fz_drop_pixmap(fz_context *, fz_pixmap *);
void fz_clear_pixmap_with_value(fz_context *, fz_pixmap *, int);
void fz_gamma_pixmap(fz_context *, fz_pixmap *, float);
fz_pixmap *fz_scale_pixmap(fz_context *, fz_pixmap *, float, float, float, float, const fz_irect *);
int fz_pixmap_width(fz_context *, const fz_pixmap *);
int fz_pixmap_height(fz_context *, const fz_pixmap *);
int fz_pixmap_components(fz_context *, const fz_pixmap *);
unsigned char *fz_pixmap_samples(fz_context *, const fz_pixmap *);
fz_colorspace *fz_device_gray(fz_context *);
fz_colorspace *fz_device_rgb(fz_context *);
fz_colorspace *fz_device_bgr(fz_context *);
fz_device *mupdf_new_draw_device(fz_context *, const fz_matrix *, fz_pixmap *);
fz_device *mupdf_new_bbox_device(fz_context *, fz_rect *);
void *mupdf_run_page(fz_context *, fz_page *, fz_device *, const fz_matrix *, fz_cookie *);
void fz_close_device(fz_context *, fz_device *);
void fz_drop_device(fz_context *, fz_device *);
enum pdf_annot_type {
  PDF_ANNOT_TEXT = 0,
  PDF_ANNOT_LINK = 1,
  PDF_ANNOT_FREE_TEXT = 2,
  PDF_ANNOT_LINE = 3,
  PDF_ANNOT_SQUARE = 4,
  PDF_ANNOT_CIRCLE = 5,
  PDF_ANNOT_POLYGON = 6,
  PDF_ANNOT_POLY_LINE = 7,
  PDF_ANNOT_HIGHLIGHT = 8,
  PDF_ANNOT_UNDERLINE = 9,
  PDF_ANNOT_SQUIGGLY = 10,
  PDF_ANNOT_STRIKE_OUT = 11,
  PDF_ANNOT_REDACT = 12,
  PDF_ANNOT_STAMP = 13,
  PDF_ANNOT_CARET = 14,
  PDF_ANNOT_INK = 15,
  PDF_ANNOT_POPUP = 16,
  PDF_ANNOT_FILE_ATTACHMENT = 17,
  PDF_ANNOT_SOUND = 18,
  PDF_ANNOT_MOVIE = 19,
  PDF_ANNOT_RICH_MEDIA = 20,
  PDF_ANNOT_WIDGET = 21,
  PDF_ANNOT_SCREEN = 22,
  PDF_ANNOT_PRINTER_MARK = 23,
  PDF_ANNOT_TRAP_NET = 24,
  PDF_ANNOT_WATERMARK = 25,
  PDF_ANNOT_3D = 26,
  PDF_ANNOT_PROJECTION = 27,
  PDF_ANNOT_UNKNOWN = -1,
};
typedef struct pdf_annot pdf_annot;
typedef struct pdf_page pdf_page;
typedef struct pdf_document pdf_document;
pdf_annot *mupdf_pdf_create_annot(fz_context *, pdf_page *, enum pdf_annot_type);
void *mupdf_pdf_delete_annot(fz_context *, pdf_page *, pdf_annot *);
void *mupdf_pdf_set_annot_quad_points(fz_context *, pdf_annot *, int, const fz_quad *);
void *mupdf_pdf_set_annot_contents(fz_context *, pdf_annot *, const char *);
void *mupdf_pdf_set_annot_color(fz_context *, pdf_annot *, int, const float *);
void *mupdf_pdf_set_annot_opacity(fz_context *, pdf_annot *, float);
pdf_annot *mupdf_pdf_first_annot(fz_context *, pdf_page *);
pdf_annot *mupdf_pdf_next_annot(fz_context *, pdf_annot *);
int mupdf_pdf_annot_quad_point_count(fz_context *, pdf_annot *);
void *mupdf_pdf_annot_quad_point(fz_context *, pdf_annot *, int, fz_quad *);
typedef struct {
  int do_incremental;
  int do_pretty;
  int do_ascii;
  int do_compress;
  int do_compress_images;
  int do_compress_fonts;
  int do_decompress;
  int do_garbage;
  int do_linear;
  int do_clean;
  int do_sanitize;
  int do_appearance;
  int do_encrypt;
  int dont_regenerate_id;
  int permissions;
  char opwd_utf8[128];
  char upwd_utf8[128];
  int do_snapshot;
  int do_preserve_metadata;
  int do_use_objstms;
  int compression_effort;
  int do_labels;
} pdf_write_options;
void *mupdf_pdf_save_document(fz_context *, pdf_document *, const char *, pdf_write_options *);
fz_alloc_context *mupdf_get_my_alloc_context();
int mupdf_get_cache_size();
int mupdf_error_code(fz_context *);
char *mupdf_error_message(fz_context *);
fz_matrix *mupdf_fz_scale(fz_matrix *, float, float);
fz_matrix *mupdf_fz_translate(fz_matrix *, float, float);
fz_matrix *mupdf_fz_pre_rotate(fz_matrix *, float);
fz_matrix *mupdf_fz_pre_translate(fz_matrix *, float, float);
fz_rect *mupdf_fz_transform_rect(fz_rect *, const fz_matrix *);
fz_irect *mupdf_fz_round_rect(fz_irect *, const fz_rect *);
fz_rect *mupdf_fz_union_rect(fz_rect *, const fz_rect *);
fz_rect *mupdf_fz_rect_from_quad(fz_rect *, const fz_quad *);
]]
