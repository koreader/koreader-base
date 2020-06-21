local ffi = require("ffi")

ffi.cdef[[
static const int FZ_STEXT_BLOCK_TEXT = 0;
typedef struct fz_point_s fz_point;
struct fz_point_s {
  float x;
  float y;
};
typedef struct fz_rect_s fz_rect;
struct fz_rect_s {
  float x0;
  float y0;
  float x1;
  float y1;
};
extern const fz_rect fz_unit_rect;
extern const fz_rect fz_empty_rect;
extern const fz_rect fz_infinite_rect;
fz_rect fz_intersect_rect(fz_rect, fz_rect);
fz_rect fz_union_rect(fz_rect, fz_rect);
typedef struct fz_quad_s fz_quad;
struct fz_quad_s {
  fz_point ul;
  fz_point ur;
  fz_point ll;
  fz_point lr;
};
typedef struct fz_irect_s fz_irect;
struct fz_irect_s {
  int x0;
  int y0;
  int x1;
  int y1;
};
extern const fz_irect fz_empty_irect;
extern const fz_irect fz_infinite_irect;
fz_irect fz_intersect_irect(fz_irect, fz_irect);
fz_irect fz_irect_from_rect(fz_rect);
fz_irect fz_round_rect(fz_rect);
typedef struct fz_matrix_s fz_matrix;
struct fz_matrix_s {
  float a;
  float b;
  float c;
  float d;
  float e;
  float f;
};
extern const fz_matrix fz_identity;
fz_matrix fz_concat(fz_matrix, fz_matrix);
fz_matrix fz_scale(float, float);
fz_matrix fz_pre_scale(fz_matrix, float, float);
fz_matrix fz_rotate(float);
fz_matrix fz_pre_rotate(fz_matrix, float);
fz_matrix fz_translate(float, float);
fz_matrix fz_pre_translate(fz_matrix, float, float);
fz_rect fz_transform_rect(fz_rect, fz_matrix);
typedef struct fz_locks_context_s fz_locks_context;
struct fz_locks_context_s {
  void *user;
  void (*lock)(void *, int);
  void (*unlock)(void *, int);
};
typedef struct fz_alloc_context_s fz_alloc_context;
struct fz_alloc_context_s {
  void *user;
  void *(*malloc)(void *, unsigned int);
  void *(*realloc)(void *, void *, unsigned int);
  void (*free)(void *, void *);
};
typedef struct fz_error_stack_slot_s fz_error_stack_slot;
typedef struct fz_error_context_s fz_error_context;
typedef struct fz_warn_context_s fz_warn_context;
struct fz_warn_context_s {
  char message[256];
  int count;
};
typedef struct fz_font_context_s fz_font_context;
struct fz_font_context_s;
typedef struct fz_colorspace_context_s fz_colorspace_context;
struct fz_colorspace_context_s;
typedef struct fz_cmm_instance_s fz_cmm_instance;
struct fz_cmm_instance_s;
typedef struct fz_aa_context_s fz_aa_context;
struct fz_aa_context_s;
typedef struct fz_style_context_s fz_style_context;
struct fz_style_context_s;
typedef struct fz_store_s fz_store;
struct fz_store_s;
typedef struct fz_glyph_cache_s fz_glyph_cache;
struct fz_glyph_cache_s;
typedef struct fz_tuning_context_s fz_tuning_context;
struct fz_tuning_context_s;
typedef struct fz_document_handler_context_s fz_document_handler_context;
struct fz_document_handler_context_s;
typedef struct fz_output_context_s fz_output_context;
struct fz_output_context_s;
typedef struct fz_context_s fz_context;
struct fz_context_s {
  void *user;
  const fz_alloc_context *alloc;
  fz_locks_context locks;
  fz_error_context *error;
  fz_warn_context *warn;
  fz_font_context *font;
  fz_colorspace_context *colorspace;
  fz_cmm_instance *cmm_instance;
  fz_aa_context *aa;
  fz_style_context *style;
  fz_store *store;
  fz_glyph_cache *glyph_cache;
  fz_tuning_context *tuning;
  fz_document_handler_context *handler;
  fz_output_context *output;
  short unsigned int seed48[7];
};
typedef struct fz_font_s fz_font;
struct fz_font_s;
typedef struct fz_hash_table_s fz_hash_table;
struct fz_hash_table_s;
typedef struct fz_storable_s fz_storable;
typedef void fz_store_drop_fn(fz_context *, fz_storable *);
struct fz_storable_s {
  int refs;
  fz_store_drop_fn *drop;
};
typedef struct fz_key_storable_s fz_key_storable;
struct fz_key_storable_s {
  fz_storable storable;
  short int store_key_refs;
};
void fz_install_external_font_funcs(fz_context *);
typedef struct fz_buffer_s fz_buffer;
struct fz_buffer_s;
fz_buffer *mupdf_new_buffer_from_shared_data(fz_context *, const unsigned char *, unsigned int);
void *mupdf_drop_buffer(fz_context *, fz_buffer *);
typedef struct fz_color_params_s fz_color_params;
struct fz_color_params_s {
  unsigned char ri;
  unsigned char bp;
  unsigned char op;
  unsigned char opm;
};
typedef struct fz_colorspace_s fz_colorspace;
struct fz_colorspace_s;
typedef struct fz_default_colorspaces_s fz_default_colorspaces;
struct fz_default_colorspaces_s;
fz_context *fz_new_context_imp(const fz_alloc_context *, const fz_locks_context *, unsigned int, const char *);
void fz_drop_context(fz_context *);
void fz_register_document_handlers(fz_context *);
typedef struct fz_separations_s fz_separations;
struct fz_separations_s;
typedef struct fz_pixmap_s fz_pixmap;
struct fz_pixmap_s {
  fz_storable storable;
  int x;
  int y;
  int w;
  int h;
  unsigned char n;
  unsigned char s;
  unsigned char alpha;
  unsigned char flags;
  int stride;
  fz_separations *seps;
  int xres;
  int yres;
  fz_colorspace *colorspace;
  unsigned char *samples;
  fz_pixmap *underlying;
};
typedef struct fz_image_s fz_image;
struct fz_image_s {
  fz_key_storable key_storable;
  int w;
  int h;
  uint8_t n;
  uint8_t bpc;
  unsigned int imagemask : 1;
  unsigned int interpolate : 1;
  unsigned int use_colorkey : 1;
  unsigned int use_decode : 1;
  unsigned int invert_cmyk_jpeg : 1;
  unsigned int decoded : 1;
  unsigned int scalable : 1;
  fz_image *mask;
  int xres;
  int yres;
  fz_colorspace *colorspace;
  void (*drop_image)(fz_context *, fz_image *);
  fz_pixmap *(*get_pixmap)(fz_context *, fz_image *, fz_irect *, int, int, int *);
  size_t (*get_size)(fz_context *, fz_image *);
  int colorkey[64];
  float decode[64];
};
struct fz_pixmap_s {
  fz_storable storable;
  int x;
  int y;
  int w;
  int h;
  unsigned char n;
  unsigned char s;
  unsigned char alpha;
  unsigned char flags;
  ptrdiff_t stride;
  struct fz_separations_s *seps;
  int xres;
  int yres;
  fz_colorspace *colorspace;
  unsigned char *samples;
  fz_pixmap *underlying;
};
fz_image *mupdf_new_image_from_buffer(fz_context *, struct fz_buffer_s *);
fz_pixmap *mupdf_get_pixmap_from_image(fz_context *, fz_image *, const fz_irect *, fz_matrix *, int *, int *);
void *mupdf_save_pixmap_as_png(fz_context *, fz_pixmap *, const char *);
fz_image *fz_keep_image(fz_context *, fz_image *);
void fz_drop_image(fz_context *, fz_image *);
fz_pixmap *fz_load_png(fz_context *, const unsigned char *, size_t);
int fz_runetochar(char *, int);
typedef struct fz_path_s fz_path;
struct fz_path_s;
typedef struct fz_stroke_state_s fz_stroke_state;
enum fz_linecap_e {
  FZ_LINECAP_BUTT = 0,
  FZ_LINECAP_ROUND = 1,
  FZ_LINECAP_SQUARE = 2,
  FZ_LINECAP_TRIANGLE = 3,
};
enum fz_linejoin_e {
  FZ_LINEJOIN_MITER = 0,
  FZ_LINEJOIN_ROUND = 1,
  FZ_LINEJOIN_BEVEL = 2,
  FZ_LINEJOIN_MITER_XPS = 3,
};
struct fz_stroke_state_s {
  int refs;
  enum fz_linecap_e start_cap;
  enum fz_linecap_e dash_cap;
  enum fz_linecap_e end_cap;
  enum fz_linejoin_e linejoin;
  float linewidth;
  float miterlimit;
  float dash_phase;
  int dash_len;
  float dash_list[32];
};
typedef struct fz_text_item_s fz_text_item;
struct fz_text_item_s {
  float x;
  float y;
  int gid;
  int ucs;
};
typedef struct fz_text_span_s fz_text_span;
struct fz_text_span_s {
  fz_font *font;
  fz_matrix trm;
  unsigned int wmode : 1;
  unsigned int bidi_level : 7;
  unsigned int markup_dir : 2;
  unsigned int language : 15;
  int len;
  int cap;
  fz_text_item *items;
  fz_text_span *next;
};
typedef struct fz_text_s fz_text;
struct fz_text_s {
  int refs;
  fz_text_span *head;
  fz_text_span *tail;
};
typedef struct fz_jbig2_globals_s fz_jbig2_globals;
struct fz_jbig2_globals_s;
typedef struct fz_compression_params_s fz_compression_params;
struct fz_compression_params_s {
  int type;
  union {
    struct {
      int color_transform;
    } jpeg;
    struct {
      int smask_in_data;
    } jpx;
    struct {
      fz_jbig2_globals *globals;
    } jbig2;
    struct {
      int columns;
      int rows;
      int k;
      int end_of_line;
      int encoded_byte_align;
      int end_of_block;
      int black_is_1;
      int damaged_rows_before_error;
    } fax;
    struct {
      int columns;
      int colors;
      int predictor;
      int bpc;
    } flate;
    struct {
      int columns;
      int colors;
      int predictor;
      int bpc;
      int early_change;
    } lzw;
  } u;
};
typedef struct fz_compressed_buffer_s fz_compressed_buffer;
struct fz_compressed_buffer_s {
  fz_compression_params params;
  fz_buffer *buffer;
};
typedef struct fz_shade_s fz_shade;
struct fz_shade_s {
  fz_storable storable;
  fz_rect bbox;
  fz_colorspace *colorspace;
  fz_matrix matrix;
  int use_background;
  float background[32];
  int use_function;
  float function[256][33];
  int type;
  union {
    struct {
      int extend[2];
      float coords[2][3];
    } l_or_r;
    struct {
      int vprow;
      int bpflag;
      int bpcoord;
      int bpcomp;
      float x0;
      float x1;
      float y0;
      float y1;
      float c0[32];
      float c1[32];
    } m;
    struct {
      fz_matrix matrix;
      int xdivs;
      int ydivs;
      float domain[2][2];
      float *fn_vals;
    } f;
  } u;
  fz_compressed_buffer *buffer;
};
typedef struct fz_device_container_stack_s fz_device_container_stack;
struct fz_device_container_stack_s;
typedef struct fz_device_s fz_device;
struct fz_device_s {
  int refs;
  int hints;
  int flags;
  void (*close_device)(fz_context *, fz_device *);
  void (*drop_device)(fz_context *, fz_device *);
  void (*fill_path)(fz_context *, fz_device *, const fz_path *, int, fz_matrix, fz_colorspace *, const float *, float, const fz_color_params *);
  void (*stroke_path)(fz_context *, fz_device *, const fz_path *, const fz_stroke_state *, fz_matrix, fz_colorspace *, const float *, float, const fz_color_params *);
  void (*clip_path)(fz_context *, fz_device *, const fz_path *, int, fz_matrix, fz_rect);
  void (*clip_stroke_path)(fz_context *, fz_device *, const fz_path *, const fz_stroke_state *, fz_matrix, fz_rect);
  void (*fill_text)(fz_context *, fz_device *, const fz_text *, fz_matrix, fz_colorspace *, const float *, float, const fz_color_params *);
  void (*stroke_text)(fz_context *, fz_device *, const fz_text *, const fz_stroke_state *, fz_matrix, fz_colorspace *, const float *, float, const fz_color_params *);
  void (*clip_text)(fz_context *, fz_device *, const fz_text *, fz_matrix, fz_rect);
  void (*clip_stroke_text)(fz_context *, fz_device *, const fz_text *, const fz_stroke_state *, fz_matrix, fz_rect);
  void (*ignore_text)(fz_context *, fz_device *, const fz_text *, fz_matrix);
  void (*fill_shade)(fz_context *, fz_device *, fz_shade *, fz_matrix, float, const fz_color_params *);
  void (*fill_image)(fz_context *, fz_device *, fz_image *, fz_matrix, float, const fz_color_params *);
  void (*fill_image_mask)(fz_context *, fz_device *, fz_image *, fz_matrix, fz_colorspace *, const float *, float, const fz_color_params *);
  void (*clip_image_mask)(fz_context *, fz_device *, fz_image *, fz_matrix, fz_rect);
  void (*pop_clip)(fz_context *, fz_device *);
  void (*begin_mask)(fz_context *, fz_device *, fz_rect, int, fz_colorspace *, const float *, const fz_color_params *);
  void (*end_mask)(fz_context *, fz_device *);
  void (*begin_group)(fz_context *, fz_device *, fz_rect, fz_colorspace *, int, int, int, float);
  void (*end_group)(fz_context *, fz_device *);
  int (*begin_tile)(fz_context *, fz_device *, fz_rect, fz_rect, float, float, fz_matrix, int);
  void (*end_tile)(fz_context *, fz_device *);
  void (*render_flags)(fz_context *, fz_device *, int, int);
  void (*set_default_colorspaces)(fz_context *, fz_device *, fz_default_colorspaces *);
  void (*begin_layer)(fz_context *, fz_device *, const char *);
  void (*end_layer)(fz_context *, fz_device *);
  fz_rect d1_rect;
  int error_depth;
  char errmess[256];
  int container_len;
  int container_cap;
  fz_device_container_stack *container;
};
typedef struct fz_cookie_s fz_cookie;
struct fz_cookie_s {
  int abort;
  int progress;
  int progress_max;
  int errors;
  int incomplete_ok;
  int incomplete;
};
typedef struct fz_annot_s fz_annot;
struct fz_annot_s {
  int refs;
  void (*drop_annot)(fz_context *, fz_annot *);
  fz_rect (*bound_annot)(fz_context *, fz_annot *);
  void (*run_annot)(fz_context *, fz_annot *, fz_device *, fz_matrix, fz_cookie *);
  fz_annot *(*next_annot)(fz_context *, fz_annot *);
};
typedef struct fz_outline_s fz_outline;
struct fz_outline_s {
  int refs;
  char *title;
  char *uri;
  int page;
  float x;
  float y;
  fz_outline *next;
  fz_outline *down;
  int is_open;
};
typedef struct fz_link_s fz_link;
struct fz_link_s {
  int refs;
  fz_link *next;
  fz_rect rect;
  void *doc;
  char *uri;
};
typedef struct fz_transition_s fz_transition;
struct fz_transition_s {
  int type;
  float duration;
  int vertical;
  int outwards;
  int direction;
  int state0;
  int state1;
};
typedef struct fz_page_s fz_page;
struct fz_page_s {
  int refs;
  int number;
  void (*drop_page)(fz_context *, fz_page *);
  fz_rect (*bound_page)(fz_context *, fz_page *);
  void (*run_page_contents)(fz_context *, fz_page *, fz_device *, fz_matrix, fz_cookie *);
  fz_link *(*load_links)(fz_context *, fz_page *);
  fz_annot *(*first_annot)(fz_context *, fz_page *);
  fz_transition *(*page_presentation)(fz_context *, fz_page *, fz_transition *, float *);
  void (*control_separation)(fz_context *, fz_page *, int, int);
  int (*separation_disabled)(fz_context *, fz_page *, int);
  fz_separations *(*separations)(fz_context *, fz_page *);
  int (*overprint)(fz_context *, fz_page *);
  fz_page **prev;
  fz_page *next;
};
typedef struct fz_document_s fz_document;
struct fz_document_s {
  int refs;
  void (*drop_document)(fz_context *, fz_document *);
  int (*needs_password)(fz_context *, fz_document *);
  int (*authenticate_password)(fz_context *, fz_document *, const char *);
  int (*has_permission)(fz_context *, fz_document *, enum {
    FZ_PERMISSION_PRINT = 112,
    FZ_PERMISSION_COPY = 99,
    FZ_PERMISSION_EDIT = 101,
    FZ_PERMISSION_ANNOTATE = 110,
  });
  fz_outline *(*load_outline)(fz_context *, fz_document *);
  void (*layout)(fz_context *, fz_document *, float, float, float);
  intptr_t (*make_bookmark)(fz_context *, fz_document *, int);
  int (*lookup_bookmark)(fz_context *, fz_document *, intptr_t);
  int (*resolve_link)(fz_context *, fz_document *, const char *, float *, float *);
  int (*count_pages)(fz_context *, fz_document *);
  fz_page *(*load_page)(fz_context *, fz_document *, int);
  int (*lookup_metadata)(fz_context *, fz_document *, const char *, char *, int);
  fz_colorspace *(*get_output_intent)(fz_context *, fz_document *);
  int did_layout;
  int is_reflowable;
  fz_page *open;
};
typedef struct fz_stream_s fz_stream;
struct fz_stream_s {
  int refs;
  int error;
  int eof;
  long long int pos;
  int avail;
  int bits;
  unsigned char *rp;
  unsigned char *wp;
  void *state;
  int (*next)(fz_context *, fz_stream *, unsigned int);
  void (*drop)(fz_context *, void *);
  void (*seek)(fz_context *, fz_stream *, long long int, int);
  int (*meta)(fz_context *, fz_stream *, int, int, void *);
};
fz_document *mupdf_open_document(fz_context *, const char *);
fz_document *mupdf_open_document_with_stream(fz_context *, const char *, struct fz_stream_s *);
int fz_is_document_reflowable(fz_context *, fz_document *);
int fz_needs_password(fz_context *, fz_document *);
int fz_authenticate_password(fz_context *, fz_document *, const char *);
void fz_drop_document(fz_context *, fz_document *);
int mupdf_count_pages(fz_context *, fz_document *);
void *mupdf_layout_document(fz_context *, fz_document *, float, float, float);
int fz_lookup_metadata(fz_context *, fz_document *, const char *, char *, int);
int fz_resolve_link(fz_context *, fz_document *, const char *, float *, float *);
fz_page *mupdf_load_page(fz_context *, fz_document *, int);
fz_rect fz_bound_page(fz_context *, fz_page *);
void fz_drop_page(fz_context *, fz_page *);
fz_link *mupdf_load_links(fz_context *, fz_page *);
void fz_drop_link(fz_context *, fz_link *);
fz_outline *mupdf_load_outline(fz_context *, fz_document *);
void fz_drop_outline(fz_context *, fz_outline *);
void *mupdf_drop_stream(fz_context *, struct fz_stream_s *);
struct fz_stream_s *mupdf_open_memory(fz_context *, const unsigned char *, size_t);
typedef struct fz_stext_char_s fz_stext_char;
struct fz_stext_char_s {
  int c;
  fz_point origin;
  fz_quad quad;
  float size;
  fz_font *font;
  fz_stext_char *next;
};
typedef struct fz_stext_line_s fz_stext_line;
struct fz_stext_line_s {
  int wmode;
  fz_point dir;
  fz_rect bbox;
  fz_stext_char *first_char;
  fz_stext_char *last_char;
  fz_stext_line *prev;
  fz_stext_line *next;
};
typedef struct fz_stext_block_s fz_stext_block;
struct fz_stext_block_s {
  int type;
  fz_rect bbox;
  union {
    struct {
      fz_stext_line *first_line;
      fz_stext_line *last_line;
    } t;
    struct {
      fz_matrix transform;
      fz_image *image;
    } i;
  } u;
  fz_stext_block *prev;
  fz_stext_block *next;
};
typedef struct fz_stext_options_s fz_stext_options;
struct fz_stext_options_s {
  int flags;
};
typedef struct fz_pool_s fz_pool;
struct fz_pool_s;
typedef struct fz_stext_page_s fz_stext_page;
struct fz_stext_page_s {
  fz_pool *pool;
  fz_rect mediabox;
  fz_stext_block *first_block;
  fz_stext_block *last_block;
};
fz_stext_page *mupdf_new_stext_page_from_page(fz_context *, fz_page *, const fz_stext_options *);
void fz_drop_stext_page(fz_context *, fz_stext_page *);
fz_pixmap *mupdf_new_pixmap(fz_context *, fz_colorspace *, int, int, fz_separations *, int);
fz_pixmap *fz_new_pixmap(fz_context *, fz_colorspace *, int, int, fz_separations *, int);
fz_pixmap *mupdf_new_pixmap_with_bbox(fz_context *, fz_colorspace *, fz_irect, fz_separations *, int);
fz_pixmap *mupdf_new_pixmap_with_data(fz_context *, fz_colorspace *, int, int, fz_separations *, int, int, unsigned char *);
fz_pixmap *mupdf_new_pixmap_with_bbox_and_data(fz_context *, fz_colorspace *, fz_irect, fz_separations *, int, unsigned char *);
fz_pixmap *fz_convert_pixmap(fz_context *, fz_pixmap *, fz_colorspace *, fz_colorspace *, fz_default_colorspaces *, const fz_color_params *, int);
fz_pixmap *fz_keep_pixmap(fz_context *, fz_pixmap *);
void fz_drop_pixmap(fz_context *, fz_pixmap *);
void fz_clear_pixmap_with_value(fz_context *, fz_pixmap *, int);
void fz_gamma_pixmap(fz_context *, fz_pixmap *, float);
fz_pixmap *fz_scale_pixmap(fz_context *, fz_pixmap *, float, float, float, float, const fz_irect *);
int fz_pixmap_width(fz_context *, fz_pixmap *);
int fz_pixmap_height(fz_context *, fz_pixmap *);
int fz_pixmap_components(fz_context *, fz_pixmap *);
unsigned char *fz_pixmap_samples(fz_context *, fz_pixmap *);
fz_colorspace *fz_device_gray(fz_context *);
fz_colorspace *fz_device_rgb(fz_context *);
fz_colorspace *fz_device_bgr(fz_context *);
struct fz_color_params_s {
  uint8_t ri;
  uint8_t bp;
  uint8_t op;
  uint8_t opm;
};
const struct fz_color_params_s *fz_default_color_params(fz_context *);
struct fz_device_s *mupdf_new_draw_device(fz_context *, const fz_matrix *, fz_pixmap *);
struct fz_device_s *mupdf_new_text_device(fz_context *, fz_stext_page *, const fz_stext_options *);
struct fz_device_s *mupdf_new_bbox_device(fz_context *, fz_rect *);
void *mupdf_run_page(fz_context *, fz_page *, struct fz_device_s *, const fz_matrix *, struct fz_cookie_s *);
void fz_close_device(fz_context *, struct fz_device_s *);
void fz_drop_device(fz_context *, struct fz_device_s *);
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
  PDF_ANNOT_STAMP = 12,
  PDF_ANNOT_CARET = 13,
  PDF_ANNOT_INK = 14,
  PDF_ANNOT_POPUP = 15,
  PDF_ANNOT_FILE_ATTACHMENT = 16,
  PDF_ANNOT_SOUND = 17,
  PDF_ANNOT_MOVIE = 18,
  PDF_ANNOT_WIDGET = 19,
  PDF_ANNOT_SCREEN = 20,
  PDF_ANNOT_PRINTER_MARK = 21,
  PDF_ANNOT_TRAP_NET = 22,
  PDF_ANNOT_WATERMARK = 23,
  PDF_ANNOT_3D = 24,
  PDF_ANNOT_UNKNOWN = -1,
};
typedef struct pdf_hotspot_s pdf_hotspot;
struct pdf_hotspot_s {
  int num;
  int state;
};
typedef struct pdf_lexbuf_s pdf_lexbuf;
struct pdf_lexbuf_s {
  int size;
  int base_size;
  int len;
  int64_t i;
  float f;
  char *scratch;
  char buffer[256];
};
typedef struct pdf_lexbuf_large_s pdf_lexbuf_large;
struct pdf_lexbuf_large_s {
  pdf_lexbuf base;
  char buffer[65280];
};
typedef struct pdf_obj_s pdf_obj;
struct pdf_obj_s;
typedef struct pdf_annot_s pdf_annot;
typedef struct pdf_crypt_s pdf_crypt;
typedef struct pdf_ocg_descriptor_s pdf_ocg_descriptor;
typedef struct pdf_portfolio_s pdf_portfolio;
typedef struct pdf_xref_entry_s pdf_xref_entry;
typedef struct pdf_xref_subsec_s pdf_xref_subsec;
typedef struct pdf_pkcs7_designated_name_s pdf_pkcs7_designated_name;
typedef struct pdf_pkcs7_signer_s pdf_pkcs7_signer;
typedef struct pdf_unsaved_sig_s pdf_unsaved_sig;
typedef struct pdf_xref_s pdf_xref;
typedef struct pdf_rev_page_map_s pdf_rev_page_map;
typedef struct pdf_js_s pdf_js;
typedef struct pdf_doc_event_s pdf_doc_event;
typedef struct pdf_document_s pdf_document;
typedef struct pdf_page_s pdf_page;
struct pdf_annot_s {
  fz_annot super;
  pdf_page *page;
  pdf_obj *obj;
  pdf_obj *ap;
  int needs_new_ap;
  int has_new_ap;
  pdf_annot *next;
};
struct pdf_page_s {
  fz_page super;
  pdf_document *doc;
  pdf_obj *obj;
  int transparency;
  int overprint;
  int incomplete;
  fz_link *links;
  pdf_annot *annots;
  pdf_annot **annot_tailp;
};
struct pdf_crypt_s;
struct pdf_ocg_descriptor_s;
struct pdf_portfolio_s;
struct pdf_xref_entry_s {
  char type;
  unsigned char flags;
  short unsigned int gen;
  int num;
  long long int ofs;
  long long int stm_ofs;
  fz_buffer *stm_buf;
  pdf_obj *obj;
};
struct pdf_xref_subsec_s {
  pdf_xref_subsec *next;
  int len;
  int start;
  pdf_xref_entry *table;
};
struct pdf_pkcs7_designated_name_s {
  char *cn;
  char *o;
  char *ou;
  char *email;
  char *c;
};
struct pdf_pkcs7_signer_s {
  pdf_pkcs7_signer *(*keep)(pdf_pkcs7_signer *);
  void (*drop)(pdf_pkcs7_signer *);
  pdf_pkcs7_designated_name *(*designated_name)(pdf_pkcs7_signer *);
  void (*drop_designated_name)(pdf_pkcs7_signer *, pdf_pkcs7_designated_name *);
  int (*max_digest_size)(pdf_pkcs7_signer *);
  int (*create_digest)(pdf_pkcs7_signer *, fz_stream *, unsigned char *, int *);
};
struct pdf_unsaved_sig_s {
  pdf_obj *field;
  int byte_range_start;
  int byte_range_end;
  int contents_start;
  int contents_end;
  pdf_pkcs7_signer *signer;
  pdf_unsaved_sig *next;
};
struct pdf_xref_s {
  int num_objects;
  pdf_xref_subsec *subsec;
  pdf_obj *trailer;
  pdf_obj *pre_repair_trailer;
  pdf_unsaved_sig *unsaved_sigs;
  pdf_unsaved_sig **unsaved_sigs_end;
  long long int end_ofs;
};
struct pdf_rev_page_map_s {
  int page;
  int object;
};
struct pdf_js_s;
struct pdf_doc_event_s {
  int type;
};
struct pdf_document_s {
  fz_document super;
  fz_stream *file;
  int version;
  int64_t startxref;
  int64_t file_size;
  struct pdf_crypt_s *crypt;
  struct pdf_ocg_descriptor_s *ocg;
  struct pdf_portfolio_s *portfolio;
  pdf_hotspot hotspot;
  fz_colorspace *oi;
  int max_xref_len;
  int num_xref_sections;
  int saved_num_xref_sections;
  int num_incremental_sections;
  int xref_base;
  int disallow_new_increments;
  pdf_xref *xref_sections;
  pdf_xref *saved_xref_sections;
  int *xref_index;
  int freeze_updates;
  int has_xref_streams;
  int has_old_style_xrefs;
  int rev_page_count;
  pdf_rev_page_map *rev_page_map;
  int repair_attempted;
  int file_reading_linearly;
  int64_t file_length;
  int linear_page_count;
  pdf_obj *linear_obj;
  pdf_obj **linear_page_refs;
  int linear_page1_obj_num;
  int64_t linear_pos;
  int linear_page_num;
  int hint_object_offset;
  int hint_object_length;
  int hints_loaded;
  struct {
    int number;
    int64_t offset;
    int64_t index;
  } *hint_page;
  int *hint_shared_ref;
  struct {
    int number;
    int64_t offset;
  } *hint_shared;
  int hint_obj_offsets_max;
  int64_t *hint_obj_offsets;
  int resources_localised;
  pdf_lexbuf_large lexbuf;
  pdf_annot *focus;
  pdf_obj *focus_obj;
  pdf_js *js;
  int recalculating;
  int dirty;
  void (*event_cb)(fz_context *, pdf_document *, pdf_doc_event *, void *);
  void *event_cb_data;
  int num_type3_fonts;
  int max_type3_fonts;
  fz_font **type3_fonts;
  struct {
    fz_hash_table *images;
    fz_hash_table *fonts;
  } resources;
  int orphans_max;
  int orphans_count;
  pdf_obj **orphans;
};
pdf_document *pdf_specifics(fz_context *, fz_document *);
pdf_annot *mupdf_pdf_create_annot(fz_context *, pdf_page *, enum pdf_annot_type);
void *mupdf_pdf_set_annot_quad_points(fz_context *, pdf_annot *, int, const float *);
void *mupdf_pdf_set_text_annot_position(fz_context *, pdf_annot *, fz_point);
void *mupdf_pdf_set_markup_appearance(fz_context *, pdf_document *, pdf_annot *, float *, float, float, float);
typedef struct pdf_write_options_s pdf_write_options;
struct pdf_write_options_s {
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
  int continue_on_error;
  int *errors;
};
void *mupdf_pdf_save_document(fz_context *, pdf_document *, const char *, pdf_write_options *);
fz_alloc_context *mupdf_get_my_alloc_context();
int mupdf_get_cache_size();
int mupdf_error_code(fz_context *);
char *mupdf_error_message(fz_context *);
]]
