local ffi = require("ffi")

ffi.cdef[[
typedef int FT_Error;
typedef long int FT_Pos;
struct FT_Generic_ {
  void *data;
  void (*finalizer)(void *);
};
typedef struct FT_Generic_ FT_Generic;
typedef struct FT_ListNodeRec_ *FT_ListNode;
struct FT_ListNodeRec_ {
  FT_ListNode prev;
  FT_ListNode next;
  void *data;
};
typedef struct FT_ListRec_ *FT_List;
struct FT_ListRec_ {
  FT_ListNode head;
  FT_ListNode tail;
};
struct FT_BBox_ {
  FT_Pos xMin;
  FT_Pos yMin;
  FT_Pos xMax;
  FT_Pos yMax;
};
typedef struct FT_BBox_ FT_BBox;
struct FT_Bitmap_Size_ {
  short int height;
  short int width;
  FT_Pos size;
  FT_Pos x_ppem;
  FT_Pos y_ppem;
};
typedef struct FT_Bitmap_Size_ FT_Bitmap_Size;
struct FT_Bitmap_ {
  unsigned int rows;
  unsigned int width;
  int pitch;
  unsigned char *buffer;
  short unsigned int num_grays;
  unsigned char pixel_mode;
  unsigned char palette_mode;
  void *palette;
};
typedef struct FT_Bitmap_ FT_Bitmap;
struct FT_Vector_ {
  FT_Pos x;
  FT_Pos y;
};
typedef struct FT_Vector_ FT_Vector;
struct FT_Outline_ {
  short int n_contours;
  short int n_points;
  FT_Vector *points;
  char *tags;
  short int *contours;
  int flags;
};
typedef struct FT_Outline_ FT_Outline;
typedef struct FT_MemoryRec_ *FT_Memory;
struct FT_MemoryRec_ {
  void *user;
  void *(*alloc)(FT_Memory, long int);
  void (*free)(FT_Memory, void *);
  void *(*realloc)(FT_Memory, long int, long int, void *);
};
union FT_StreamDesc_ {
  long int value;
  void *pointer;
};
typedef union FT_StreamDesc_ FT_StreamDesc;
typedef struct FT_StreamRec_ *FT_Stream;
struct FT_StreamRec_ {
  unsigned char *base;
  long unsigned int size;
  long unsigned int pos;
  FT_StreamDesc descriptor;
  FT_StreamDesc pathname;
  long unsigned int (*read)(FT_Stream, long unsigned int, unsigned char *, long unsigned int);
  void (*close)(FT_Stream);
  FT_Memory memory;
  unsigned char *cursor;
  unsigned char *limit;
};
enum FT_Glyph_Format_ {
  FT_GLYPH_FORMAT_NONE = 0,
  FT_GLYPH_FORMAT_COMPOSITE = 1668246896,
  FT_GLYPH_FORMAT_BITMAP = 1651078259,
  FT_GLYPH_FORMAT_OUTLINE = 1869968492,
  FT_GLYPH_FORMAT_PLOTTER = 1886154612,
};
typedef enum FT_Glyph_Format_ FT_Glyph_Format;
struct FT_LibraryRec_;
typedef struct FT_LibraryRec_ *FT_Library;
typedef struct FT_FaceRec_ *FT_Face;
typedef struct FT_Glyph_Metrics_ FT_Glyph_Metrics;
struct FT_Glyph_Metrics_ {
  FT_Pos width;
  FT_Pos height;
  FT_Pos horiBearingX;
  FT_Pos horiBearingY;
  FT_Pos horiAdvance;
  FT_Pos vertBearingX;
  FT_Pos vertBearingY;
  FT_Pos vertAdvance;
};
struct FT_SubGlyphRec_;
typedef struct FT_SubGlyphRec_ *FT_SubGlyph;
struct FT_Slot_InternalRec_;
typedef struct FT_Slot_InternalRec_ *FT_Slot_Internal;
typedef struct FT_GlyphSlotRec_ *FT_GlyphSlot;
struct FT_GlyphSlotRec_ {
  FT_Library library;
  FT_Face face;
  FT_GlyphSlot next;
  unsigned int glyph_index;
  FT_Generic generic;
  FT_Glyph_Metrics metrics;
  long int linearHoriAdvance;
  long int linearVertAdvance;
  FT_Vector advance;
  FT_Glyph_Format format;
  FT_Bitmap bitmap;
  int bitmap_left;
  int bitmap_top;
  FT_Outline outline;
  unsigned int num_subglyphs;
  FT_SubGlyph subglyphs;
  void *control_data;
  long int control_len;
  FT_Pos lsb_delta;
  FT_Pos rsb_delta;
  void *other;
  FT_Slot_Internal internal;
};
struct FT_Size_Metrics_ {
  short unsigned int x_ppem;
  short unsigned int y_ppem;
  long int x_scale;
  long int y_scale;
  FT_Pos ascender;
  FT_Pos descender;
  FT_Pos height;
  FT_Pos max_advance;
};
typedef struct FT_Size_Metrics_ FT_Size_Metrics;
typedef struct FT_Size_InternalRec_ *FT_Size_Internal;
struct FT_Size_InternalRec_;
typedef struct FT_SizeRec_ *FT_Size;
struct FT_SizeRec_ {
  FT_Face face;
  FT_Generic generic;
  FT_Size_Metrics metrics;
  FT_Size_Internal internal;
};
typedef struct FT_CharMapRec_ *FT_CharMap;
struct FT_DriverRec_;
typedef struct FT_DriverRec_ *FT_Driver;
struct FT_Face_InternalRec_;
typedef struct FT_Face_InternalRec_ *FT_Face_Internal;
struct FT_FaceRec_ {
  long int num_faces;
  long int face_index;
  long int face_flags;
  long int style_flags;
  long int num_glyphs;
  char *family_name;
  char *style_name;
  int num_fixed_sizes;
  FT_Bitmap_Size *available_sizes;
  int num_charmaps;
  FT_CharMap *charmaps;
  FT_Generic generic;
  FT_BBox bbox;
  short unsigned int units_per_EM;
  short int ascender;
  short int descender;
  short int height;
  short int max_advance_width;
  short int max_advance_height;
  short int underline_position;
  short int underline_thickness;
  FT_GlyphSlot glyph;
  FT_Size size;
  FT_CharMap charmap;
  FT_Driver driver;
  FT_Memory memory;
  FT_Stream stream;
  struct FT_ListRec_ sizes_list;
  FT_Generic autohint;
  void *extensions;
  FT_Face_Internal internal;
};
enum FT_Encoding_ {
  FT_ENCODING_NONE = 0,
  FT_ENCODING_MS_SYMBOL = 1937337698,
  FT_ENCODING_UNICODE = 1970170211,
  FT_ENCODING_SJIS = 1936353651,
  FT_ENCODING_PRC = 1734484000,
  FT_ENCODING_BIG5 = 1651074869,
  FT_ENCODING_WANSUNG = 2002873971,
  FT_ENCODING_JOHAB = 1785686113,
  FT_ENCODING_GB2312 = 1734484000,
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
  FT_Face face;
  FT_Encoding encoding;
  short unsigned int platform_id;
  short unsigned int encoding_id;
};
FT_Error FT_Init_FreeType(FT_Library *) __attribute__((visibility("default")));
FT_Error FT_New_Face(FT_Library, const char *, long int, FT_Face *) __attribute__((visibility("default")));
FT_Error FT_Set_Pixel_Sizes(FT_Face, unsigned int, unsigned int) __attribute__((visibility("default")));
FT_Error FT_Done_Face(FT_Face) __attribute__((visibility("default")));
unsigned int FT_Get_Char_Index(FT_Face, long unsigned int) __attribute__((visibility("default")));
FT_Error FT_Load_Char(FT_Face, long unsigned int, int) __attribute__((visibility("default")));
FT_Error FT_Get_Kerning(FT_Face, unsigned int, unsigned int, unsigned int, FT_Vector *) __attribute__((visibility("default")));
void FT_GlyphSlot_Embolden(FT_GlyphSlot) __attribute__((visibility("default")));
void FT_GlyphSlot_Oblique(FT_GlyphSlot) __attribute__((visibility("default")));
enum FT_Render_Mode_ {
  FT_RENDER_MODE_NORMAL = 0,
  FT_RENDER_MODE_LIGHT = 1,
  FT_RENDER_MODE_MONO = 2,
  FT_RENDER_MODE_LCD = 3,
  FT_RENDER_MODE_LCD_V = 4,
  FT_RENDER_MODE_MAX = 5,
};
typedef enum FT_Render_Mode_ FT_Render_Mode;
FT_Error FT_Load_Glyph(FT_Face, unsigned int, int) __attribute__((visibility("default")));
FT_Error FT_Render_Glyph(FT_GlyphSlot, FT_Render_Mode) __attribute__((visibility("default")));
FT_Error FT_Outline_Embolden(FT_Outline *, FT_Pos) __attribute__((visibility("default")));
void FT_Outline_Translate(const FT_Outline *, FT_Pos, FT_Pos) __attribute__((visibility("default")));
long int FT_MulFix(long int, long int) __attribute__((visibility("default")));
static const int FT_LOAD_RENDER = 4;
static const int FT_LOAD_DEFAULT = 0;
static const int FT_LOAD_TARGET_LIGHT = 65536;
static const int FT_LOAD_NO_AUTOHINT = 32768;
static const int FT_LOAD_NO_HINTING = 2;
static const int FT_LOAD_FORCE_AUTOHINT = 32;
static const int FT_FACE_FLAG_KERNING = 64;
static const int FT_KERNING_DEFAULT = 0;
]]
