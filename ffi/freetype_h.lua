-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
static const unsigned FT_FACE_FLAG_EXTERNAL_STREAM = 1024;
static const unsigned FT_FACE_FLAG_FAST_GLYPHS = 128;
static const unsigned FT_FACE_FLAG_FIXED_SIZES = 2;
static const unsigned FT_FACE_FLAG_FIXED_WIDTH = 4;
static const unsigned FT_FACE_FLAG_GLYPH_NAMES = 512;
static const unsigned FT_FACE_FLAG_HINTER = 2048;
static const unsigned FT_FACE_FLAG_HORIZONTAL = 16;
static const unsigned FT_FACE_FLAG_KERNING = 64;
static const unsigned FT_FACE_FLAG_MULTIPLE_MASTERS = 256;
static const unsigned FT_FACE_FLAG_SCALABLE = 1;
static const unsigned FT_FACE_FLAG_SFNT = 8;
static const unsigned FT_FACE_FLAG_VERTICAL = 32;
static const unsigned FT_KERNING_DEFAULT = 0;
static const unsigned FT_KERNING_UNFITTED = 1;
static const unsigned FT_KERNING_UNSCALED = 2;
static const unsigned FT_LOAD_CROP_BITMAP = 64;
static const unsigned FT_LOAD_DEFAULT = 0;
static const unsigned FT_LOAD_FORCE_AUTOHINT = 32;
static const unsigned FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH = 512;
static const unsigned FT_LOAD_IGNORE_TRANSFORM = 2048;
static const unsigned FT_LOAD_LINEAR_DESIGN = 8192;
static const unsigned FT_LOAD_MONOCHROME = 4096;
static const unsigned FT_LOAD_NO_AUTOHINT = 32768;
static const unsigned FT_LOAD_NO_BITMAP = 8;
static const unsigned FT_LOAD_NO_HINTING = 2;
static const unsigned FT_LOAD_NO_RECURSE = 1024;
static const unsigned FT_LOAD_NO_SCALE = 1;
static const unsigned FT_LOAD_PEDANTIC = 128;
static const unsigned FT_LOAD_RENDER = 4;
static const unsigned FT_LOAD_SBITS_ONLY = 16384;
static const unsigned FT_LOAD_TARGET_LCD = 196608;
static const unsigned FT_LOAD_TARGET_LCD_V = 262144;
static const unsigned FT_LOAD_TARGET_LIGHT = 65536;
static const unsigned FT_LOAD_TARGET_MONO = 131072;
static const unsigned FT_LOAD_TARGET_NORMAL = 0;
static const unsigned FT_LOAD_VERTICAL_LAYOUT = 16;
static const unsigned FT_STYLE_FLAG_BOLD = 2;
static const unsigned FT_STYLE_FLAG_ITALIC = 1;
typedef unsigned char FT_Byte;
typedef signed char FT_Char;
typedef int FT_Error;
typedef long FT_Fixed;
typedef int FT_Int;
typedef int FT_Int32;
typedef long FT_Long;
typedef long FT_Pos;
typedef short FT_Short;
typedef char FT_String;
typedef unsigned FT_UInt;
typedef unsigned FT_UInt32;
typedef unsigned long FT_ULong;
typedef unsigned short FT_UShort;
typedef enum FT_Encoding_ FT_Encoding;
enum FT_Encoding_ {
  FT_ENCODING_NONE = (((FT_UInt32)(unsigned char)(0) << 24) | ((FT_UInt32)(unsigned char)(0) << 16) | ((FT_UInt32)(unsigned char)(0) << 8) | (FT_UInt32)(unsigned char)(0)),
  FT_ENCODING_MS_SYMBOL = (((FT_UInt32)(unsigned char)('s') << 24) | ((FT_UInt32)(unsigned char)('y') << 16) | ((FT_UInt32)(unsigned char)('m') << 8) | (FT_UInt32)(unsigned char)('b')),
  FT_ENCODING_UNICODE = (((FT_UInt32)(unsigned char)('u') << 24) | ((FT_UInt32)(unsigned char)('n') << 16) | ((FT_UInt32)(unsigned char)('i') << 8) | (FT_UInt32)(unsigned char)('c')),
  FT_ENCODING_SJIS = (((FT_UInt32)(unsigned char)('s') << 24) | ((FT_UInt32)(unsigned char)('j') << 16) | ((FT_UInt32)(unsigned char)('i') << 8) | (FT_UInt32)(unsigned char)('s')),
  FT_ENCODING_PRC = (((FT_UInt32)(unsigned char)('g') << 24) | ((FT_UInt32)(unsigned char)('b') << 16) | ((FT_UInt32)(unsigned char)(' ') << 8) | (FT_UInt32)(unsigned char)(' ')),
  FT_ENCODING_BIG5 = (((FT_UInt32)(unsigned char)('b') << 24) | ((FT_UInt32)(unsigned char)('i') << 16) | ((FT_UInt32)(unsigned char)('g') << 8) | (FT_UInt32)(unsigned char)('5')),
  FT_ENCODING_WANSUNG = (((FT_UInt32)(unsigned char)('w') << 24) | ((FT_UInt32)(unsigned char)('a') << 16) | ((FT_UInt32)(unsigned char)('n') << 8) | (FT_UInt32)(unsigned char)('s')),
  FT_ENCODING_JOHAB = (((FT_UInt32)(unsigned char)('j') << 24) | ((FT_UInt32)(unsigned char)('o') << 16) | ((FT_UInt32)(unsigned char)('h') << 8) | (FT_UInt32)(unsigned char)('a')),
  FT_ENCODING_GB2312 = FT_ENCODING_PRC,
  FT_ENCODING_MS_SJIS = FT_ENCODING_SJIS,
  FT_ENCODING_MS_GB2312 = FT_ENCODING_PRC,
  FT_ENCODING_MS_BIG5 = FT_ENCODING_BIG5,
  FT_ENCODING_MS_WANSUNG = FT_ENCODING_WANSUNG,
  FT_ENCODING_MS_JOHAB = FT_ENCODING_JOHAB,
  FT_ENCODING_ADOBE_STANDARD = (((FT_UInt32)(unsigned char)('A') << 24) | ((FT_UInt32)(unsigned char)('D') << 16) | ((FT_UInt32)(unsigned char)('O') << 8) | (FT_UInt32)(unsigned char)('B')),
  FT_ENCODING_ADOBE_EXPERT = (((FT_UInt32)(unsigned char)('A') << 24) | ((FT_UInt32)(unsigned char)('D') << 16) | ((FT_UInt32)(unsigned char)('B') << 8) | (FT_UInt32)(unsigned char)('E')),
  FT_ENCODING_ADOBE_CUSTOM = (((FT_UInt32)(unsigned char)('A') << 24) | ((FT_UInt32)(unsigned char)('D') << 16) | ((FT_UInt32)(unsigned char)('B') << 8) | (FT_UInt32)(unsigned char)('C')),
  FT_ENCODING_ADOBE_LATIN_1 = (((FT_UInt32)(unsigned char)('l') << 24) | ((FT_UInt32)(unsigned char)('a') << 16) | ((FT_UInt32)(unsigned char)('t') << 8) | (FT_UInt32)(unsigned char)('1')),
  FT_ENCODING_OLD_LATIN_2 = (((FT_UInt32)(unsigned char)('l') << 24) | ((FT_UInt32)(unsigned char)('a') << 16) | ((FT_UInt32)(unsigned char)('t') << 8) | (FT_UInt32)(unsigned char)('2')),
  FT_ENCODING_APPLE_ROMAN = (((FT_UInt32)(unsigned char)('a') << 24) | ((FT_UInt32)(unsigned char)('r') << 16) | ((FT_UInt32)(unsigned char)('m') << 8) | (FT_UInt32)(unsigned char)('n')),
};
typedef enum FT_Glyph_Format_ FT_Glyph_Format;
enum FT_Glyph_Format_ {
  FT_GLYPH_FORMAT_NONE = (((unsigned long)(unsigned char)(0) << 24) | ((unsigned long)(unsigned char)(0) << 16) | ((unsigned long)(unsigned char)(0) << 8) | (unsigned long)(unsigned char)(0)),
  FT_GLYPH_FORMAT_COMPOSITE = (((unsigned long)(unsigned char)('c') << 24) | ((unsigned long)(unsigned char)('o') << 16) | ((unsigned long)(unsigned char)('m') << 8) | (unsigned long)(unsigned char)('p')),
  FT_GLYPH_FORMAT_BITMAP = (((unsigned long)(unsigned char)('b') << 24) | ((unsigned long)(unsigned char)('i') << 16) | ((unsigned long)(unsigned char)('t') << 8) | (unsigned long)(unsigned char)('s')),
  FT_GLYPH_FORMAT_OUTLINE = (((unsigned long)(unsigned char)('o') << 24) | ((unsigned long)(unsigned char)('u') << 16) | ((unsigned long)(unsigned char)('t') << 8) | (unsigned long)(unsigned char)('l')),
  FT_GLYPH_FORMAT_PLOTTER = (((unsigned long)(unsigned char)('p') << 24) | ((unsigned long)(unsigned char)('l') << 16) | ((unsigned long)(unsigned char)('o') << 8) | (unsigned long)(unsigned char)('t')),
  FT_GLYPH_FORMAT_SVG = (((unsigned long)(unsigned char)('S') << 24) | ((unsigned long)(unsigned char)('V') << 16) | ((unsigned long)(unsigned char)('G') << 8) | (unsigned long)(unsigned char)(' ')),
};
typedef enum FT_Render_Mode_ FT_Render_Mode;
enum FT_Render_Mode_ {
  FT_RENDER_MODE_NORMAL = 0,
  FT_RENDER_MODE_LIGHT,
  FT_RENDER_MODE_MONO,
  FT_RENDER_MODE_LCD,
  FT_RENDER_MODE_LCD_V,
  FT_RENDER_MODE_SDF,
  FT_RENDER_MODE_MAX,
};
typedef enum FT_Sfnt_Tag_ FT_Sfnt_Tag;
enum FT_Sfnt_Tag_ {
  FT_SFNT_HEAD,
  FT_SFNT_MAXP,
  FT_SFNT_OS2,
  FT_SFNT_HHEA,
  FT_SFNT_VHEA,
  FT_SFNT_POST,
  FT_SFNT_PCLT,
  FT_SFNT_MAX,
};
typedef void (*FT_Generic_Finalizer)(void *);
typedef struct FT_BBox_ FT_BBox;
typedef struct FT_Bitmap_ FT_Bitmap;
typedef struct FT_Bitmap_Size_ FT_Bitmap_Size;
typedef struct FT_CharMapRec_ *FT_CharMap;
typedef struct FT_DriverRec_ *FT_Driver;
typedef struct FT_FaceRec_ *FT_Face;
typedef struct FT_Face_InternalRec_ *FT_Face_Internal;
typedef struct FT_Generic_ FT_Generic;
typedef struct FT_GlyphSlotRec_ *FT_GlyphSlot;
typedef struct FT_Glyph_Metrics_ FT_Glyph_Metrics;
typedef struct FT_LibraryRec_ *FT_Library;
typedef struct FT_ListRec_ *FT_List;
typedef struct FT_ListNodeRec_ *FT_ListNode;
typedef struct FT_ListRec_ FT_ListRec;
typedef struct FT_MemoryRec_ *FT_Memory;
typedef struct FT_Outline_ FT_Outline;
typedef struct FT_SizeRec_ *FT_Size;
typedef struct FT_Size_InternalRec_ *FT_Size_Internal;
typedef struct FT_Size_Metrics_ FT_Size_Metrics;
typedef struct FT_Slot_InternalRec_ *FT_Slot_Internal;
typedef struct FT_StreamRec_ *FT_Stream;
typedef struct FT_SubGlyphRec_ *FT_SubGlyph;
typedef struct FT_Vector_ FT_Vector;
typedef struct TT_OS2_ TT_OS2;
struct FT_BBox_ {
  FT_Pos xMin, yMin;
  FT_Pos xMax, yMax;
};
struct FT_Bitmap_ {
  unsigned rows;
  unsigned width;
  int pitch;
  unsigned char *buffer;
  unsigned short num_grays;
  unsigned char pixel_mode;
  unsigned char palette_mode;
  void *palette;
};
struct FT_CharMapRec_ {
  FT_Face face;
  FT_Encoding encoding;
  FT_UShort platform_id;
  FT_UShort encoding_id;
};
struct FT_Generic_ {
  void *data;
  FT_Generic_Finalizer finalizer;
};
struct FT_Outline_ {
  unsigned short n_contours;
  unsigned short n_points;
  FT_Vector *points;
  unsigned char *tags;
  unsigned short *contours;
  int flags;
};
struct FT_Vector_ {
  FT_Pos x;
  FT_Pos y;
};
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
struct FT_GlyphSlotRec_ {
  FT_Library library;
  FT_Face face;
  FT_GlyphSlot next;
  FT_UInt glyph_index;
  FT_Generic generic;
  FT_Glyph_Metrics metrics;
  FT_Fixed linearHoriAdvance;
  FT_Fixed linearVertAdvance;
  FT_Vector advance;
  FT_Glyph_Format format;
  FT_Bitmap bitmap;
  FT_Int bitmap_left;
  FT_Int bitmap_top;
  FT_Outline outline;
  FT_UInt num_subglyphs;
  FT_SubGlyph subglyphs;
  void *control_data;
  long control_len;
  FT_Pos lsb_delta;
  FT_Pos rsb_delta;
  void *other;
  FT_Slot_Internal internal;
};
struct FT_ListRec_ {
  FT_ListNode head;
  FT_ListNode tail;
};
struct FT_Size_Metrics_ {
  FT_UShort x_ppem;
  FT_UShort y_ppem;
  FT_Fixed x_scale;
  FT_Fixed y_scale;
  FT_Pos ascender;
  FT_Pos descender;
  FT_Pos height;
  FT_Pos max_advance;
};
struct FT_SizeRec_ {
  FT_Face face;
  FT_Generic generic;
  FT_Size_Metrics metrics;
  FT_Size_Internal internal;
};
struct FT_FaceRec_ {
  FT_Long num_faces;
  FT_Long face_index;
  FT_Long face_flags;
  FT_Long style_flags;
  FT_Long num_glyphs;
  FT_String *family_name;
  FT_String *style_name;
  FT_Int num_fixed_sizes;
  FT_Bitmap_Size *available_sizes;
  FT_Int num_charmaps;
  FT_CharMap *charmaps;
  FT_Generic generic;
  FT_BBox bbox;
  FT_UShort units_per_EM;
  FT_Short ascender;
  FT_Short descender;
  FT_Short height;
  FT_Short max_advance_width;
  FT_Short max_advance_height;
  FT_Short underline_position;
  FT_Short underline_thickness;
  FT_GlyphSlot glyph;
  FT_Size size;
  FT_CharMap charmap;
  FT_Driver driver;
  FT_Memory memory;
  FT_Stream stream;
  FT_ListRec sizes_list;
  FT_Generic autohint;
  void *extensions;
  FT_Face_Internal internal;
};
struct TT_OS2_ {
  FT_UShort version;
  FT_Short xAvgCharWidth;
  FT_UShort usWeightClass;
  FT_UShort usWidthClass;
  FT_UShort fsType;
  FT_Short ySubscriptXSize;
  FT_Short ySubscriptYSize;
  FT_Short ySubscriptXOffset;
  FT_Short ySubscriptYOffset;
  FT_Short ySuperscriptXSize;
  FT_Short ySuperscriptYSize;
  FT_Short ySuperscriptXOffset;
  FT_Short ySuperscriptYOffset;
  FT_Short yStrikeoutSize;
  FT_Short yStrikeoutPosition;
  FT_Short sFamilyClass;
  FT_Byte panose[10];
  FT_ULong ulUnicodeRange1;
  FT_ULong ulUnicodeRange2;
  FT_ULong ulUnicodeRange3;
  FT_ULong ulUnicodeRange4;
  FT_Char achVendID[4];
  FT_UShort fsSelection;
  FT_UShort usFirstCharIndex;
  FT_UShort usLastCharIndex;
  FT_Short sTypoAscender;
  FT_Short sTypoDescender;
  FT_Short sTypoLineGap;
  FT_UShort usWinAscent;
  FT_UShort usWinDescent;
  FT_ULong ulCodePageRange1;
  FT_ULong ulCodePageRange2;
  FT_Short sxHeight;
  FT_Short sCapHeight;
  FT_UShort usDefaultChar;
  FT_UShort usBreakChar;
  FT_UShort usMaxContext;
  FT_UShort usLowerOpticalPointSize;
  FT_UShort usUpperOpticalPointSize;
};
FT_Error FT_Done_Library(FT_Library);
FT_Error FT_Init_FreeType(FT_Library *);
FT_Error FT_Reference_Library(FT_Library);
FT_Error FT_Done_Face(FT_Face);
FT_Error FT_New_Face(FT_Library, const char *, FT_Long, FT_Face *);
FT_Error FT_Reference_Face(FT_Face);
FT_Error FT_Set_Pixel_Sizes(FT_Face, FT_UInt, FT_UInt);
FT_Error FT_Activate_Size(FT_Size);
FT_Error FT_Done_Size(FT_Size);
FT_Error FT_New_Size(FT_Face, FT_Size *);
FT_UInt FT_Get_Char_Index(FT_Face, FT_ULong);
FT_Error FT_Load_Char(FT_Face, FT_ULong, FT_Int32);
FT_Error FT_Get_Kerning(FT_Face, FT_UInt, FT_UInt, FT_UInt, FT_Vector *);
void FT_GlyphSlot_Embolden(FT_GlyphSlot);
void FT_GlyphSlot_Oblique(FT_GlyphSlot);
FT_Error FT_Load_Glyph(FT_Face, FT_UInt, FT_Int32);
FT_Error FT_Render_Glyph(FT_GlyphSlot, FT_Render_Mode);
FT_Long FT_MulFix(FT_Long, FT_Long);
FT_Error FT_Outline_Embolden(FT_Outline *, FT_Pos);
void FT_Outline_Translate(const FT_Outline *, FT_Pos, FT_Pos);
void *FT_Get_Sfnt_Table(FT_Face, FT_Sfnt_Tag);
]]
