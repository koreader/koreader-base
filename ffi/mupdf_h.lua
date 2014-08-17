local ffi = require("ffi")
ffi.cdef[[
typedef struct fz_alloc_context_s fz_alloc_context;
typedef struct fz_locks_context_s fz_locks_context;
typedef struct fz_colorspace_s fz_colorspace;
typedef struct fz_document_s fz_document;
typedef struct fz_context_s fz_context;
typedef struct fz_matrix_s fz_matrix;
typedef struct fz_cookie_s fz_cookie;
typedef struct fz_pixmap_s fz_pixmap;
typedef struct fz_device_s fz_device;
typedef struct fz_image_s fz_image;
typedef struct fz_irect_s fz_irect;
typedef struct fz_rect_s fz_rect;
typedef struct fz_page_s fz_page;

struct fz_matrix_s {
  float a, b, c, d, e, f;
};
struct fz_rect_s {
  float x0, y0;
  float x1, y1;
};
struct fz_irect_s {
  int x0, y0;
  int x1, y1;
};

typedef void fz_store_free_fn(struct fz_context_s *, struct fz_storable_s *);
struct fz_storable_s {
  int refs;
  void (*free)(struct fz_context_s *, struct fz_storable_s *);
};
typedef struct fz_storable_s fz_storable;
struct fz_pixmap_s {
  struct fz_storable_s storable;
  int x;
  int y;
  int w;
  int h;
  int n;
  int interpolate;
  int xres;
  int yres;
  struct fz_colorspace_s *colorspace;
  unsigned char *samples;
  int free_samples;
};

fz_context *fz_new_context_imp(fz_alloc_context*, fz_locks_context*, unsigned int, const char *);
void fz_register_document_handlers(fz_context *ctx);
fz_colorspace *fz_device_gray(fz_context*);
fz_colorspace *fz_device_rgb(fz_context *ctx);
fz_document *fz_open_document(fz_context *ctx, const char *filename);
int fz_count_pages(fz_document *doc);
fz_page *fz_load_page(fz_document *doc, int number);
fz_rect *fz_bound_page(fz_document *doc, fz_page *page, fz_rect *rect);
fz_matrix *fz_scale(fz_matrix *m, float sx, float sy);
fz_rect *fz_transform_rect(fz_rect *restrict rect, const fz_matrix *restrict transform);
fz_irect *fz_round_rect(fz_irect *restrict bbox, const fz_rect *restrict rect);
void fz_clear_pixmap_with_value(fz_context *ctx, fz_pixmap *pix, int value);
void fz_run_page(fz_document *doc, fz_page *page, fz_device *dev, const fz_matrix *transform, fz_cookie *cookie);
fz_pixmap *fz_new_pixmap_with_bbox(fz_context *ctx, fz_colorspace *colorspace, const fz_irect *bbox);
fz_device *fz_new_draw_device(fz_context *ctx, fz_pixmap *dest);
void fz_free_device(fz_device *dev);
fz_pixmap *fz_new_pixmap(fz_context*, fz_colorspace *, int, int);
void fz_convert_pixmap(fz_context*, fz_pixmap*, fz_pixmap*);
int fz_pixmap_width(fz_context *ctx, fz_pixmap *pix);
int fz_pixmap_height(fz_context *ctx, fz_pixmap *pix);
int fz_pixmap_components(fz_context *ctx, fz_pixmap *pix);
unsigned char *fz_pixmap_samples(fz_context *ctx, fz_pixmap *pix);
void fz_keep_pixmap(fz_context*, fz_pixmap*);
void fz_drop_pixmap(fz_context*, fz_pixmap*);
void fz_free_page(fz_document *doc, fz_page *page);
void fz_free_context(fz_context*);
void fz_close_document(fz_document *doc);
fz_image *fz_new_image_from_data(fz_context*, unsigned char*, int);
fz_pixmap *fz_new_pixmap_from_image(fz_context*, fz_image*, int, int);
void fz_keep_image(fz_context*, fz_image*);
void fz_drop_image(fz_context*, fz_image*);
]]
