-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
static const unsigned FZ_STEXT_BLOCK_TEXT = 0;
typedef struct {
  float x, y;
} fz_point;
typedef struct {
  fz_point ul, ur, ll, lr;
} fz_quad;
typedef struct {
  float x0, y0;
  float x1, y1;
} fz_rect;
typedef struct {
  int x0, y0;
  int x1, y1;
} fz_irect;
typedef struct {
  float a, b, c, d, e, f;
} fz_matrix;
const fz_matrix fz_identity;
const fz_rect fz_empty_rect;
typedef struct fz_context fz_context;
typedef struct fz_font fz_font;
void fz_install_external_font_funcs(fz_context *ctx);
typedef struct fz_archive fz_archive;
fz_archive *mupdf_open_directory(fz_context *ctx, const char *path);
void *mupdf_drop_archive(fz_context *ctx, fz_archive *archive);
typedef struct {
  int refs;
  unsigned char *data;
  size_t cap, len;
  int unused_bits;
  int shared;
} fz_buffer;
fz_buffer *mupdf_new_buffer_from_shared_data(fz_context *ctx, const unsigned char *data, size_t size);
void *mupdf_drop_buffer(fz_context *ctx, fz_buffer *buf);
typedef struct {
  void *user;
  void *(*malloc)(void *, size_t);
  void *(*realloc)(void *, void *, size_t);
  void (*free)(void *, void *);
} fz_alloc_context;
typedef struct fz_colorspace fz_colorspace;
typedef struct {
  void *user;
  void (*lock)(void *user, int lock);
  void (*unlock)(void *user, int lock);
} fz_locks_context;
fz_context *fz_new_context_imp(const fz_alloc_context *alloc, const fz_locks_context *locks, size_t max_store, const char *version);
void fz_drop_context(fz_context *ctx);
void fz_register_document_handlers(fz_context *ctx);
void fz_set_user_context(fz_context *ctx, void *user);
void *fz_user_context(fz_context *ctx);
typedef struct fz_image fz_image;
typedef struct fz_pixmap fz_pixmap;
fz_image *mupdf_new_image_from_buffer(fz_context *ctx, fz_buffer *buffer);
fz_pixmap *mupdf_get_pixmap_from_image(fz_context *ctx, fz_image *image, const fz_irect *subarea, fz_matrix *trans, int *w, int *h);
void fz_drop_image(fz_context *ctx, fz_image *image);
int fz_runetochar(char *str, int rune);
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
  float x, y;
  struct fz_outline *next;
  struct fz_outline *down;
  unsigned is_open:1;
  unsigned flags:7;
  unsigned r:8;
  unsigned g:8;
  unsigned b:8;
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
fz_document *mupdf_open_document(fz_context *ctx, const char *filename);
fz_document *mupdf_open_document_with_stream_and_dir(fz_context *ctx, const char *magic, fz_stream *stream, fz_archive *archive);
int fz_is_document_reflowable(fz_context *ctx, fz_document *doc);
int fz_needs_password(fz_context *ctx, fz_document *doc);
int fz_authenticate_password(fz_context *ctx, fz_document *doc, const char *password);
void fz_drop_document(fz_context *ctx, fz_document *doc);
int mupdf_count_pages(fz_context *ctx, fz_document *doc);
void *mupdf_layout_document(fz_context *ctx, fz_document *doc, float w, float h, float em);
int fz_lookup_metadata(fz_context *ctx, fz_document *doc, const char *key, char *buf, size_t size);
fz_page *mupdf_load_page(fz_context *ctx, fz_document *doc, int pageno);
fz_rect *mupdf_fz_bound_page(fz_context *ctx, fz_page *page, fz_rect *r);
void fz_drop_page(fz_context *ctx, fz_page *page);
typedef struct fz_link fz_link;
typedef void (fz_link_drop_link_fn)(fz_context *ctx, fz_link *link);
typedef void (fz_link_set_rect_fn)(fz_context *ctx, fz_link *link, fz_rect rect);
typedef void (fz_link_set_uri_fn)(fz_context *ctx, fz_link *link, const char *uri);
struct fz_link {
  int refs;
  struct fz_link *next;
  fz_rect rect;
  char *uri;
  fz_link_set_rect_fn *set_rect_fn;
  fz_link_set_uri_fn *set_uri_fn;
  fz_link_drop_link_fn *drop;
};
fz_link *mupdf_load_links(fz_context *ctx, fz_page *page);
fz_location *mupdf_fz_resolve_link(fz_context *ctx, fz_document *doc, const char *uri, float *xp, float *yp, fz_location *loc);
void fz_drop_link(fz_context *ctx, fz_link *link);
int mupdf_fz_page_number_from_location(fz_context *ctx, fz_document *doc, fz_location *loc);
void *mupdf_fz_location_from_page_number(fz_context *ctx, fz_document *doc, fz_location *location, int number);
fz_outline *mupdf_load_outline(fz_context *ctx, fz_document *doc);
void fz_drop_outline(fz_context *ctx, fz_outline *outline);
void *mupdf_drop_stream(fz_context *ctx, fz_stream *stm);
fz_stream *mupdf_open_memory(fz_context *ctx, const unsigned char *data, size_t len);
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
typedef struct fz_pool fz_pool;
typedef struct fz_pool_array fz_pool_array;
typedef struct {
  int w;
  int h;
  struct {
    unsigned flags;
  } info[];
} fz_stext_grid_info;
typedef struct fz_stext_grid_positions fz_stext_grid_positions;
typedef struct fz_stext_struct fz_stext_struct;
typedef struct fz_stext_line fz_stext_line;
struct fz_stext_line {
  uint8_t wmode;
  uint8_t flags;
  fz_point dir;
  fz_rect bbox;
  fz_stext_char *first_char, *last_char;
  fz_stext_line *prev, *next;
};
typedef struct fz_stext_block fz_stext_block;
struct fz_stext_block {
  int type;
  int id;
  fz_rect bbox;
  union {
    struct {
      fz_stext_line *first_line, *last_line;
      int flags;
    } t;
    struct {
      fz_matrix transform;
      fz_image *image;
    } i;
    struct {
      fz_stext_struct *down;
      int index;
    } s;
    struct {
      uint32_t flags;
      uint32_t argb;
    } v;
    struct {
      fz_stext_grid_positions *xs;
      fz_stext_grid_positions *ys;
      fz_stext_grid_info *info;
    } b;
  } u;
  fz_stext_block *prev, *next;
};
typedef struct {
  int flags;
  float scale;
  fz_rect clip;
} fz_stext_options;
typedef struct {
  int refs;
  fz_pool *pool;
  fz_rect mediabox;
  fz_stext_block *first_block;
  fz_stext_block *last_block;
  fz_stext_struct *last_struct;
  fz_pool_array *id_list;
} fz_stext_page;
fz_stext_page *mupdf_new_stext_page_from_page(fz_context *ctx, fz_page *page, const fz_stext_options *options);
int mupdf_search_stext_page(fz_context *ctx, fz_stext_page *text, const char *needle, int *hit_mark, fz_quad *hit_bbox, int hit_max);
void fz_drop_stext_page(fz_context *ctx, fz_stext_page *page);
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
const fz_color_params fz_default_color_params;
fz_pixmap *fz_new_pixmap(fz_context *ctx, fz_colorspace *cs, int w, int h, fz_separations *seps, int alpha);
fz_pixmap *mupdf_new_pixmap_with_bbox(fz_context *ctx, fz_colorspace *cs, const fz_irect *bbox, fz_separations *seps, int alpha);
fz_pixmap *mupdf_new_pixmap_with_data(fz_context *ctx, fz_colorspace *cs, int w, int h, fz_separations *seps, int alpha, int stride, unsigned char *samples);
fz_pixmap *mupdf_new_pixmap_with_bbox_and_data(fz_context *ctx, fz_colorspace *cs, const fz_irect *rect, fz_separations *seps, int alpha, unsigned char *samples);
fz_pixmap *mupdf_convert_pixmap(fz_context *ctx, const fz_pixmap *pix, fz_colorspace *ds, fz_colorspace *prf, fz_default_colorspaces *default_cs, fz_color_params color_params, int keep_alpha);
void fz_drop_pixmap(fz_context *ctx, fz_pixmap *pix);
void fz_clear_pixmap_with_value(fz_context *ctx, fz_pixmap *pix, int value);
void fz_gamma_pixmap(fz_context *ctx, fz_pixmap *pix, float gamma);
fz_pixmap *fz_scale_pixmap(fz_context *ctx, fz_pixmap *src, float x, float y, float w, float h, const fz_irect *clip);
int fz_pixmap_width(fz_context *ctx, const fz_pixmap *pix);
int fz_pixmap_height(fz_context *ctx, const fz_pixmap *pix);
int fz_pixmap_components(fz_context *ctx, const fz_pixmap *pix);
unsigned char *fz_pixmap_samples(fz_context *ctx, const fz_pixmap *pix);
fz_colorspace *fz_device_gray(fz_context *ctx);
fz_colorspace *fz_device_rgb(fz_context *ctx);
fz_colorspace *fz_device_bgr(fz_context *ctx);
fz_device *mupdf_new_draw_device(fz_context *ctx, const fz_matrix *transform, fz_pixmap *dest);
fz_device *mupdf_new_bbox_device(fz_context *ctx, fz_rect *rectp);
fz_device *mupdf_new_isolated_smask_device(fz_context *ctx, fz_device *dev);
int mupdf_page_has_smask(fz_context *ctx, fz_page *page);
void *mupdf_run_page(fz_context *ctx, fz_page *page, fz_device *dev, const fz_matrix *transform, fz_cookie *cookie);
void fz_close_device(fz_context *ctx, fz_device *dev);
void fz_drop_device(fz_context *ctx, fz_device *dev);
enum pdf_annot_type {
  PDF_ANNOT_TEXT,
  PDF_ANNOT_LINK,
  PDF_ANNOT_FREE_TEXT,
  PDF_ANNOT_LINE,
  PDF_ANNOT_SQUARE,
  PDF_ANNOT_CIRCLE,
  PDF_ANNOT_POLYGON,
  PDF_ANNOT_POLY_LINE,
  PDF_ANNOT_HIGHLIGHT,
  PDF_ANNOT_UNDERLINE,
  PDF_ANNOT_SQUIGGLY,
  PDF_ANNOT_STRIKE_OUT,
  PDF_ANNOT_REDACT,
  PDF_ANNOT_STAMP,
  PDF_ANNOT_CARET,
  PDF_ANNOT_INK,
  PDF_ANNOT_POPUP,
  PDF_ANNOT_FILE_ATTACHMENT,
  PDF_ANNOT_SOUND,
  PDF_ANNOT_MOVIE,
  PDF_ANNOT_RICH_MEDIA,
  PDF_ANNOT_WIDGET,
  PDF_ANNOT_SCREEN,
  PDF_ANNOT_PRINTER_MARK,
  PDF_ANNOT_TRAP_NET,
  PDF_ANNOT_WATERMARK,
  PDF_ANNOT_3D,
  PDF_ANNOT_PROJECTION,
  PDF_ANNOT_UNKNOWN = -1,
};
typedef struct pdf_annot pdf_annot;
typedef struct pdf_page pdf_page;
typedef struct pdf_document pdf_document;
int mupdf_pdf_annot_type(fz_context *ctx, pdf_annot *annot);
const char *mupdf_pdf_annot_contents(fz_context *ctx, pdf_annot *annot);
pdf_annot *mupdf_pdf_create_annot(fz_context *ctx, pdf_page *page, enum pdf_annot_type type);
void *mupdf_pdf_delete_annot(fz_context *ctx, pdf_page *page, pdf_annot *annot);
void *mupdf_pdf_set_annot_quad_points(fz_context *ctx, pdf_annot *annot, int n, const fz_quad *qv);
void *mupdf_pdf_set_annot_contents(fz_context *ctx, pdf_annot *annot, const char *text);
void *mupdf_pdf_set_annot_color(fz_context *ctx, pdf_annot *annot, int n, const float color[4]);
void *mupdf_pdf_set_annot_opacity(fz_context *ctx, pdf_annot *annot, float opacity);
pdf_annot *mupdf_pdf_first_annot(fz_context *ctx, pdf_page *page);
pdf_annot *mupdf_pdf_next_annot(fz_context *ctx, pdf_annot *annot);
int mupdf_pdf_annot_quad_point_count(fz_context *ctx, pdf_annot *annot);
void *mupdf_pdf_annot_quad_point(fz_context *ctx, pdf_annot *annot, int i, fz_quad *qv);
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
void *mupdf_pdf_save_document(fz_context *ctx, pdf_document *doc, const char *filename, pdf_write_options *opts);
fz_alloc_context *mupdf_get_my_alloc_context();
int mupdf_get_cache_size();
int mupdf_error_code(fz_context *ctx);
char *mupdf_error_message(fz_context *ctx);
fz_matrix *mupdf_fz_scale(fz_matrix *m, float sx, float sy);
fz_matrix *mupdf_fz_translate(fz_matrix *m, float tx, float ty);
fz_matrix *mupdf_fz_pre_rotate(fz_matrix *m, float theta);
fz_matrix *mupdf_fz_pre_translate(fz_matrix *m, float tx, float ty);
fz_rect *mupdf_fz_transform_rect(fz_rect *r, const fz_matrix *m);
fz_irect *mupdf_fz_round_rect(fz_irect *ir, const fz_rect *r);
fz_rect *mupdf_fz_union_rect(fz_rect *a, const fz_rect *b);
fz_rect *mupdf_fz_rect_from_quad(fz_rect *r, const fz_quad *q);
]]
