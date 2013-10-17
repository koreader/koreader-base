local ffi = require("ffi")
ffi.cdef[[
typedef struct fz_alloc_context_s fz_alloc_context;
typedef struct fz_colorspace_s fz_colorspace;
typedef struct fz_context_s fz_context;
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
typedef struct fz_pixmap_s fz_pixmap;
struct fz_context_s *fz_new_context_imp(struct fz_alloc_context_s *, struct fz_locks_context_s *, unsigned int, const char *);
struct fz_pixmap_s *fz_new_pixmap(struct fz_context_s *, struct fz_colorspace_s *, int, int);
void fz_convert_pixmap(struct fz_context_s *, struct fz_pixmap_s *, struct fz_pixmap_s *);
void fz_drop_pixmap(struct fz_context_s *, struct fz_pixmap_s *);
struct fz_colorspace_s *fz_device_gray(struct fz_context_s *);
void fz_free_context(struct fz_context_s *);
struct fz_pixmap_s *fz_load_png(struct fz_context_s *, unsigned char *, int);
]]
