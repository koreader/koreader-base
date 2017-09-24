local ffi = require("ffi")

ffi.cdef[[
static const int FZ_PAGE_BLOCK_TEXT = 0;
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
fz_rect *fz_intersect_rect(fz_rect *restrict, const fz_rect *restrict);
fz_rect *fz_union_rect(fz_rect *restrict, const fz_rect *restrict);
typedef struct fz_irect_s fz_irect;
struct fz_irect_s {
  int x0;
  int y0;
  int x1;
  int y1;
};
extern const fz_irect fz_empty_irect;
extern const fz_irect fz_infinite_irect;
fz_irect *fz_intersect_irect(fz_irect *restrict, const fz_irect *restrict);
fz_irect *fz_irect_from_rect(fz_irect *restrict, const fz_rect *restrict);
fz_irect *fz_round_rect(fz_irect *restrict, const fz_rect *restrict);
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
fz_matrix *fz_concat(fz_matrix *, const fz_matrix *, const fz_matrix *);
fz_matrix *fz_scale(fz_matrix *, float, float);
fz_matrix *fz_pre_scale(fz_matrix *, float, float);
fz_matrix *fz_rotate(fz_matrix *, float);
fz_matrix *fz_pre_rotate(fz_matrix *, float);
fz_matrix *fz_translate(fz_matrix *, float, float);
fz_matrix *fz_pre_translate(fz_matrix *, float, float);
fz_rect *fz_transform_rect(fz_rect *restrict, const fz_matrix *restrict);
typedef struct fz_context_s fz_context;
typedef struct fz_storable_s fz_storable;
typedef void fz_store_drop_fn(fz_context *, fz_storable *);
struct fz_storable_s {
  int refs;
  fz_store_drop_fn *drop;
};
typedef struct fz_alloc_context_s fz_alloc_context;
typedef struct fz_colorspace_s fz_colorspace;
fz_context *fz_new_context_imp(fz_alloc_context *, struct fz_locks_context_s *, unsigned int, const char *);
void fz_drop_context(fz_context *);
void fz_register_document_handlers(fz_context *);
typedef struct fz_image_s fz_image;
typedef struct fz_pixmap_s fz_pixmap;
struct fz_image_s {
  fz_storable storable;
  int w;
  int h;
  int n;
  int bpc;
  fz_image *mask;
  fz_colorspace *colorspace;
  fz_pixmap *(*get_pixmap)(fz_context *, fz_image *, int, int, int *);
  int colorkey[64];
  float decode[64];
  int imagemask;
  int interpolate;
  int usecolorkey;
  int xres;
  int yres;
  int invert_cmyk_jpeg;
  struct fz_compressed_buffer_s *buffer;
  fz_pixmap *tile;
};
struct fz_pixmap_s {
  fz_storable storable;
  int x;
  int y;
  int w;
  int h;
  int n;
  int interpolate;
  int xres;
  int yres;
  fz_colorspace *colorspace;
  unsigned char *samples;
  int free_samples;
};
fz_image *fz_new_image_from_data(fz_context *, unsigned char *, int);
fz_image *mupdf_new_image_from_data(fz_context *, unsigned char *, int);
fz_pixmap *fz_new_pixmap_from_image(fz_context *, fz_image *, int, int);
fz_pixmap *mupdf_new_pixmap_from_image(fz_context *, fz_image *, int, int);
fz_image *fz_keep_image(fz_context *, fz_image *);
void fz_drop_image(fz_context *, fz_image *);
fz_pixmap *fz_load_png(fz_context *, unsigned char *, int);
int fz_runetochar(char *, int);
enum fz_link_kind_e {
  FZ_LINK_NONE = 0,
  FZ_LINK_GOTO = 1,
  FZ_LINK_URI = 2,
  FZ_LINK_LAUNCH = 3,
  FZ_LINK_NAMED = 4,
  FZ_LINK_GOTOR = 5,
};
typedef struct fz_link_dest_s fz_link_dest;
struct fz_link_dest_s {
  enum fz_link_kind_e kind;
  union {
    struct {
      int page;
      char *dest;
      int flags;
      fz_point lt;
      fz_point rb;
      char *file_spec;
      int new_window;
    } gotor;
    struct {
      char *uri;
      int is_map;
    } uri;
    struct {
      char *file_spec;
      int new_window;
      int is_uri;
    } launch;
    struct {
      char *named;
    } named;
  } ld;
};
typedef struct fz_outline_s fz_outline;
struct fz_outline_s {
  int refs;
  char *title;
  fz_link_dest dest;
  fz_outline *next;
  fz_outline *down;
  int is_open;
};
typedef struct fz_document_s fz_document;
typedef struct fz_page_s fz_page;
typedef struct fz_write_options_s fz_write_options;
struct fz_document_s {
  int refs;
  void (*close)(fz_context *, fz_document *);
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
  int (*count_pages)(fz_context *, fz_document *);
  fz_page *(*load_page)(fz_context *, fz_document *, int);
  int (*lookup_metadata)(fz_context *, fz_document *, const char *, char *, int);
  void (*write)(fz_context *, fz_document *, char *, fz_write_options *);
  int did_layout;
};
typedef struct fz_link_s fz_link;
struct fz_page_s {
  int refs;
  void (*drop_page_imp)(fz_context *, fz_page *);
  fz_rect *(*bound_page)(fz_context *, fz_page *, fz_rect *);
  void (*run_page_contents)(fz_context *, fz_page *, struct fz_device_s *, const fz_matrix *, struct fz_cookie_s *);
  fz_link *(*load_links)(fz_context *, fz_page *);
  struct fz_annot_s *(*first_annot)(fz_context *, fz_page *);
  struct fz_annot_s *(*next_annot)(fz_context *, fz_page *, struct fz_annot_s *);
  fz_rect *(*bound_annot)(fz_context *, fz_page *, struct fz_annot_s *, fz_rect *);
  void (*run_annot)(fz_context *, fz_page *, struct fz_annot_s *, struct fz_device_s *, const fz_matrix *, struct fz_cookie_s *);
  struct fz_transition_s *(*page_presentation)(fz_context *, fz_page *, float *);
  void (*control_separation)(fz_context *, fz_page *, int, int);
  int (*separation_disabled)(fz_context *, fz_page *, int);
  int (*count_separations)(fz_context *, fz_page *);
  const char *(*get_separation)(fz_context *, fz_page *, int, unsigned int *, unsigned int *);
};
fz_document *mupdf_open_document(fz_context *, const char *);
int fz_needs_password(fz_context *, fz_document *);
int fz_authenticate_password(fz_context *, fz_document *, const char *);
void fz_drop_document(fz_context *, fz_document *);
int mupdf_count_pages(fz_context *, fz_document *);
int fz_lookup_metadata(fz_context *, fz_document *, const char *, char *, int);
fz_page *mupdf_load_page(fz_context *, fz_document *, int);
fz_rect *fz_bound_page(fz_context *, fz_page *, fz_rect *);
void fz_drop_page(fz_context *, fz_page *);
struct fz_link_s {
  int refs;
  fz_rect rect;
  fz_link_dest dest;
  fz_link *next;
};
fz_link *mupdf_load_links(fz_context *, fz_page *);
void fz_drop_link(fz_context *, fz_link *);
fz_outline *mupdf_load_outline(fz_context *, fz_document *);
void fz_drop_outline(fz_context *, fz_outline *);
typedef struct fz_text_style_s fz_text_style;
struct fz_text_style_s {
  fz_text_style *next;
  int id;
  struct fz_font_s *font;
  float size;
  int wmode;
  int script;
  float ascender;
  float descender;
};
typedef struct fz_text_char_s fz_text_char;
struct fz_text_char_s {
  fz_point p;
  int c;
  fz_text_style *style;
};
typedef struct fz_text_span_s fz_text_span;
struct fz_text_span_s {
  int len;
  int cap;
  fz_text_char *text;
  fz_point min;
  fz_point max;
  int wmode;
  fz_matrix transform;
  float ascender_max;
  float descender_min;
  fz_rect bbox;
  float base_offset;
  float spacing;
  int column;
  float column_width;
  int align;
  float indent;
  fz_text_span *next;
};
typedef struct fz_text_line_s fz_text_line;
struct fz_text_line_s {
  fz_text_span *first_span;
  fz_text_span *last_span;
  float distance;
  fz_rect bbox;
  void *region;
};
typedef struct fz_text_sheet_s fz_text_sheet;
struct fz_text_sheet_s {
  int maxid;
  fz_text_style *style;
};
fz_text_sheet *mupdf_new_text_sheet(fz_context *);
void fz_drop_text_sheet(fz_context *, fz_text_sheet *);
typedef struct fz_text_page_s fz_text_page;
typedef struct fz_page_block_s fz_page_block;
struct fz_text_page_s {
  fz_rect mediabox;
  int len;
  int cap;
  fz_page_block *blocks;
  fz_text_page *next;
};
fz_text_page *mupdf_new_text_page(fz_context *);
void fz_drop_text_page(fz_context *, fz_text_page *);
typedef struct fz_text_block_s fz_text_block;
struct fz_page_block_s {
  int type;
  union {
    fz_text_block *text;
    struct fz_image_block_s *image;
  } u;
};
struct fz_text_block_s {
  fz_rect bbox;
  int len;
  int cap;
  fz_text_line *lines;
};
fz_rect *fz_text_char_bbox(fz_context *, fz_rect *, fz_text_span *, int);
fz_pixmap *mupdf_new_pixmap(fz_context *, fz_colorspace *, int, int);
fz_pixmap *fz_new_pixmap(fz_context *, fz_colorspace *, int, int);
fz_pixmap *mupdf_new_pixmap_with_bbox(fz_context *, fz_colorspace *, const fz_irect *);
fz_pixmap *mupdf_new_pixmap_with_data(fz_context *, fz_colorspace *, int, int, unsigned char *);
fz_pixmap *mupdf_new_pixmap_with_bbox_and_data(fz_context *, fz_colorspace *, const fz_irect *, unsigned char *);
fz_pixmap *fz_scale_pixmap(fz_context *, fz_pixmap *, float, float, float, float, fz_irect *);
void fz_convert_pixmap(fz_context *, fz_pixmap *, fz_pixmap *);
fz_pixmap *fz_keep_pixmap(fz_context *, fz_pixmap *);
void fz_drop_pixmap(fz_context *, fz_pixmap *);
void fz_clear_pixmap_with_value(fz_context *, fz_pixmap *, int);
void fz_gamma_pixmap(fz_context *, fz_pixmap *, float);
int fz_pixmap_width(fz_context *, fz_pixmap *);
int fz_pixmap_height(fz_context *, fz_pixmap *);
int fz_pixmap_components(fz_context *, fz_pixmap *);
unsigned char *fz_pixmap_samples(fz_context *, fz_pixmap *);
fz_colorspace *fz_device_gray(fz_context *);
fz_colorspace *fz_device_rgb(fz_context *);
struct fz_device_s *mupdf_new_draw_device(fz_context *, fz_pixmap *);
struct fz_device_s *mupdf_new_text_device(fz_context *, fz_text_sheet *, fz_text_page *);
struct fz_device_s *mupdf_new_bbox_device(fz_context *, fz_rect *);
void *mupdf_run_page(fz_context *, fz_page *, struct fz_device_s *, const fz_matrix *, struct fz_cookie_s *);
void fz_drop_device(fz_context *, struct fz_device_s *);
typedef struct pdf_hotspot_s pdf_hotspot;
struct pdf_hotspot_s {
  int num;
  int gen;
  int state;
};
typedef struct pdf_lexbuf_s pdf_lexbuf;
struct pdf_lexbuf_s {
  int size;
  int base_size;
  int len;
  int i;
  float f;
  char *scratch;
  char buffer[256];
};
typedef struct pdf_lexbuf_large_s pdf_lexbuf_large;
struct pdf_lexbuf_large_s {
  pdf_lexbuf base;
  char buffer[65280];
};
typedef struct pdf_annot_s pdf_annot;
typedef struct pdf_page_s pdf_page;
struct pdf_annot_s {
  pdf_page *page;
  struct pdf_obj_s *obj;
  fz_rect rect;
  fz_rect pagerect;
  struct pdf_xobject_s *ap;
  int ap_iteration;
  fz_matrix matrix;
  pdf_annot *next;
  pdf_annot *next_changed;
  int annot_type;
  int widget_type;
};
typedef struct pdf_document_s pdf_document;
struct pdf_document_s {
  fz_document super;
  struct fz_stream_s *file;
  int version;
  int startxref;
  int file_size;
  struct pdf_crypt_s *crypt;
  struct pdf_ocg_descriptor_s *ocg;
  pdf_hotspot hotspot;
  int max_xref_len;
  int num_xref_sections;
  int num_incremental_sections;
  int xref_base;
  int disallow_new_increments;
  struct pdf_xref_s *xref_sections;
  int *xref_index;
  int freeze_updates;
  int has_xref_streams;
  int page_count;
  int repair_attempted;
  int file_reading_linearly;
  int file_length;
  struct pdf_obj_s *linear_obj;
  struct pdf_obj_s **linear_page_refs;
  int linear_page1_obj_num;
  int linear_pos;
  int linear_page_num;
  int hint_object_offset;
  int hint_object_length;
  int hints_loaded;
  struct {
    int number;
    int offset;
    int index;
  } *hint_page;
  int *hint_shared_ref;
  struct {
    int number;
    int offset;
  } *hint_shared;
  int hint_obj_offsets_max;
  int *hint_obj_offsets;
  int resources_localised;
  pdf_lexbuf_large lexbuf;
  pdf_annot *focus;
  struct pdf_obj_s *focus_obj;
  struct pdf_js_s *js;
  void (*drop_js)(struct pdf_js_s *);
  int recalculating;
  int dirty;
  void (*update_appearance)(fz_context *, pdf_document *, pdf_annot *);
  void (*event_cb)(fz_context *, pdf_document *, struct pdf_doc_event_s *, void *);
  void *event_cb_data;
  int num_type3_fonts;
  int max_type3_fonts;
  struct fz_font_s **type3_fonts;
};
pdf_document *pdf_specifics(fz_context *, fz_document *);
pdf_annot *mupdf_pdf_create_annot(fz_context *, pdf_document *, pdf_page *, enum {
  FZ_ANNOT_TEXT = 0,
  FZ_ANNOT_LINK = 1,
  FZ_ANNOT_FREETEXT = 2,
  FZ_ANNOT_LINE = 3,
  FZ_ANNOT_SQUARE = 4,
  FZ_ANNOT_CIRCLE = 5,
  FZ_ANNOT_POLYGON = 6,
  FZ_ANNOT_POLYLINE = 7,
  FZ_ANNOT_HIGHLIGHT = 8,
  FZ_ANNOT_UNDERLINE = 9,
  FZ_ANNOT_SQUIGGLY = 10,
  FZ_ANNOT_STRIKEOUT = 11,
  FZ_ANNOT_STAMP = 12,
  FZ_ANNOT_CARET = 13,
  FZ_ANNOT_INK = 14,
  FZ_ANNOT_POPUP = 15,
  FZ_ANNOT_FILEATTACHMENT = 16,
  FZ_ANNOT_SOUND = 17,
  FZ_ANNOT_MOVIE = 18,
  FZ_ANNOT_WIDGET = 19,
  FZ_ANNOT_SCREEN = 20,
  FZ_ANNOT_PRINTERMARK = 21,
  FZ_ANNOT_TRAPNET = 22,
  FZ_ANNOT_WATERMARK = 23,
  FZ_ANNOT_3D = 24,
});
void *mupdf_pdf_set_markup_annot_quadpoints(fz_context *, pdf_document *, pdf_annot *, fz_point *, int);
void *mupdf_pdf_set_markup_appearance(fz_context *, pdf_document *, pdf_annot *, float *, float, float, float);
struct fz_write_options_s {
  int do_incremental;
  int do_ascii;
  int do_deflate;
  int do_expand;
  int do_garbage;
  int do_linear;
  int do_clean;
  int continue_on_error;
  int *errors;
};
void *mupdf_write_document(fz_context *, fz_document *, char *, fz_write_options *);
fz_alloc_context *mupdf_get_my_alloc_context();
int mupdf_get_cache_size();
int mupdf_error_code(fz_context *);
char *mupdf_error_message(fz_context *);
]]
