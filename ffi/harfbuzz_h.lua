local ffi = require("ffi")

ffi.cdef[[
typedef int hb_bool_t;
typedef unsigned int hb_codepoint_t;
typedef int hb_position_t;
typedef unsigned int hb_mask_t;
typedef unsigned int hb_tag_t;
typedef unsigned int hb_color_t;
union _hb_var_int_t {
  uint32_t u32;
  int32_t i32;
  uint16_t u16[2];
  int16_t i16[2];
  uint8_t u8[4];
  int8_t i8[4];
};
typedef union _hb_var_int_t hb_var_int_t;
typedef enum {
  HB_DIRECTION_INVALID = 0,
  HB_DIRECTION_LTR = 4,
  HB_DIRECTION_RTL = 5,
  HB_DIRECTION_TTB = 6,
  HB_DIRECTION_BTT = 7,
} hb_direction_t;
typedef enum {
  HB_SCRIPT_COMMON = 1517910393,
  HB_SCRIPT_INHERITED = 1516858984,
  HB_SCRIPT_UNKNOWN = 1517976186,
  HB_SCRIPT_ARABIC = 1098015074,
  HB_SCRIPT_ARMENIAN = 1098018158,
  HB_SCRIPT_BENGALI = 1113943655,
  HB_SCRIPT_CYRILLIC = 1132032620,
  HB_SCRIPT_DEVANAGARI = 1147500129,
  HB_SCRIPT_GEORGIAN = 1197830002,
  HB_SCRIPT_GREEK = 1198679403,
  HB_SCRIPT_GUJARATI = 1198877298,
  HB_SCRIPT_GURMUKHI = 1198879349,
  HB_SCRIPT_HANGUL = 1214344807,
  HB_SCRIPT_HAN = 1214344809,
  HB_SCRIPT_HEBREW = 1214603890,
  HB_SCRIPT_HIRAGANA = 1214870113,
  HB_SCRIPT_KANNADA = 1265525857,
  HB_SCRIPT_KATAKANA = 1264676449,
  HB_SCRIPT_LAO = 1281453935,
  HB_SCRIPT_LATIN = 1281455214,
  HB_SCRIPT_MALAYALAM = 1298954605,
  HB_SCRIPT_ORIYA = 1332902241,
  HB_SCRIPT_TAMIL = 1415671148,
  HB_SCRIPT_TELUGU = 1415933045,
  HB_SCRIPT_THAI = 1416126825,
  HB_SCRIPT_TIBETAN = 1416192628,
  HB_SCRIPT_BOPOMOFO = 1114599535,
  HB_SCRIPT_BRAILLE = 1114792297,
  HB_SCRIPT_CANADIAN_SYLLABICS = 1130458739,
  HB_SCRIPT_CHEROKEE = 1130915186,
  HB_SCRIPT_ETHIOPIC = 1165256809,
  HB_SCRIPT_KHMER = 1265134962,
  HB_SCRIPT_MONGOLIAN = 1299148391,
  HB_SCRIPT_MYANMAR = 1299803506,
  HB_SCRIPT_OGHAM = 1332175213,
  HB_SCRIPT_RUNIC = 1383427698,
  HB_SCRIPT_SINHALA = 1399418472,
  HB_SCRIPT_SYRIAC = 1400468067,
  HB_SCRIPT_THAANA = 1416126817,
  HB_SCRIPT_YI = 1500080489,
  HB_SCRIPT_DESERET = 1148416628,
  HB_SCRIPT_GOTHIC = 1198486632,
  HB_SCRIPT_OLD_ITALIC = 1232363884,
  HB_SCRIPT_BUHID = 1114990692,
  HB_SCRIPT_HANUNOO = 1214344815,
  HB_SCRIPT_TAGALOG = 1416064103,
  HB_SCRIPT_TAGBANWA = 1415669602,
  HB_SCRIPT_CYPRIOT = 1131442804,
  HB_SCRIPT_LIMBU = 1281977698,
  HB_SCRIPT_LINEAR_B = 1281977954,
  HB_SCRIPT_OSMANYA = 1332964705,
  HB_SCRIPT_SHAVIAN = 1399349623,
  HB_SCRIPT_TAI_LE = 1415670885,
  HB_SCRIPT_UGARITIC = 1432838514,
  HB_SCRIPT_BUGINESE = 1114990441,
  HB_SCRIPT_COPTIC = 1131376756,
  HB_SCRIPT_GLAGOLITIC = 1198285159,
  HB_SCRIPT_KHAROSHTHI = 1265131890,
  HB_SCRIPT_NEW_TAI_LUE = 1415670901,
  HB_SCRIPT_OLD_PERSIAN = 1483761007,
  HB_SCRIPT_SYLOTI_NAGRI = 1400466543,
  HB_SCRIPT_TIFINAGH = 1415999079,
  HB_SCRIPT_BALINESE = 1113681001,
  HB_SCRIPT_CUNEIFORM = 1483961720,
  HB_SCRIPT_NKO = 1315663727,
  HB_SCRIPT_PHAGS_PA = 1349017959,
  HB_SCRIPT_PHOENICIAN = 1349021304,
  HB_SCRIPT_CARIAN = 1130459753,
  HB_SCRIPT_CHAM = 1130914157,
  HB_SCRIPT_KAYAH_LI = 1264675945,
  HB_SCRIPT_LEPCHA = 1281716323,
  HB_SCRIPT_LYCIAN = 1283023721,
  HB_SCRIPT_LYDIAN = 1283023977,
  HB_SCRIPT_OL_CHIKI = 1332503403,
  HB_SCRIPT_REJANG = 1382706791,
  HB_SCRIPT_SAURASHTRA = 1398895986,
  HB_SCRIPT_SUNDANESE = 1400204900,
  HB_SCRIPT_VAI = 1449224553,
  HB_SCRIPT_AVESTAN = 1098281844,
  HB_SCRIPT_BAMUM = 1113681269,
  HB_SCRIPT_EGYPTIAN_HIEROGLYPHS = 1164409200,
  HB_SCRIPT_IMPERIAL_ARAMAIC = 1098018153,
  HB_SCRIPT_INSCRIPTIONAL_PAHLAVI = 1349020777,
  HB_SCRIPT_INSCRIPTIONAL_PARTHIAN = 1349678185,
  HB_SCRIPT_JAVANESE = 1247901281,
  HB_SCRIPT_KAITHI = 1265920105,
  HB_SCRIPT_LISU = 1281979253,
  HB_SCRIPT_MEETEI_MAYEK = 1299473769,
  HB_SCRIPT_OLD_SOUTH_ARABIAN = 1398895202,
  HB_SCRIPT_OLD_TURKIC = 1332898664,
  HB_SCRIPT_SAMARITAN = 1398893938,
  HB_SCRIPT_TAI_THAM = 1281453665,
  HB_SCRIPT_TAI_VIET = 1415673460,
  HB_SCRIPT_BATAK = 1113683051,
  HB_SCRIPT_BRAHMI = 1114792296,
  HB_SCRIPT_MANDAIC = 1298230884,
  HB_SCRIPT_CHAKMA = 1130457965,
  HB_SCRIPT_MEROITIC_CURSIVE = 1298494051,
  HB_SCRIPT_MEROITIC_HIEROGLYPHS = 1298494063,
  HB_SCRIPT_MIAO = 1349284452,
  HB_SCRIPT_SHARADA = 1399353956,
  HB_SCRIPT_SORA_SOMPENG = 1399812705,
  HB_SCRIPT_TAKRI = 1415670642,
  HB_SCRIPT_BASSA_VAH = 1113682803,
  HB_SCRIPT_CAUCASIAN_ALBANIAN = 1097295970,
  HB_SCRIPT_DUPLOYAN = 1148547180,
  HB_SCRIPT_ELBASAN = 1164730977,
  HB_SCRIPT_GRANTHA = 1198678382,
  HB_SCRIPT_KHOJKI = 1265135466,
  HB_SCRIPT_KHUDAWADI = 1399418468,
  HB_SCRIPT_LINEAR_A = 1281977953,
  HB_SCRIPT_MAHAJANI = 1298229354,
  HB_SCRIPT_MANICHAEAN = 1298230889,
  HB_SCRIPT_MENDE_KIKAKUI = 1298493028,
  HB_SCRIPT_MODI = 1299145833,
  HB_SCRIPT_MRO = 1299345263,
  HB_SCRIPT_NABATAEAN = 1315070324,
  HB_SCRIPT_OLD_NORTH_ARABIAN = 1315009122,
  HB_SCRIPT_OLD_PERMIC = 1348825709,
  HB_SCRIPT_PAHAWH_HMONG = 1215131239,
  HB_SCRIPT_PALMYRENE = 1348562029,
  HB_SCRIPT_PAU_CIN_HAU = 1348564323,
  HB_SCRIPT_PSALTER_PAHLAVI = 1349020784,
  HB_SCRIPT_SIDDHAM = 1399415908,
  HB_SCRIPT_TIRHUTA = 1416196712,
  HB_SCRIPT_WARANG_CITI = 1466004065,
  HB_SCRIPT_AHOM = 1097363309,
  HB_SCRIPT_ANATOLIAN_HIEROGLYPHS = 1215067511,
  HB_SCRIPT_HATRAN = 1214346354,
  HB_SCRIPT_MULTANI = 1299541108,
  HB_SCRIPT_OLD_HUNGARIAN = 1215655527,
  HB_SCRIPT_SIGNWRITING = 1399287415,
  HB_SCRIPT_ADLAM = 1097100397,
  HB_SCRIPT_BHAIKSUKI = 1114139507,
  HB_SCRIPT_MARCHEN = 1298231907,
  HB_SCRIPT_OSAGE = 1332963173,
  HB_SCRIPT_TANGUT = 1415671399,
  HB_SCRIPT_NEWA = 1315272545,
  HB_SCRIPT_MASARAM_GONDI = 1198485101,
  HB_SCRIPT_NUSHU = 1316186229,
  HB_SCRIPT_SOYOMBO = 1399814511,
  HB_SCRIPT_ZANABAZAR_SQUARE = 1516334690,
  HB_SCRIPT_DOGRA = 1148151666,
  HB_SCRIPT_GUNJALA_GONDI = 1198485095,
  HB_SCRIPT_HANIFI_ROHINGYA = 1383032935,
  HB_SCRIPT_MAKASAR = 1298230113,
  HB_SCRIPT_MEDEFAIDRIN = 1298490470,
  HB_SCRIPT_OLD_SOGDIAN = 1399809903,
  HB_SCRIPT_SOGDIAN = 1399809892,
  HB_SCRIPT_ELYMAIC = 1164736877,
  HB_SCRIPT_NANDINAGARI = 1315008100,
  HB_SCRIPT_NYIAKENG_PUACHUE_HMONG = 1215131248,
  HB_SCRIPT_WANCHO = 1466132591,
  HB_SCRIPT_CHORASMIAN = 1130918515,
  HB_SCRIPT_DIVES_AKURU = 1147756907,
  HB_SCRIPT_KHITAN_SMALL_SCRIPT = 1265202291,
  HB_SCRIPT_YEZIDI = 1499822697,
  HB_SCRIPT_INVALID = 0,
  _HB_SCRIPT_MAX_VALUE = 2147483647,
  _HB_SCRIPT_MAX_VALUE_SIGNED = 2147483647,
} hb_script_t;
typedef struct hb_user_data_key_t hb_user_data_key_t;
typedef struct hb_feature_t hb_feature_t;
typedef struct hb_variation_t hb_variation_t;
typedef enum {
  HB_MEMORY_MODE_DUPLICATE = 0,
  HB_MEMORY_MODE_READONLY = 1,
  HB_MEMORY_MODE_WRITABLE = 2,
  HB_MEMORY_MODE_READONLY_MAY_MAKE_WRITABLE = 3,
} hb_memory_mode_t;
typedef enum {
  HB_UNICODE_GENERAL_CATEGORY_CONTROL = 0,
  HB_UNICODE_GENERAL_CATEGORY_FORMAT = 1,
  HB_UNICODE_GENERAL_CATEGORY_UNASSIGNED = 2,
  HB_UNICODE_GENERAL_CATEGORY_PRIVATE_USE = 3,
  HB_UNICODE_GENERAL_CATEGORY_SURROGATE = 4,
  HB_UNICODE_GENERAL_CATEGORY_LOWERCASE_LETTER = 5,
  HB_UNICODE_GENERAL_CATEGORY_MODIFIER_LETTER = 6,
  HB_UNICODE_GENERAL_CATEGORY_OTHER_LETTER = 7,
  HB_UNICODE_GENERAL_CATEGORY_TITLECASE_LETTER = 8,
  HB_UNICODE_GENERAL_CATEGORY_UPPERCASE_LETTER = 9,
  HB_UNICODE_GENERAL_CATEGORY_SPACING_MARK = 10,
  HB_UNICODE_GENERAL_CATEGORY_ENCLOSING_MARK = 11,
  HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK = 12,
  HB_UNICODE_GENERAL_CATEGORY_DECIMAL_NUMBER = 13,
  HB_UNICODE_GENERAL_CATEGORY_LETTER_NUMBER = 14,
  HB_UNICODE_GENERAL_CATEGORY_OTHER_NUMBER = 15,
  HB_UNICODE_GENERAL_CATEGORY_CONNECT_PUNCTUATION = 16,
  HB_UNICODE_GENERAL_CATEGORY_DASH_PUNCTUATION = 17,
  HB_UNICODE_GENERAL_CATEGORY_CLOSE_PUNCTUATION = 18,
  HB_UNICODE_GENERAL_CATEGORY_FINAL_PUNCTUATION = 19,
  HB_UNICODE_GENERAL_CATEGORY_INITIAL_PUNCTUATION = 20,
  HB_UNICODE_GENERAL_CATEGORY_OTHER_PUNCTUATION = 21,
  HB_UNICODE_GENERAL_CATEGORY_OPEN_PUNCTUATION = 22,
  HB_UNICODE_GENERAL_CATEGORY_CURRENCY_SYMBOL = 23,
  HB_UNICODE_GENERAL_CATEGORY_MODIFIER_SYMBOL = 24,
  HB_UNICODE_GENERAL_CATEGORY_MATH_SYMBOL = 25,
  HB_UNICODE_GENERAL_CATEGORY_OTHER_SYMBOL = 26,
  HB_UNICODE_GENERAL_CATEGORY_LINE_SEPARATOR = 27,
  HB_UNICODE_GENERAL_CATEGORY_PARAGRAPH_SEPARATOR = 28,
  HB_UNICODE_GENERAL_CATEGORY_SPACE_SEPARATOR = 29,
} hb_unicode_general_category_t;
typedef enum {
  HB_UNICODE_COMBINING_CLASS_NOT_REORDERED = 0,
  HB_UNICODE_COMBINING_CLASS_OVERLAY = 1,
  HB_UNICODE_COMBINING_CLASS_NUKTA = 7,
  HB_UNICODE_COMBINING_CLASS_KANA_VOICING = 8,
  HB_UNICODE_COMBINING_CLASS_VIRAMA = 9,
  HB_UNICODE_COMBINING_CLASS_CCC10 = 10,
  HB_UNICODE_COMBINING_CLASS_CCC11 = 11,
  HB_UNICODE_COMBINING_CLASS_CCC12 = 12,
  HB_UNICODE_COMBINING_CLASS_CCC13 = 13,
  HB_UNICODE_COMBINING_CLASS_CCC14 = 14,
  HB_UNICODE_COMBINING_CLASS_CCC15 = 15,
  HB_UNICODE_COMBINING_CLASS_CCC16 = 16,
  HB_UNICODE_COMBINING_CLASS_CCC17 = 17,
  HB_UNICODE_COMBINING_CLASS_CCC18 = 18,
  HB_UNICODE_COMBINING_CLASS_CCC19 = 19,
  HB_UNICODE_COMBINING_CLASS_CCC20 = 20,
  HB_UNICODE_COMBINING_CLASS_CCC21 = 21,
  HB_UNICODE_COMBINING_CLASS_CCC22 = 22,
  HB_UNICODE_COMBINING_CLASS_CCC23 = 23,
  HB_UNICODE_COMBINING_CLASS_CCC24 = 24,
  HB_UNICODE_COMBINING_CLASS_CCC25 = 25,
  HB_UNICODE_COMBINING_CLASS_CCC26 = 26,
  HB_UNICODE_COMBINING_CLASS_CCC27 = 27,
  HB_UNICODE_COMBINING_CLASS_CCC28 = 28,
  HB_UNICODE_COMBINING_CLASS_CCC29 = 29,
  HB_UNICODE_COMBINING_CLASS_CCC30 = 30,
  HB_UNICODE_COMBINING_CLASS_CCC31 = 31,
  HB_UNICODE_COMBINING_CLASS_CCC32 = 32,
  HB_UNICODE_COMBINING_CLASS_CCC33 = 33,
  HB_UNICODE_COMBINING_CLASS_CCC34 = 34,
  HB_UNICODE_COMBINING_CLASS_CCC35 = 35,
  HB_UNICODE_COMBINING_CLASS_CCC36 = 36,
  HB_UNICODE_COMBINING_CLASS_CCC84 = 84,
  HB_UNICODE_COMBINING_CLASS_CCC91 = 91,
  HB_UNICODE_COMBINING_CLASS_CCC103 = 103,
  HB_UNICODE_COMBINING_CLASS_CCC107 = 107,
  HB_UNICODE_COMBINING_CLASS_CCC118 = 118,
  HB_UNICODE_COMBINING_CLASS_CCC122 = 122,
  HB_UNICODE_COMBINING_CLASS_CCC129 = 129,
  HB_UNICODE_COMBINING_CLASS_CCC130 = 130,
  HB_UNICODE_COMBINING_CLASS_CCC133 = 132,
  HB_UNICODE_COMBINING_CLASS_ATTACHED_BELOW_LEFT = 200,
  HB_UNICODE_COMBINING_CLASS_ATTACHED_BELOW = 202,
  HB_UNICODE_COMBINING_CLASS_ATTACHED_ABOVE = 214,
  HB_UNICODE_COMBINING_CLASS_ATTACHED_ABOVE_RIGHT = 216,
  HB_UNICODE_COMBINING_CLASS_BELOW_LEFT = 218,
  HB_UNICODE_COMBINING_CLASS_BELOW = 220,
  HB_UNICODE_COMBINING_CLASS_BELOW_RIGHT = 222,
  HB_UNICODE_COMBINING_CLASS_LEFT = 224,
  HB_UNICODE_COMBINING_CLASS_RIGHT = 226,
  HB_UNICODE_COMBINING_CLASS_ABOVE_LEFT = 228,
  HB_UNICODE_COMBINING_CLASS_ABOVE = 230,
  HB_UNICODE_COMBINING_CLASS_ABOVE_RIGHT = 232,
  HB_UNICODE_COMBINING_CLASS_DOUBLE_BELOW = 233,
  HB_UNICODE_COMBINING_CLASS_DOUBLE_ABOVE = 234,
  HB_UNICODE_COMBINING_CLASS_IOTA_SUBSCRIPT = 240,
  HB_UNICODE_COMBINING_CLASS_INVALID = 255,
} hb_unicode_combining_class_t;
typedef struct hb_font_extents_t hb_font_extents_t;
typedef struct hb_glyph_extents_t hb_glyph_extents_t;
typedef struct hb_glyph_info_t hb_glyph_info_t;
typedef enum {
  HB_GLYPH_FLAG_UNSAFE_TO_BREAK = 1,
  HB_GLYPH_FLAG_DEFINED = 1,
} hb_glyph_flags_t;
typedef struct hb_glyph_position_t hb_glyph_position_t;
typedef struct hb_segment_properties_t hb_segment_properties_t;
typedef enum {
  HB_BUFFER_CONTENT_TYPE_INVALID = 0,
  HB_BUFFER_CONTENT_TYPE_UNICODE = 1,
  HB_BUFFER_CONTENT_TYPE_GLYPHS = 2,
} hb_buffer_content_type_t;
typedef enum {
  HB_BUFFER_FLAG_DEFAULT = 0,
  HB_BUFFER_FLAG_BOT = 1,
  HB_BUFFER_FLAG_EOT = 2,
  HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES = 4,
  HB_BUFFER_FLAG_REMOVE_DEFAULT_IGNORABLES = 8,
  HB_BUFFER_FLAG_DO_NOT_INSERT_DOTTED_CIRCLE = 16,
} hb_buffer_flags_t;
typedef enum {
  HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES = 0,
  HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS = 1,
  HB_BUFFER_CLUSTER_LEVEL_CHARACTERS = 2,
  HB_BUFFER_CLUSTER_LEVEL_DEFAULT = 0,
} hb_buffer_cluster_level_t;
typedef enum {
  HB_BUFFER_SERIALIZE_FLAG_DEFAULT = 0,
  HB_BUFFER_SERIALIZE_FLAG_NO_CLUSTERS = 1,
  HB_BUFFER_SERIALIZE_FLAG_NO_POSITIONS = 2,
  HB_BUFFER_SERIALIZE_FLAG_NO_GLYPH_NAMES = 4,
  HB_BUFFER_SERIALIZE_FLAG_GLYPH_EXTENTS = 8,
  HB_BUFFER_SERIALIZE_FLAG_GLYPH_FLAGS = 16,
  HB_BUFFER_SERIALIZE_FLAG_NO_ADVANCES = 32,
} hb_buffer_serialize_flags_t;
typedef enum {
  HB_BUFFER_SERIALIZE_FORMAT_TEXT = 1413830740,
  HB_BUFFER_SERIALIZE_FORMAT_JSON = 1246973774,
  HB_BUFFER_SERIALIZE_FORMAT_INVALID = 0,
} hb_buffer_serialize_format_t;
typedef enum {
  HB_BUFFER_DIFF_FLAG_EQUAL = 0,
  HB_BUFFER_DIFF_FLAG_CONTENT_TYPE_MISMATCH = 1,
  HB_BUFFER_DIFF_FLAG_LENGTH_MISMATCH = 2,
  HB_BUFFER_DIFF_FLAG_NOTDEF_PRESENT = 4,
  HB_BUFFER_DIFF_FLAG_DOTTED_CIRCLE_PRESENT = 8,
  HB_BUFFER_DIFF_FLAG_CODEPOINT_MISMATCH = 16,
  HB_BUFFER_DIFF_FLAG_CLUSTER_MISMATCH = 32,
  HB_BUFFER_DIFF_FLAG_GLYPH_FLAGS_MISMATCH = 64,
  HB_BUFFER_DIFF_FLAG_POSITION_MISMATCH = 128,
} hb_buffer_diff_flags_t;
struct hb_user_data_key_t {
  char unused;
};
struct hb_feature_t {
  hb_tag_t tag;
  uint32_t value;
  unsigned int start;
  unsigned int end;
};
struct hb_variation_t {
  hb_tag_t tag;
  float value;
};
struct hb_blob_t;
typedef struct hb_blob_t hb_blob_t;
struct hb_unicode_funcs_t;
typedef struct hb_unicode_funcs_t hb_unicode_funcs_t;
struct hb_set_t;
typedef struct hb_set_t hb_set_t;
struct hb_face_t;
typedef struct hb_face_t hb_face_t;
struct hb_font_t;
typedef struct hb_font_t hb_font_t;
struct hb_font_funcs_t;
typedef struct hb_font_funcs_t hb_font_funcs_t;
struct hb_font_extents_t {
  hb_position_t ascender;
  hb_position_t descender;
  hb_position_t line_gap;
  hb_position_t reserved9;
  hb_position_t reserved8;
  hb_position_t reserved7;
  hb_position_t reserved6;
  hb_position_t reserved5;
  hb_position_t reserved4;
  hb_position_t reserved3;
  hb_position_t reserved2;
  hb_position_t reserved1;
};
struct hb_glyph_extents_t {
  hb_position_t x_bearing;
  hb_position_t y_bearing;
  hb_position_t width;
  hb_position_t height;
};
struct hb_glyph_info_t {
  hb_codepoint_t codepoint;
  hb_mask_t mask;
  uint32_t cluster;
  hb_var_int_t var1;
  hb_var_int_t var2;
};
struct hb_glyph_position_t {
  hb_position_t x_advance;
  hb_position_t y_advance;
  hb_position_t x_offset;
  hb_position_t y_offset;
  hb_var_int_t var;
};
struct hb_segment_properties_t {
  hb_direction_t direction;
  hb_script_t script;
  const struct hb_language_impl_t *language;
  void *reserved1;
  void *reserved2;
};
struct hb_buffer_t;
typedef struct hb_buffer_t hb_buffer_t;
struct hb_map_t;
typedef struct hb_map_t hb_map_t;
struct hb_shape_plan_t;
typedef struct hb_shape_plan_t hb_shape_plan_t;
typedef hb_bool_t (*hb_font_get_font_h_extents_func_t)(hb_font_t *, void *, hb_font_extents_t *, void *);
typedef hb_bool_t (*hb_font_get_font_v_extents_func_t)(hb_font_t *, void *, hb_font_extents_t *, void *);
typedef hb_position_t (*hb_font_get_glyph_h_advance_func_t)(hb_font_t *, void *, hb_codepoint_t, void *);
typedef hb_position_t (*hb_font_get_glyph_v_advance_func_t)(hb_font_t *, void *, hb_codepoint_t, void *);
typedef void (*hb_font_get_glyph_h_advances_func_t)(hb_font_t *, void *, unsigned int, const hb_codepoint_t *, unsigned int, hb_position_t *, unsigned int, void *);
typedef void (*hb_font_get_glyph_v_advances_func_t)(hb_font_t *, void *, unsigned int, const hb_codepoint_t *, unsigned int, hb_position_t *, unsigned int, void *);
typedef hb_bool_t (*hb_font_get_glyph_h_origin_func_t)(hb_font_t *, void *, hb_codepoint_t, hb_position_t *, hb_position_t *, void *);
typedef hb_bool_t (*hb_font_get_glyph_v_origin_func_t)(hb_font_t *, void *, hb_codepoint_t, hb_position_t *, hb_position_t *, void *);
typedef hb_position_t (*hb_font_get_glyph_h_kerning_func_t)(hb_font_t *, void *, hb_codepoint_t, hb_codepoint_t, void *);
typedef hb_position_t (*hb_font_get_glyph_v_kerning_func_t)(hb_font_t *, void *, hb_codepoint_t, hb_codepoint_t, void *);
typedef void (*hb_destroy_func_t)(void *);
typedef hb_unicode_combining_class_t (*hb_unicode_combining_class_func_t)(hb_unicode_funcs_t *, hb_codepoint_t, void *);
typedef hb_unicode_general_category_t (*hb_unicode_general_category_func_t)(hb_unicode_funcs_t *, hb_codepoint_t, void *);
typedef hb_codepoint_t (*hb_unicode_mirroring_func_t)(hb_unicode_funcs_t *, hb_codepoint_t, void *);
typedef hb_script_t (*hb_unicode_script_func_t)(hb_unicode_funcs_t *, hb_codepoint_t, void *);
typedef hb_bool_t (*hb_unicode_compose_func_t)(hb_unicode_funcs_t *, hb_codepoint_t, hb_codepoint_t, hb_codepoint_t *, void *);
typedef hb_bool_t (*hb_unicode_decompose_func_t)(hb_unicode_funcs_t *, hb_codepoint_t, hb_codepoint_t *, hb_codepoint_t *, void *);
typedef hb_bool_t (*hb_font_get_font_extents_func_t)(hb_font_t *, void *, hb_font_extents_t *, void *);
typedef hb_bool_t (*hb_font_get_nominal_glyph_func_t)(hb_font_t *, void *, hb_codepoint_t, hb_codepoint_t *, void *);
typedef hb_bool_t (*hb_font_get_variation_glyph_func_t)(hb_font_t *, void *, hb_codepoint_t, hb_codepoint_t, hb_codepoint_t *, void *);
typedef unsigned int (*hb_font_get_nominal_glyphs_func_t)(hb_font_t *, void *, unsigned int, const hb_codepoint_t *, unsigned int, hb_codepoint_t *, unsigned int, void *);
typedef hb_position_t (*hb_font_get_glyph_advance_func_t)(hb_font_t *, void *, hb_codepoint_t, void *);
typedef void (*hb_font_get_glyph_advances_func_t)(hb_font_t *, void *, unsigned int, const hb_codepoint_t *, unsigned int, hb_position_t *, unsigned int, void *);
typedef hb_bool_t (*hb_font_get_glyph_origin_func_t)(hb_font_t *, void *, hb_codepoint_t, hb_position_t *, hb_position_t *, void *);
typedef hb_position_t (*hb_font_get_glyph_kerning_func_t)(hb_font_t *, void *, hb_codepoint_t, hb_codepoint_t, void *);
typedef hb_bool_t (*hb_font_get_glyph_extents_func_t)(hb_font_t *, void *, hb_codepoint_t, hb_glyph_extents_t *, void *);
typedef hb_bool_t (*hb_font_get_glyph_contour_point_func_t)(hb_font_t *, void *, hb_codepoint_t, unsigned int, hb_position_t *, hb_position_t *, void *);
typedef hb_bool_t (*hb_font_get_glyph_name_func_t)(hb_font_t *, void *, hb_codepoint_t, char *, unsigned int, void *);
typedef hb_bool_t (*hb_font_get_glyph_from_name_func_t)(hb_font_t *, void *, const char *, int, hb_codepoint_t *, void *);
typedef hb_bool_t (*hb_buffer_message_func_t)(hb_buffer_t *, hb_font_t *, const char *, void *);
typedef hb_bool_t (*hb_font_get_glyph_func_t)(hb_font_t *, void *, hb_codepoint_t, hb_codepoint_t, hb_codepoint_t *, void *);
typedef unsigned int (*hb_unicode_eastasian_width_func_t)(hb_unicode_funcs_t *, hb_codepoint_t, void *);
typedef unsigned int (*hb_unicode_decompose_compatibility_func_t)(hb_unicode_funcs_t *, hb_codepoint_t, hb_codepoint_t *, void *);
hb_tag_t hb_tag_from_string(const char *, int);
void hb_tag_to_string(hb_tag_t, char *);
hb_direction_t hb_direction_from_string(const char *, int);
const char *hb_direction_to_string(hb_direction_t);
const struct hb_language_impl_t *hb_language_from_string(const char *, int);
const char *hb_language_to_string(const struct hb_language_impl_t *);
const struct hb_language_impl_t *hb_language_get_default(void);
hb_script_t hb_script_from_iso15924_tag(hb_tag_t);
hb_script_t hb_script_from_string(const char *, int);
hb_tag_t hb_script_to_iso15924_tag(hb_script_t);
hb_direction_t hb_script_get_horizontal_direction(hb_script_t);
hb_bool_t hb_feature_from_string(const char *, int, hb_feature_t *);
void hb_feature_to_string(hb_feature_t *, char *, unsigned int);
hb_bool_t hb_variation_from_string(const char *, int, hb_variation_t *);
void hb_variation_to_string(hb_variation_t *, char *, unsigned int);
uint8_t hb_color_get_alpha(hb_color_t);
uint8_t hb_color_get_red(hb_color_t);
uint8_t hb_color_get_green(hb_color_t);
uint8_t hb_color_get_blue(hb_color_t);
hb_blob_t *hb_blob_create(const char *, unsigned int, hb_memory_mode_t, void *, hb_destroy_func_t);
hb_blob_t *hb_blob_create_from_file(const char *);
hb_blob_t *hb_blob_create_sub_blob(hb_blob_t *, unsigned int, unsigned int);
hb_blob_t *hb_blob_copy_writable_or_fail(hb_blob_t *);
hb_blob_t *hb_blob_get_empty(void);
hb_blob_t *hb_blob_reference(hb_blob_t *);
void hb_blob_destroy(hb_blob_t *);
hb_bool_t hb_blob_set_user_data(hb_blob_t *, hb_user_data_key_t *, void *, hb_destroy_func_t, hb_bool_t);
void *hb_blob_get_user_data(hb_blob_t *, hb_user_data_key_t *);
void hb_blob_make_immutable(hb_blob_t *);
hb_bool_t hb_blob_is_immutable(hb_blob_t *);
unsigned int hb_blob_get_length(hb_blob_t *);
const char *hb_blob_get_data(hb_blob_t *, unsigned int *);
char *hb_blob_get_data_writable(hb_blob_t *, unsigned int *);
hb_unicode_funcs_t *hb_unicode_funcs_get_default(void);
hb_unicode_funcs_t *hb_unicode_funcs_create(hb_unicode_funcs_t *);
hb_unicode_funcs_t *hb_unicode_funcs_get_empty(void);
hb_unicode_funcs_t *hb_unicode_funcs_reference(hb_unicode_funcs_t *);
void hb_unicode_funcs_destroy(hb_unicode_funcs_t *);
hb_bool_t hb_unicode_funcs_set_user_data(hb_unicode_funcs_t *, hb_user_data_key_t *, void *, hb_destroy_func_t, hb_bool_t);
void *hb_unicode_funcs_get_user_data(hb_unicode_funcs_t *, hb_user_data_key_t *);
void hb_unicode_funcs_make_immutable(hb_unicode_funcs_t *);
hb_bool_t hb_unicode_funcs_is_immutable(hb_unicode_funcs_t *);
hb_unicode_funcs_t *hb_unicode_funcs_get_parent(hb_unicode_funcs_t *);
void hb_unicode_funcs_set_combining_class_func(hb_unicode_funcs_t *, hb_unicode_combining_class_func_t, void *, hb_destroy_func_t);
void hb_unicode_funcs_set_general_category_func(hb_unicode_funcs_t *, hb_unicode_general_category_func_t, void *, hb_destroy_func_t);
void hb_unicode_funcs_set_mirroring_func(hb_unicode_funcs_t *, hb_unicode_mirroring_func_t, void *, hb_destroy_func_t);
void hb_unicode_funcs_set_script_func(hb_unicode_funcs_t *, hb_unicode_script_func_t, void *, hb_destroy_func_t);
void hb_unicode_funcs_set_compose_func(hb_unicode_funcs_t *, hb_unicode_compose_func_t, void *, hb_destroy_func_t);
void hb_unicode_funcs_set_decompose_func(hb_unicode_funcs_t *, hb_unicode_decompose_func_t, void *, hb_destroy_func_t);
hb_unicode_combining_class_t hb_unicode_combining_class(hb_unicode_funcs_t *, hb_codepoint_t);
hb_unicode_general_category_t hb_unicode_general_category(hb_unicode_funcs_t *, hb_codepoint_t);
hb_codepoint_t hb_unicode_mirroring(hb_unicode_funcs_t *, hb_codepoint_t);
hb_script_t hb_unicode_script(hb_unicode_funcs_t *, hb_codepoint_t);
hb_bool_t hb_unicode_compose(hb_unicode_funcs_t *, hb_codepoint_t, hb_codepoint_t, hb_codepoint_t *);
hb_bool_t hb_unicode_decompose(hb_unicode_funcs_t *, hb_codepoint_t, hb_codepoint_t *, hb_codepoint_t *);
hb_set_t *hb_set_create(void);
hb_set_t *hb_set_get_empty(void);
hb_set_t *hb_set_reference(hb_set_t *);
void hb_set_destroy(hb_set_t *);
hb_bool_t hb_set_set_user_data(hb_set_t *, hb_user_data_key_t *, void *, hb_destroy_func_t, hb_bool_t);
void *hb_set_get_user_data(hb_set_t *, hb_user_data_key_t *);
hb_bool_t hb_set_allocation_successful(const hb_set_t *);
void hb_set_clear(hb_set_t *);
hb_bool_t hb_set_is_empty(const hb_set_t *);
hb_bool_t hb_set_has(const hb_set_t *, hb_codepoint_t);
void hb_set_add(hb_set_t *, hb_codepoint_t);
void hb_set_add_range(hb_set_t *, hb_codepoint_t, hb_codepoint_t);
void hb_set_del(hb_set_t *, hb_codepoint_t);
void hb_set_del_range(hb_set_t *, hb_codepoint_t, hb_codepoint_t);
hb_bool_t hb_set_is_equal(const hb_set_t *, const hb_set_t *);
hb_bool_t hb_set_is_subset(const hb_set_t *, const hb_set_t *);
void hb_set_set(hb_set_t *, const hb_set_t *);
void hb_set_union(hb_set_t *, const hb_set_t *);
void hb_set_intersect(hb_set_t *, const hb_set_t *);
void hb_set_subtract(hb_set_t *, const hb_set_t *);
void hb_set_symmetric_difference(hb_set_t *, const hb_set_t *);
unsigned int hb_set_get_population(const hb_set_t *);
hb_codepoint_t hb_set_get_min(const hb_set_t *);
hb_codepoint_t hb_set_get_max(const hb_set_t *);
hb_bool_t hb_set_next(const hb_set_t *, hb_codepoint_t *);
hb_bool_t hb_set_previous(const hb_set_t *, hb_codepoint_t *);
hb_bool_t hb_set_next_range(const hb_set_t *, hb_codepoint_t *, hb_codepoint_t *);
hb_bool_t hb_set_previous_range(const hb_set_t *, hb_codepoint_t *, hb_codepoint_t *);
unsigned int hb_face_count(hb_blob_t *);
hb_face_t *hb_face_create(hb_blob_t *, unsigned int);
hb_face_t *hb_face_create_for_tables(hb_blob_t *(*)(hb_face_t *, hb_tag_t, void *), void *, hb_destroy_func_t);
hb_face_t *hb_face_get_empty(void);
hb_face_t *hb_face_reference(hb_face_t *);
void hb_face_destroy(hb_face_t *);
hb_bool_t hb_face_set_user_data(hb_face_t *, hb_user_data_key_t *, void *, hb_destroy_func_t, hb_bool_t);
void *hb_face_get_user_data(const hb_face_t *, hb_user_data_key_t *);
void hb_face_make_immutable(hb_face_t *);
hb_bool_t hb_face_is_immutable(const hb_face_t *);
hb_blob_t *hb_face_reference_table(const hb_face_t *, hb_tag_t);
hb_blob_t *hb_face_reference_blob(hb_face_t *);
void hb_face_set_index(hb_face_t *, unsigned int);
unsigned int hb_face_get_index(const hb_face_t *);
void hb_face_set_upem(hb_face_t *, unsigned int);
unsigned int hb_face_get_upem(const hb_face_t *);
void hb_face_set_glyph_count(hb_face_t *, unsigned int);
unsigned int hb_face_get_glyph_count(const hb_face_t *);
unsigned int hb_face_get_table_tags(const hb_face_t *, unsigned int, unsigned int *, hb_tag_t *);
void hb_face_collect_unicodes(hb_face_t *, hb_set_t *);
void hb_face_collect_variation_selectors(hb_face_t *, hb_set_t *);
void hb_face_collect_variation_unicodes(hb_face_t *, hb_codepoint_t, hb_set_t *);
hb_face_t *hb_face_builder_create(void);
hb_bool_t hb_face_builder_add_table(hb_face_t *, hb_tag_t, hb_blob_t *);
hb_font_funcs_t *hb_font_funcs_create(void);
hb_font_funcs_t *hb_font_funcs_get_empty(void);
hb_font_funcs_t *hb_font_funcs_reference(hb_font_funcs_t *);
void hb_font_funcs_destroy(hb_font_funcs_t *);
hb_bool_t hb_font_funcs_set_user_data(hb_font_funcs_t *, hb_user_data_key_t *, void *, hb_destroy_func_t, hb_bool_t);
void *hb_font_funcs_get_user_data(hb_font_funcs_t *, hb_user_data_key_t *);
void hb_font_funcs_make_immutable(hb_font_funcs_t *);
hb_bool_t hb_font_funcs_is_immutable(hb_font_funcs_t *);
void hb_font_funcs_set_font_h_extents_func(hb_font_funcs_t *, hb_font_get_font_h_extents_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_font_v_extents_func(hb_font_funcs_t *, hb_font_get_font_v_extents_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_nominal_glyph_func(hb_font_funcs_t *, hb_font_get_nominal_glyph_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_nominal_glyphs_func(hb_font_funcs_t *, hb_font_get_nominal_glyphs_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_variation_glyph_func(hb_font_funcs_t *, hb_font_get_variation_glyph_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_glyph_h_advance_func(hb_font_funcs_t *, hb_font_get_glyph_h_advance_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_glyph_v_advance_func(hb_font_funcs_t *, hb_font_get_glyph_v_advance_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_glyph_h_advances_func(hb_font_funcs_t *, hb_font_get_glyph_h_advances_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_glyph_v_advances_func(hb_font_funcs_t *, hb_font_get_glyph_v_advances_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_glyph_h_origin_func(hb_font_funcs_t *, hb_font_get_glyph_h_origin_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_glyph_v_origin_func(hb_font_funcs_t *, hb_font_get_glyph_v_origin_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_glyph_h_kerning_func(hb_font_funcs_t *, hb_font_get_glyph_h_kerning_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_glyph_extents_func(hb_font_funcs_t *, hb_font_get_glyph_extents_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_glyph_contour_point_func(hb_font_funcs_t *, hb_font_get_glyph_contour_point_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_glyph_name_func(hb_font_funcs_t *, hb_font_get_glyph_name_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_glyph_from_name_func(hb_font_funcs_t *, hb_font_get_glyph_from_name_func_t, void *, hb_destroy_func_t);
hb_bool_t hb_font_get_h_extents(hb_font_t *, hb_font_extents_t *);
hb_bool_t hb_font_get_v_extents(hb_font_t *, hb_font_extents_t *);
hb_bool_t hb_font_get_nominal_glyph(hb_font_t *, hb_codepoint_t, hb_codepoint_t *);
hb_bool_t hb_font_get_variation_glyph(hb_font_t *, hb_codepoint_t, hb_codepoint_t, hb_codepoint_t *);
unsigned int hb_font_get_nominal_glyphs(hb_font_t *, unsigned int, const hb_codepoint_t *, unsigned int, hb_codepoint_t *, unsigned int);
hb_position_t hb_font_get_glyph_h_advance(hb_font_t *, hb_codepoint_t);
hb_position_t hb_font_get_glyph_v_advance(hb_font_t *, hb_codepoint_t);
void hb_font_get_glyph_h_advances(hb_font_t *, unsigned int, const hb_codepoint_t *, unsigned int, hb_position_t *, unsigned int);
void hb_font_get_glyph_v_advances(hb_font_t *, unsigned int, const hb_codepoint_t *, unsigned int, hb_position_t *, unsigned int);
hb_bool_t hb_font_get_glyph_h_origin(hb_font_t *, hb_codepoint_t, hb_position_t *, hb_position_t *);
hb_bool_t hb_font_get_glyph_v_origin(hb_font_t *, hb_codepoint_t, hb_position_t *, hb_position_t *);
hb_position_t hb_font_get_glyph_h_kerning(hb_font_t *, hb_codepoint_t, hb_codepoint_t);
hb_bool_t hb_font_get_glyph_extents(hb_font_t *, hb_codepoint_t, hb_glyph_extents_t *);
hb_bool_t hb_font_get_glyph_contour_point(hb_font_t *, hb_codepoint_t, unsigned int, hb_position_t *, hb_position_t *);
hb_bool_t hb_font_get_glyph_name(hb_font_t *, hb_codepoint_t, char *, unsigned int);
hb_bool_t hb_font_get_glyph_from_name(hb_font_t *, const char *, int, hb_codepoint_t *);
hb_bool_t hb_font_get_glyph(hb_font_t *, hb_codepoint_t, hb_codepoint_t, hb_codepoint_t *);
void hb_font_get_extents_for_direction(hb_font_t *, hb_direction_t, hb_font_extents_t *);
void hb_font_get_glyph_advance_for_direction(hb_font_t *, hb_codepoint_t, hb_direction_t, hb_position_t *, hb_position_t *);
void hb_font_get_glyph_advances_for_direction(hb_font_t *, hb_direction_t, unsigned int, const hb_codepoint_t *, unsigned int, hb_position_t *, unsigned int);
void hb_font_get_glyph_origin_for_direction(hb_font_t *, hb_codepoint_t, hb_direction_t, hb_position_t *, hb_position_t *);
void hb_font_add_glyph_origin_for_direction(hb_font_t *, hb_codepoint_t, hb_direction_t, hb_position_t *, hb_position_t *);
void hb_font_subtract_glyph_origin_for_direction(hb_font_t *, hb_codepoint_t, hb_direction_t, hb_position_t *, hb_position_t *);
void hb_font_get_glyph_kerning_for_direction(hb_font_t *, hb_codepoint_t, hb_codepoint_t, hb_direction_t, hb_position_t *, hb_position_t *);
hb_bool_t hb_font_get_glyph_extents_for_origin(hb_font_t *, hb_codepoint_t, hb_direction_t, hb_glyph_extents_t *);
hb_bool_t hb_font_get_glyph_contour_point_for_origin(hb_font_t *, hb_codepoint_t, unsigned int, hb_direction_t, hb_position_t *, hb_position_t *);
void hb_font_glyph_to_string(hb_font_t *, hb_codepoint_t, char *, unsigned int);
hb_bool_t hb_font_glyph_from_string(hb_font_t *, const char *, int, hb_codepoint_t *);
hb_font_t *hb_font_create(hb_face_t *);
hb_font_t *hb_font_create_sub_font(hb_font_t *);
hb_font_t *hb_font_get_empty(void);
hb_font_t *hb_font_reference(hb_font_t *);
void hb_font_destroy(hb_font_t *);
hb_bool_t hb_font_set_user_data(hb_font_t *, hb_user_data_key_t *, void *, hb_destroy_func_t, hb_bool_t);
void *hb_font_get_user_data(hb_font_t *, hb_user_data_key_t *);
void hb_font_make_immutable(hb_font_t *);
hb_bool_t hb_font_is_immutable(hb_font_t *);
void hb_font_set_parent(hb_font_t *, hb_font_t *);
hb_font_t *hb_font_get_parent(hb_font_t *);
void hb_font_set_face(hb_font_t *, hb_face_t *);
hb_face_t *hb_font_get_face(hb_font_t *);
void hb_font_set_funcs(hb_font_t *, hb_font_funcs_t *, void *, hb_destroy_func_t);
void hb_font_set_funcs_data(hb_font_t *, void *, hb_destroy_func_t);
void hb_font_set_scale(hb_font_t *, int, int);
void hb_font_get_scale(hb_font_t *, int *, int *);
void hb_font_set_ppem(hb_font_t *, unsigned int, unsigned int);
void hb_font_get_ppem(hb_font_t *, unsigned int *, unsigned int *);
void hb_font_set_ptem(hb_font_t *, float);
float hb_font_get_ptem(hb_font_t *);
void hb_font_set_variations(hb_font_t *, const hb_variation_t *, unsigned int);
void hb_font_set_var_coords_design(hb_font_t *, const float *, unsigned int);
void hb_font_set_var_coords_normalized(hb_font_t *, const int *, unsigned int);
const int *hb_font_get_var_coords_normalized(hb_font_t *, unsigned int *);
void hb_font_set_var_named_instance(hb_font_t *, unsigned int);
hb_glyph_flags_t hb_glyph_info_get_glyph_flags(const hb_glyph_info_t *);
hb_bool_t hb_segment_properties_equal(const hb_segment_properties_t *, const hb_segment_properties_t *);
unsigned int hb_segment_properties_hash(const hb_segment_properties_t *);
hb_buffer_t *hb_buffer_create(void);
hb_buffer_t *hb_buffer_get_empty(void);
hb_buffer_t *hb_buffer_reference(hb_buffer_t *);
void hb_buffer_destroy(hb_buffer_t *);
hb_bool_t hb_buffer_set_user_data(hb_buffer_t *, hb_user_data_key_t *, void *, hb_destroy_func_t, hb_bool_t);
void *hb_buffer_get_user_data(hb_buffer_t *, hb_user_data_key_t *);
void hb_buffer_set_content_type(hb_buffer_t *, hb_buffer_content_type_t);
hb_buffer_content_type_t hb_buffer_get_content_type(hb_buffer_t *);
void hb_buffer_set_unicode_funcs(hb_buffer_t *, hb_unicode_funcs_t *);
hb_unicode_funcs_t *hb_buffer_get_unicode_funcs(hb_buffer_t *);
void hb_buffer_set_direction(hb_buffer_t *, hb_direction_t);
hb_direction_t hb_buffer_get_direction(hb_buffer_t *);
void hb_buffer_set_script(hb_buffer_t *, hb_script_t);
hb_script_t hb_buffer_get_script(hb_buffer_t *);
void hb_buffer_set_language(hb_buffer_t *, const struct hb_language_impl_t *);
const struct hb_language_impl_t *hb_buffer_get_language(hb_buffer_t *);
void hb_buffer_set_segment_properties(hb_buffer_t *, const hb_segment_properties_t *);
void hb_buffer_get_segment_properties(hb_buffer_t *, hb_segment_properties_t *);
void hb_buffer_guess_segment_properties(hb_buffer_t *);
void hb_buffer_set_flags(hb_buffer_t *, hb_buffer_flags_t);
hb_buffer_flags_t hb_buffer_get_flags(hb_buffer_t *);
void hb_buffer_set_cluster_level(hb_buffer_t *, hb_buffer_cluster_level_t);
hb_buffer_cluster_level_t hb_buffer_get_cluster_level(hb_buffer_t *);
void hb_buffer_set_replacement_codepoint(hb_buffer_t *, hb_codepoint_t);
hb_codepoint_t hb_buffer_get_replacement_codepoint(hb_buffer_t *);
void hb_buffer_set_invisible_glyph(hb_buffer_t *, hb_codepoint_t);
hb_codepoint_t hb_buffer_get_invisible_glyph(hb_buffer_t *);
void hb_buffer_reset(hb_buffer_t *);
void hb_buffer_clear_contents(hb_buffer_t *);
hb_bool_t hb_buffer_pre_allocate(hb_buffer_t *, unsigned int);
hb_bool_t hb_buffer_allocation_successful(hb_buffer_t *);
void hb_buffer_reverse(hb_buffer_t *);
void hb_buffer_reverse_range(hb_buffer_t *, unsigned int, unsigned int);
void hb_buffer_reverse_clusters(hb_buffer_t *);
void hb_buffer_add(hb_buffer_t *, hb_codepoint_t, unsigned int);
void hb_buffer_add_utf8(hb_buffer_t *, const char *, int, unsigned int, int);
void hb_buffer_add_utf16(hb_buffer_t *, const uint16_t *, int, unsigned int, int);
void hb_buffer_add_utf32(hb_buffer_t *, const uint32_t *, int, unsigned int, int);
void hb_buffer_add_latin1(hb_buffer_t *, const uint8_t *, int, unsigned int, int);
void hb_buffer_add_codepoints(hb_buffer_t *, const hb_codepoint_t *, int, unsigned int, int);
void hb_buffer_append(hb_buffer_t *, hb_buffer_t *, unsigned int, unsigned int);
hb_bool_t hb_buffer_set_length(hb_buffer_t *, unsigned int);
unsigned int hb_buffer_get_length(hb_buffer_t *);
hb_glyph_info_t *hb_buffer_get_glyph_infos(hb_buffer_t *, unsigned int *);
hb_glyph_position_t *hb_buffer_get_glyph_positions(hb_buffer_t *, unsigned int *);
void hb_buffer_normalize_glyphs(hb_buffer_t *);
hb_buffer_serialize_format_t hb_buffer_serialize_format_from_string(const char *, int);
const char *hb_buffer_serialize_format_to_string(hb_buffer_serialize_format_t);
const char **hb_buffer_serialize_list_formats(void);
unsigned int hb_buffer_serialize_glyphs(hb_buffer_t *, unsigned int, unsigned int, char *, unsigned int, unsigned int *, hb_font_t *, hb_buffer_serialize_format_t, hb_buffer_serialize_flags_t);
hb_bool_t hb_buffer_deserialize_glyphs(hb_buffer_t *, const char *, int, const char **, hb_font_t *, hb_buffer_serialize_format_t);
hb_buffer_diff_flags_t hb_buffer_diff(hb_buffer_t *, hb_buffer_t *, hb_codepoint_t, unsigned int);
void hb_buffer_set_message_func(hb_buffer_t *, hb_buffer_message_func_t, void *, hb_destroy_func_t);
void hb_font_funcs_set_glyph_func(hb_font_funcs_t *, hb_font_get_glyph_func_t, void *, hb_destroy_func_t) __attribute__((deprecated("Use 'hb_font_funcs_set_nominal_glyph_func and hb_font_funcs_set_variation_glyph_func' instead")));
void hb_set_invert(hb_set_t *);
void hb_unicode_funcs_set_eastasian_width_func(hb_unicode_funcs_t *, hb_unicode_eastasian_width_func_t, void *, hb_destroy_func_t);
unsigned int hb_unicode_eastasian_width(hb_unicode_funcs_t *, hb_codepoint_t);
void hb_unicode_funcs_set_decompose_compatibility_func(hb_unicode_funcs_t *, hb_unicode_decompose_compatibility_func_t, void *, hb_destroy_func_t);
unsigned int hb_unicode_decompose_compatibility(hb_unicode_funcs_t *, hb_codepoint_t, hb_codepoint_t *);
void hb_font_funcs_set_glyph_v_kerning_func(hb_font_funcs_t *, hb_font_get_glyph_v_kerning_func_t, void *, hb_destroy_func_t);
hb_position_t hb_font_get_glyph_v_kerning(hb_font_t *, hb_codepoint_t, hb_codepoint_t);
hb_map_t *hb_map_create(void);
hb_map_t *hb_map_get_empty(void);
hb_map_t *hb_map_reference(hb_map_t *);
void hb_map_destroy(hb_map_t *);
hb_bool_t hb_map_set_user_data(hb_map_t *, hb_user_data_key_t *, void *, hb_destroy_func_t, hb_bool_t);
void *hb_map_get_user_data(hb_map_t *, hb_user_data_key_t *);
hb_bool_t hb_map_allocation_successful(const hb_map_t *);
void hb_map_clear(hb_map_t *);
hb_bool_t hb_map_is_empty(const hb_map_t *);
unsigned int hb_map_get_population(const hb_map_t *);
void hb_map_set(hb_map_t *, hb_codepoint_t, hb_codepoint_t);
hb_codepoint_t hb_map_get(const hb_map_t *, hb_codepoint_t);
void hb_map_del(hb_map_t *, hb_codepoint_t);
hb_bool_t hb_map_has(const hb_map_t *, hb_codepoint_t);
void hb_shape(hb_font_t *, hb_buffer_t *, const hb_feature_t *, unsigned int);
hb_bool_t hb_shape_full(hb_font_t *, hb_buffer_t *, const hb_feature_t *, unsigned int, const char *const *);
const char **hb_shape_list_shapers(void);
hb_shape_plan_t *hb_shape_plan_create(hb_face_t *, const hb_segment_properties_t *, const hb_feature_t *, unsigned int, const char *const *);
hb_shape_plan_t *hb_shape_plan_create_cached(hb_face_t *, const hb_segment_properties_t *, const hb_feature_t *, unsigned int, const char *const *);
hb_shape_plan_t *hb_shape_plan_create2(hb_face_t *, const hb_segment_properties_t *, const hb_feature_t *, unsigned int, const int *, unsigned int, const char *const *);
hb_shape_plan_t *hb_shape_plan_create_cached2(hb_face_t *, const hb_segment_properties_t *, const hb_feature_t *, unsigned int, const int *, unsigned int, const char *const *);
hb_shape_plan_t *hb_shape_plan_get_empty(void);
hb_shape_plan_t *hb_shape_plan_reference(hb_shape_plan_t *);
void hb_shape_plan_destroy(hb_shape_plan_t *);
hb_bool_t hb_shape_plan_set_user_data(hb_shape_plan_t *, hb_user_data_key_t *, void *, hb_destroy_func_t, hb_bool_t);
void *hb_shape_plan_get_user_data(hb_shape_plan_t *, hb_user_data_key_t *);
hb_bool_t hb_shape_plan_execute(hb_shape_plan_t *, hb_font_t *, hb_buffer_t *, const hb_feature_t *, unsigned int);
const char *hb_shape_plan_get_shaper(hb_shape_plan_t *);
void hb_version(unsigned int *, unsigned int *, unsigned int *);
const char *hb_version_string(void);
hb_bool_t hb_version_atleast(unsigned int, unsigned int, unsigned int);
typedef struct FT_FaceRec_ *FT_Face;
hb_face_t *hb_ft_face_create(FT_Face, hb_destroy_func_t);
hb_face_t *hb_ft_face_create_cached(FT_Face);
hb_face_t *hb_ft_face_create_referenced(FT_Face);
hb_font_t *hb_ft_font_create(FT_Face, hb_destroy_func_t);
hb_font_t *hb_ft_font_create_referenced(FT_Face);
FT_Face hb_ft_font_get_face(hb_font_t *);
FT_Face hb_ft_font_lock_face(hb_font_t *);
void hb_ft_font_unlock_face(hb_font_t *);
void hb_ft_font_set_load_flags(hb_font_t *, int);
int hb_ft_font_get_load_flags(hb_font_t *);
void hb_ft_font_changed(hb_font_t *);
void hb_ft_font_set_funcs(hb_font_t *);
]]
