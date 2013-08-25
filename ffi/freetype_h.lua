local ffi = require("ffi")
ffi.cdef[[
typedef int FT_Error;
struct FT_Generic_ {
  void *data;
  void (*finalizer)(void *);
};
typedef struct FT_Generic_ FT_Generic;
struct FT_ListNodeRec_ {
  struct FT_ListNodeRec_ *prev;
  struct FT_ListNodeRec_ *next;
  void *data;
};
typedef struct FT_ListNodeRec_ *FT_ListNode;
struct FT_ListRec_ {
  struct FT_ListNodeRec_ *head;
  struct FT_ListNodeRec_ *tail;
};
typedef struct FT_ListRec_ *FT_List;
struct FT_BBox_ {
  long int xMin;
  long int yMin;
  long int xMax;
  long int yMax;
};
typedef struct FT_BBox_ FT_BBox;
struct FT_FaceRec_ {
  long int num_faces;
  long int face_index;
  long int face_flags;
  long int style_flags;
  long int num_glyphs;
  char *family_name;
  char *style_name;
  int num_fixed_sizes;
  struct FT_Bitmap_Size_ *available_sizes;
  int num_charmaps;
  struct FT_CharMapRec_ **charmaps;
  struct FT_Generic_ generic;
  struct FT_BBox_ bbox;
  short unsigned int units_per_EM;
  short int ascender;
  short int descender;
  short int height;
  short int max_advance_width;
  short int max_advance_height;
  short int underline_position;
  short int underline_thickness;
  struct FT_GlyphSlotRec_ *glyph;
  struct FT_SizeRec_ *size;
  struct FT_CharMapRec_ *charmap;
  struct FT_DriverRec_ *driver;
  struct FT_MemoryRec_ *memory;
  struct FT_StreamRec_ *stream;
  struct FT_ListRec_ sizes_list;
  struct FT_Generic_ autohint;
  void *extensions;
  struct FT_Face_InternalRec_ *internal;
};
typedef struct FT_FaceRec_ *FT_Face;
struct FT_Face_InternalRec_;
typedef struct FT_Face_InternalRec_ *FT_Face_Internal;
struct FT_LibraryRec_;
typedef struct FT_LibraryRec_ *FT_Library;
struct FT_Bitmap_Size_ {
  short int height;
  short int width;
  long int size;
  long int x_ppem;
  long int y_ppem;
};
typedef struct FT_Bitmap_Size_ FT_Bitmap_Size;
struct FT_Bitmap_ {
  int rows;
  int width;
  int pitch;
  unsigned char *buffer;
  short int num_grays;
  char pixel_mode;
  char palette_mode;
  void *palette;
};
typedef struct FT_Bitmap_ FT_Bitmap;
struct FT_Outline_ {
  short int n_contours;
  short int n_points;
  struct FT_Vector_ *points;
  char *tags;
  short int *contours;
  int flags;
};
typedef struct FT_Outline_ FT_Outline;
struct FT_SubGlyphRec_;
typedef struct FT_SubGlyphRec_ *FT_SubGlyph;
enum FT_Encoding_ {
  FT_ENCODING_NONE = 0,
  FT_ENCODING_MS_SYMBOL = 1937337698,
  FT_ENCODING_UNICODE = 1970170211,
  FT_ENCODING_SJIS = 1936353651,
  FT_ENCODING_GB2312 = 1734484000,
  FT_ENCODING_BIG5 = 1651074869,
  FT_ENCODING_WANSUNG = 2002873971,
  FT_ENCODING_JOHAB = 1785686113,
  FT_ENCODING_MS_SJIS = 1936353651,
  FT_ENCODING_MS_GB2312 = 1734484000,
  FT_ENCODING_MS_BIG5 = 1651074869,
  FT_ENCODING_MS_WANSUNG = 2002873971,
  FT_ENCODING_MS_JOHAB = 1785686113,
  FT_ENCODING_ADOBE_STANDARD = 1094995778,
  FT_ENCODING_ADOBE_EXPERT = 1094992453,
  FT_ENCODING_ADOBE_CUSTOM = 1094992451,
  FT_ENCODING_ADOBE_LATIN_1 = 1818326065,
  FT_ENCODING_OLD_LATIN_2 = 1818326066,
  FT_ENCODING_APPLE_ROMAN = 1634889070,
};
typedef enum FT_Encoding_ FT_Encoding;
struct FT_CharMapRec_ {
  struct FT_FaceRec_ *face;
  enum FT_Encoding_ encoding;
  short unsigned int platform_id;
  short unsigned int encoding_id;
};
typedef struct FT_CharMapRec_ *FT_CharMap;
struct FT_Vector_ {
  long int x;
  long int y;
};
typedef struct FT_Vector_ FT_Vector;
enum FT_Glyph_Format_ {
  FT_GLYPH_FORMAT_NONE = 0,
  FT_GLYPH_FORMAT_COMPOSITE = 1668246896,
  FT_GLYPH_FORMAT_BITMAP = 1651078259,
  FT_GLYPH_FORMAT_OUTLINE = 1869968492,
  FT_GLYPH_FORMAT_PLOTTER = 1886154612,
};
typedef enum FT_Glyph_Format_ FT_Glyph_Format;
struct FT_Slot_InternalRec_;
typedef struct FT_Slot_InternalRec_ *FT_Slot_Internal;
struct FT_Glyph_Metrics_ {
  long int width;
  long int height;
  long int horiBearingX;
  long int horiBearingY;
  long int horiAdvance;
  long int vertBearingX;
  long int vertBearingY;
  long int vertAdvance;
};
typedef struct FT_Glyph_Metrics_ FT_Glyph_Metrics;
struct FT_Size_Metrics_ {
  short unsigned int x_ppem;
  short unsigned int y_ppem;
  long int x_scale;
  long int y_scale;
  long int ascender;
  long int descender;
  long int height;
  long int max_advance;
};
typedef struct FT_Size_Metrics_ FT_Size_Metrics;
struct FT_Size_InternalRec_;
typedef struct FT_Size_InternalRec_ *FT_Size_Internal;
struct FT_SizeRec_ {
  struct FT_FaceRec_ *face;
  struct FT_Generic_ generic;
  struct FT_Size_Metrics_ metrics;
  struct FT_Size_InternalRec_ *internal;
};
typedef struct FT_SizeRec_ *FT_Size;
struct FT_DriverRec_;
typedef struct FT_DriverRec_ *FT_Driver;
struct FT_MemoryRec_ {
  void *user;
  void *(*alloc)(struct FT_MemoryRec_ *, long int);
  void (*free)(struct FT_MemoryRec_ *, void *);
  void *(*realloc)(struct FT_MemoryRec_ *, long int, long int, void *);
};
typedef struct FT_MemoryRec_ *FT_Memory;
union FT_StreamDesc_ {
  long int value;
  void *pointer;
};
typedef union FT_StreamDesc_ FT_StreamDesc;
struct FT_StreamRec_ {
  unsigned char *base;
  long unsigned int size;
  long unsigned int pos;
  union FT_StreamDesc_ descriptor;
  union FT_StreamDesc_ pathname;
  long unsigned int (*read)(struct FT_StreamRec_ *, long unsigned int, unsigned char *, long unsigned int);
  void (*close)(struct FT_StreamRec_ *);
  struct FT_MemoryRec_ *memory;
  unsigned char *cursor;
  unsigned char *limit;
};
typedef struct FT_StreamRec_ *FT_Stream;
struct FT_GlyphSlotRec_ {
  struct FT_LibraryRec_ *library;
  struct FT_FaceRec_ *face;
  struct FT_GlyphSlotRec_ *next;
  unsigned int reserved;
  struct FT_Generic_ generic;
  struct FT_Glyph_Metrics_ metrics;
  long int linearHoriAdvance;
  long int linearVertAdvance;
  struct FT_Vector_ advance;
  enum FT_Glyph_Format_ format;
  struct FT_Bitmap_ bitmap;
  int bitmap_left;
  int bitmap_top;
  struct FT_Outline_ outline;
  unsigned int num_subglyphs;
  struct FT_SubGlyphRec_ *subglyphs;
  void *control_data;
  long int control_len;
  long int lsb_delta;
  long int rsb_delta;
  void *other;
  struct FT_Slot_InternalRec_ *internal;
};
typedef struct FT_GlyphSlotRec_ *FT_GlyphSlot;
int FT_Init_FreeType(struct FT_LibraryRec_ **);
int FT_New_Face(struct FT_LibraryRec_ *, const char *, long int, struct FT_FaceRec_ **);
int FT_Set_Pixel_Sizes(struct FT_FaceRec_ *, unsigned int, unsigned int);
int FT_Done_Face(struct FT_FaceRec_ *);
unsigned int FT_Get_Char_Index(struct FT_FaceRec_ *, long unsigned int);
int FT_Load_Char(struct FT_FaceRec_ *, long unsigned int, int);
int FT_Get_Kerning(struct FT_FaceRec_ *, unsigned int, unsigned int, unsigned int, struct FT_Vector_ *);
static const int FT_LOAD_RENDER = 4;
static const int FT_FACE_FLAG_KERNING = 64;
static const int FT_KERNING_DEFAULT = 0;
]]
