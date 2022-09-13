local ffi = require("ffi")

ffi.cdef[[
typedef int hb_bool_t;
typedef uint32_t hb_codepoint_t;
typedef int32_t hb_position_t;
typedef uint32_t hb_mask_t;
typedef uint32_t hb_tag_t;
typedef uint32_t hb_color_t;
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
typedef const struct hb_language_impl_t *hb_language_t;
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
  HB_SCRIPT_CYPRO_MINOAN = 1131441518,
  HB_SCRIPT_OLD_UYGHUR = 1333094258,
  HB_SCRIPT_TANGSA = 1416524641,
  HB_SCRIPT_TOTO = 1416590447,
  HB_SCRIPT_VITHKUQI = 1449751656,
  HB_SCRIPT_MATH = 1517122664,
  HB_SCRIPT_INVALID = 0,
  _HB_SCRIPT_MAX_VALUE = 2147483647,
  _HB_SCRIPT_MAX_VALUE_SIGNED = 2147483647,
} hb_script_t;
struct hb_user_data_key_t {
  char unused;
};
typedef struct hb_user_data_key_t hb_user_data_key_t;
struct hb_feature_t {
  hb_tag_t tag;
  uint32_t value;
  unsigned int start;
  unsigned int end;
};
typedef struct hb_feature_t hb_feature_t;
struct hb_variation_t {
  hb_tag_t tag;
  float value;
};
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
typedef enum {
  HB_GLYPH_FLAG_UNSAFE_TO_BREAK = 1,
  HB_GLYPH_FLAG_UNSAFE_TO_CONCAT = 2,
  HB_GLYPH_FLAG_SAFE_TO_INSERT_TATWEEL = 4,
  HB_GLYPH_FLAG_DEFINED = 7,
} hb_glyph_flags_t;
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
  HB_BUFFER_FLAG_VERIFY = 32,
  HB_BUFFER_FLAG_PRODUCE_UNSAFE_TO_CONCAT = 64,
  HB_BUFFER_FLAG_PRODUCE_SAFE_TO_INSERT_TATWEEL = 128,
  HB_BUFFER_FLAG_DEFINED = 255,
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
  HB_BUFFER_SERIALIZE_FLAG_DEFINED = 63,
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
typedef struct hb_blob_t hb_blob_t;
typedef struct hb_unicode_funcs_t hb_unicode_funcs_t;
typedef struct hb_set_t hb_set_t;
typedef struct hb_face_t hb_face_t;
typedef struct hb_font_t hb_font_t;
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
typedef struct hb_font_extents_t hb_font_extents_t;
struct hb_glyph_extents_t {
  hb_position_t x_bearing;
  hb_position_t y_bearing;
  hb_position_t width;
  hb_position_t height;
};
typedef struct hb_glyph_extents_t hb_glyph_extents_t;
struct hb_glyph_info_t {
  hb_codepoint_t codepoint;
  hb_mask_t mask;
  uint32_t cluster;
  hb_var_int_t var1;
  hb_var_int_t var2;
};
typedef struct hb_glyph_info_t hb_glyph_info_t;
struct hb_glyph_position_t {
  hb_position_t x_advance;
  hb_position_t y_advance;
  hb_position_t x_offset;
  hb_position_t y_offset;
  hb_var_int_t var;
};
typedef struct hb_glyph_position_t hb_glyph_position_t;
struct hb_segment_properties_t {
  hb_direction_t direction;
  hb_script_t script;
  hb_language_t language;
  void *reserved1;
  void *reserved2;
};
typedef struct hb_segment_properties_t hb_segment_properties_t;
typedef struct hb_buffer_t hb_buffer_t;
typedef struct hb_map_t hb_map_t;
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
hb_language_t hb_language_from_string(const char *, int);
const char *hb_language_to_string(hb_language_t);
hb_language_t hb_language_get_default(void);
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
void *hb_blob_get_user_data(const hb_blob_t *, hb_user_data_key_t *);
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
void *hb_unicode_funcs_get_user_data(const hb_unicode_funcs_t *, hb_user_data_key_t *);
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
void *hb_set_get_user_data(const hb_set_t *, hb_user_data_key_t *);
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
void *hb_font_funcs_get_user_data(const hb_font_funcs_t *, hb_user_data_key_t *);
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
void *hb_font_get_user_data(const hb_font_t *, hb_user_data_key_t *);
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
void *hb_buffer_get_user_data(const hb_buffer_t *, hb_user_data_key_t *);
void hb_buffer_set_content_type(hb_buffer_t *, hb_buffer_content_type_t);
hb_buffer_content_type_t hb_buffer_get_content_type(const hb_buffer_t *);
void hb_buffer_set_unicode_funcs(hb_buffer_t *, hb_unicode_funcs_t *);
hb_unicode_funcs_t *hb_buffer_get_unicode_funcs(const hb_buffer_t *);
void hb_buffer_set_direction(hb_buffer_t *, hb_direction_t);
hb_direction_t hb_buffer_get_direction(const hb_buffer_t *);
void hb_buffer_set_script(hb_buffer_t *, hb_script_t);
hb_script_t hb_buffer_get_script(const hb_buffer_t *);
void hb_buffer_set_language(hb_buffer_t *, hb_language_t);
hb_language_t hb_buffer_get_language(const hb_buffer_t *);
void hb_buffer_set_segment_properties(hb_buffer_t *, const hb_segment_properties_t *);
void hb_buffer_get_segment_properties(const hb_buffer_t *, hb_segment_properties_t *);
void hb_buffer_guess_segment_properties(hb_buffer_t *);
void hb_buffer_set_flags(hb_buffer_t *, hb_buffer_flags_t);
hb_buffer_flags_t hb_buffer_get_flags(const hb_buffer_t *);
void hb_buffer_set_cluster_level(hb_buffer_t *, hb_buffer_cluster_level_t);
hb_buffer_cluster_level_t hb_buffer_get_cluster_level(const hb_buffer_t *);
void hb_buffer_set_replacement_codepoint(hb_buffer_t *, hb_codepoint_t);
hb_codepoint_t hb_buffer_get_replacement_codepoint(const hb_buffer_t *);
void hb_buffer_set_invisible_glyph(hb_buffer_t *, hb_codepoint_t);
hb_codepoint_t hb_buffer_get_invisible_glyph(const hb_buffer_t *);
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
void hb_buffer_append(hb_buffer_t *, const hb_buffer_t *, unsigned int, unsigned int);
hb_bool_t hb_buffer_set_length(hb_buffer_t *, unsigned int);
unsigned int hb_buffer_get_length(const hb_buffer_t *);
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
void hb_set_invert(hb_set_t *);
void hb_font_funcs_set_glyph_v_kerning_func(hb_font_funcs_t *, hb_font_get_glyph_v_kerning_func_t, void *, hb_destroy_func_t);
hb_position_t hb_font_get_glyph_v_kerning(hb_font_t *, hb_codepoint_t, hb_codepoint_t);
hb_map_t *hb_map_create(void);
hb_map_t *hb_map_get_empty(void);
hb_map_t *hb_map_reference(hb_map_t *);
void hb_map_destroy(hb_map_t *);
hb_bool_t hb_map_set_user_data(hb_map_t *, hb_user_data_key_t *, void *, hb_destroy_func_t, hb_bool_t);
void *hb_map_get_user_data(const hb_map_t *, hb_user_data_key_t *);
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
void *hb_shape_plan_get_user_data(const hb_shape_plan_t *, hb_user_data_key_t *);
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
typedef enum {
  HB_OT_MATH_GLYPH_PART_FLAG_EXTENDER = 1,
} hb_ot_math_glyph_part_flags_t;
typedef enum {
  HB_OT_VAR_AXIS_FLAG_HIDDEN = 1,
  _HB_OT_VAR_AXIS_FLAG_MAX_VALUE = 2147483647,
} hb_ot_var_axis_flags_t;
typedef unsigned int hb_ot_name_id_t;
struct hb_ot_name_entry_t {
  hb_ot_name_id_t name_id;
  hb_var_int_t var;
  hb_language_t language;
};
typedef struct hb_ot_name_entry_t hb_ot_name_entry_t;
struct hb_ot_color_layer_t {
  hb_codepoint_t glyph;
  unsigned int color_index;
};
typedef struct hb_ot_color_layer_t hb_ot_color_layer_t;
struct hb_ot_var_axis_t {
  hb_tag_t tag;
  hb_ot_name_id_t name_id;
  float min_value;
  float default_value;
  float max_value;
};
typedef struct hb_ot_var_axis_t hb_ot_var_axis_t;
struct hb_ot_math_glyph_variant_t {
  hb_codepoint_t glyph;
  hb_position_t advance;
};
typedef struct hb_ot_math_glyph_variant_t hb_ot_math_glyph_variant_t;
struct hb_ot_math_glyph_part_t {
  hb_codepoint_t glyph;
  hb_position_t start_connector_length;
  hb_position_t end_connector_length;
  hb_position_t full_advance;
  hb_ot_math_glyph_part_flags_t flags;
};
typedef struct hb_ot_math_glyph_part_t hb_ot_math_glyph_part_t;
struct hb_ot_var_axis_info_t {
  unsigned int axis_index;
  hb_tag_t tag;
  hb_ot_name_id_t name_id;
  hb_ot_var_axis_flags_t flags;
  float min_value;
  float default_value;
  float max_value;
  unsigned int reserved;
};
typedef struct hb_ot_var_axis_info_t hb_ot_var_axis_info_t;
typedef enum {
  HB_OT_COLOR_PALETTE_FLAG_DEFAULT = 0,
  HB_OT_COLOR_PALETTE_FLAG_USABLE_WITH_LIGHT_BACKGROUND = 1,
  HB_OT_COLOR_PALETTE_FLAG_USABLE_WITH_DARK_BACKGROUND = 2,
} hb_ot_color_palette_flags_t;
typedef enum {
  HB_OT_LAYOUT_GLYPH_CLASS_UNCLASSIFIED = 0,
  HB_OT_LAYOUT_GLYPH_CLASS_BASE_GLYPH = 1,
  HB_OT_LAYOUT_GLYPH_CLASS_LIGATURE = 2,
  HB_OT_LAYOUT_GLYPH_CLASS_MARK = 3,
  HB_OT_LAYOUT_GLYPH_CLASS_COMPONENT = 4,
} hb_ot_layout_glyph_class_t;
typedef enum {
  HB_OT_LAYOUT_BASELINE_TAG_ROMAN = 1919905134,
  HB_OT_LAYOUT_BASELINE_TAG_HANGING = 1751215719,
  HB_OT_LAYOUT_BASELINE_TAG_IDEO_FACE_BOTTOM_OR_LEFT = 1768121954,
  HB_OT_LAYOUT_BASELINE_TAG_IDEO_FACE_TOP_OR_RIGHT = 1768121972,
  HB_OT_LAYOUT_BASELINE_TAG_IDEO_FACE_CENTRAL = 1231251043,
  HB_OT_LAYOUT_BASELINE_TAG_IDEO_EMBOX_BOTTOM_OR_LEFT = 1768187247,
  HB_OT_LAYOUT_BASELINE_TAG_IDEO_EMBOX_TOP_OR_RIGHT = 1768191088,
  HB_OT_LAYOUT_BASELINE_TAG_IDEO_EMBOX_CENTRAL = 1231315813,
  HB_OT_LAYOUT_BASELINE_TAG_MATH = 1835103336,
  _HB_OT_LAYOUT_BASELINE_TAG_MAX_VALUE = 2147483647,
} hb_ot_layout_baseline_tag_t;
typedef enum {
  HB_OT_MATH_CONSTANT_SCRIPT_PERCENT_SCALE_DOWN = 0,
  HB_OT_MATH_CONSTANT_SCRIPT_SCRIPT_PERCENT_SCALE_DOWN = 1,
  HB_OT_MATH_CONSTANT_DELIMITED_SUB_FORMULA_MIN_HEIGHT = 2,
  HB_OT_MATH_CONSTANT_DISPLAY_OPERATOR_MIN_HEIGHT = 3,
  HB_OT_MATH_CONSTANT_MATH_LEADING = 4,
  HB_OT_MATH_CONSTANT_AXIS_HEIGHT = 5,
  HB_OT_MATH_CONSTANT_ACCENT_BASE_HEIGHT = 6,
  HB_OT_MATH_CONSTANT_FLATTENED_ACCENT_BASE_HEIGHT = 7,
  HB_OT_MATH_CONSTANT_SUBSCRIPT_SHIFT_DOWN = 8,
  HB_OT_MATH_CONSTANT_SUBSCRIPT_TOP_MAX = 9,
  HB_OT_MATH_CONSTANT_SUBSCRIPT_BASELINE_DROP_MIN = 10,
  HB_OT_MATH_CONSTANT_SUPERSCRIPT_SHIFT_UP = 11,
  HB_OT_MATH_CONSTANT_SUPERSCRIPT_SHIFT_UP_CRAMPED = 12,
  HB_OT_MATH_CONSTANT_SUPERSCRIPT_BOTTOM_MIN = 13,
  HB_OT_MATH_CONSTANT_SUPERSCRIPT_BASELINE_DROP_MAX = 14,
  HB_OT_MATH_CONSTANT_SUB_SUPERSCRIPT_GAP_MIN = 15,
  HB_OT_MATH_CONSTANT_SUPERSCRIPT_BOTTOM_MAX_WITH_SUBSCRIPT = 16,
  HB_OT_MATH_CONSTANT_SPACE_AFTER_SCRIPT = 17,
  HB_OT_MATH_CONSTANT_UPPER_LIMIT_GAP_MIN = 18,
  HB_OT_MATH_CONSTANT_UPPER_LIMIT_BASELINE_RISE_MIN = 19,
  HB_OT_MATH_CONSTANT_LOWER_LIMIT_GAP_MIN = 20,
  HB_OT_MATH_CONSTANT_LOWER_LIMIT_BASELINE_DROP_MIN = 21,
  HB_OT_MATH_CONSTANT_STACK_TOP_SHIFT_UP = 22,
  HB_OT_MATH_CONSTANT_STACK_TOP_DISPLAY_STYLE_SHIFT_UP = 23,
  HB_OT_MATH_CONSTANT_STACK_BOTTOM_SHIFT_DOWN = 24,
  HB_OT_MATH_CONSTANT_STACK_BOTTOM_DISPLAY_STYLE_SHIFT_DOWN = 25,
  HB_OT_MATH_CONSTANT_STACK_GAP_MIN = 26,
  HB_OT_MATH_CONSTANT_STACK_DISPLAY_STYLE_GAP_MIN = 27,
  HB_OT_MATH_CONSTANT_STRETCH_STACK_TOP_SHIFT_UP = 28,
  HB_OT_MATH_CONSTANT_STRETCH_STACK_BOTTOM_SHIFT_DOWN = 29,
  HB_OT_MATH_CONSTANT_STRETCH_STACK_GAP_ABOVE_MIN = 30,
  HB_OT_MATH_CONSTANT_STRETCH_STACK_GAP_BELOW_MIN = 31,
  HB_OT_MATH_CONSTANT_FRACTION_NUMERATOR_SHIFT_UP = 32,
  HB_OT_MATH_CONSTANT_FRACTION_NUMERATOR_DISPLAY_STYLE_SHIFT_UP = 33,
  HB_OT_MATH_CONSTANT_FRACTION_DENOMINATOR_SHIFT_DOWN = 34,
  HB_OT_MATH_CONSTANT_FRACTION_DENOMINATOR_DISPLAY_STYLE_SHIFT_DOWN = 35,
  HB_OT_MATH_CONSTANT_FRACTION_NUMERATOR_GAP_MIN = 36,
  HB_OT_MATH_CONSTANT_FRACTION_NUM_DISPLAY_STYLE_GAP_MIN = 37,
  HB_OT_MATH_CONSTANT_FRACTION_RULE_THICKNESS = 38,
  HB_OT_MATH_CONSTANT_FRACTION_DENOMINATOR_GAP_MIN = 39,
  HB_OT_MATH_CONSTANT_FRACTION_DENOM_DISPLAY_STYLE_GAP_MIN = 40,
  HB_OT_MATH_CONSTANT_SKEWED_FRACTION_HORIZONTAL_GAP = 41,
  HB_OT_MATH_CONSTANT_SKEWED_FRACTION_VERTICAL_GAP = 42,
  HB_OT_MATH_CONSTANT_OVERBAR_VERTICAL_GAP = 43,
  HB_OT_MATH_CONSTANT_OVERBAR_RULE_THICKNESS = 44,
  HB_OT_MATH_CONSTANT_OVERBAR_EXTRA_ASCENDER = 45,
  HB_OT_MATH_CONSTANT_UNDERBAR_VERTICAL_GAP = 46,
  HB_OT_MATH_CONSTANT_UNDERBAR_RULE_THICKNESS = 47,
  HB_OT_MATH_CONSTANT_UNDERBAR_EXTRA_DESCENDER = 48,
  HB_OT_MATH_CONSTANT_RADICAL_VERTICAL_GAP = 49,
  HB_OT_MATH_CONSTANT_RADICAL_DISPLAY_STYLE_VERTICAL_GAP = 50,
  HB_OT_MATH_CONSTANT_RADICAL_RULE_THICKNESS = 51,
  HB_OT_MATH_CONSTANT_RADICAL_EXTRA_ASCENDER = 52,
  HB_OT_MATH_CONSTANT_RADICAL_KERN_BEFORE_DEGREE = 53,
  HB_OT_MATH_CONSTANT_RADICAL_KERN_AFTER_DEGREE = 54,
  HB_OT_MATH_CONSTANT_RADICAL_DEGREE_BOTTOM_RAISE_PERCENT = 55,
} hb_ot_math_constant_t;
typedef enum {
  HB_OT_MATH_KERN_TOP_RIGHT = 0,
  HB_OT_MATH_KERN_TOP_LEFT = 1,
  HB_OT_MATH_KERN_BOTTOM_RIGHT = 2,
  HB_OT_MATH_KERN_BOTTOM_LEFT = 3,
} hb_ot_math_kern_t;
typedef enum {
  HB_OT_META_TAG_DESIGN_LANGUAGES = 1684827751,
  HB_OT_META_TAG_SUPPORTED_LANGUAGES = 1936485991,
  _HB_OT_META_TAG_MAX_VALUE = 2147483647,
} hb_ot_meta_tag_t;
typedef enum {
  HB_OT_METRICS_TAG_HORIZONTAL_ASCENDER = 1751216995,
  HB_OT_METRICS_TAG_HORIZONTAL_DESCENDER = 1751413603,
  HB_OT_METRICS_TAG_HORIZONTAL_LINE_GAP = 1751934832,
  HB_OT_METRICS_TAG_HORIZONTAL_CLIPPING_ASCENT = 1751346273,
  HB_OT_METRICS_TAG_HORIZONTAL_CLIPPING_DESCENT = 1751346276,
  HB_OT_METRICS_TAG_VERTICAL_ASCENDER = 1986098019,
  HB_OT_METRICS_TAG_VERTICAL_DESCENDER = 1986294627,
  HB_OT_METRICS_TAG_VERTICAL_LINE_GAP = 1986815856,
  HB_OT_METRICS_TAG_HORIZONTAL_CARET_RISE = 1751347827,
  HB_OT_METRICS_TAG_HORIZONTAL_CARET_RUN = 1751347822,
  HB_OT_METRICS_TAG_HORIZONTAL_CARET_OFFSET = 1751347046,
  HB_OT_METRICS_TAG_VERTICAL_CARET_RISE = 1986228851,
  HB_OT_METRICS_TAG_VERTICAL_CARET_RUN = 1986228846,
  HB_OT_METRICS_TAG_VERTICAL_CARET_OFFSET = 1986228070,
  HB_OT_METRICS_TAG_X_HEIGHT = 2020108148,
  HB_OT_METRICS_TAG_CAP_HEIGHT = 1668311156,
  HB_OT_METRICS_TAG_SUBSCRIPT_EM_X_SIZE = 1935833203,
  HB_OT_METRICS_TAG_SUBSCRIPT_EM_Y_SIZE = 1935833459,
  HB_OT_METRICS_TAG_SUBSCRIPT_EM_X_OFFSET = 1935833199,
  HB_OT_METRICS_TAG_SUBSCRIPT_EM_Y_OFFSET = 1935833455,
  HB_OT_METRICS_TAG_SUPERSCRIPT_EM_X_SIZE = 1936750707,
  HB_OT_METRICS_TAG_SUPERSCRIPT_EM_Y_SIZE = 1936750963,
  HB_OT_METRICS_TAG_SUPERSCRIPT_EM_X_OFFSET = 1936750703,
  HB_OT_METRICS_TAG_SUPERSCRIPT_EM_Y_OFFSET = 1936750959,
  HB_OT_METRICS_TAG_STRIKEOUT_SIZE = 1937011315,
  HB_OT_METRICS_TAG_STRIKEOUT_OFFSET = 1937011311,
  HB_OT_METRICS_TAG_UNDERLINE_SIZE = 1970168947,
  HB_OT_METRICS_TAG_UNDERLINE_OFFSET = 1970168943,
  _HB_OT_METRICS_TAG_MAX_VALUE = 2147483647,
} hb_ot_metrics_tag_t;
const hb_ot_name_entry_t *hb_ot_name_list_names(hb_face_t *, unsigned int *);
unsigned int hb_ot_name_get_utf8(hb_face_t *, hb_ot_name_id_t, hb_language_t, unsigned int *, char *);
unsigned int hb_ot_name_get_utf16(hb_face_t *, hb_ot_name_id_t, hb_language_t, unsigned int *, uint16_t *);
unsigned int hb_ot_name_get_utf32(hb_face_t *, hb_ot_name_id_t, hb_language_t, unsigned int *, uint32_t *);
hb_bool_t hb_ot_color_has_palettes(hb_face_t *);
unsigned int hb_ot_color_palette_get_count(hb_face_t *);
hb_ot_name_id_t hb_ot_color_palette_get_name_id(hb_face_t *, unsigned int);
hb_ot_name_id_t hb_ot_color_palette_color_get_name_id(hb_face_t *, unsigned int);
hb_ot_color_palette_flags_t hb_ot_color_palette_get_flags(hb_face_t *, unsigned int);
unsigned int hb_ot_color_palette_get_colors(hb_face_t *, unsigned int, unsigned int, unsigned int *, hb_color_t *);
hb_bool_t hb_ot_color_has_layers(hb_face_t *);
unsigned int hb_ot_color_glyph_get_layers(hb_face_t *, hb_codepoint_t, unsigned int, unsigned int *, hb_ot_color_layer_t *);
hb_bool_t hb_ot_color_has_svg(hb_face_t *);
hb_blob_t *hb_ot_color_glyph_reference_svg(hb_face_t *, hb_codepoint_t);
hb_bool_t hb_ot_color_has_png(hb_face_t *);
hb_blob_t *hb_ot_color_glyph_reference_png(hb_font_t *, hb_codepoint_t);
void hb_ot_font_set_funcs(hb_font_t *);
void hb_ot_tags_from_script_and_language(hb_script_t, hb_language_t, unsigned int *, hb_tag_t *, unsigned int *, hb_tag_t *);
hb_script_t hb_ot_tag_to_script(hb_tag_t);
hb_language_t hb_ot_tag_to_language(hb_tag_t);
void hb_ot_tags_to_script_and_language(hb_tag_t, hb_tag_t, hb_script_t *, hb_language_t *);
hb_bool_t hb_ot_layout_has_glyph_classes(hb_face_t *);
hb_ot_layout_glyph_class_t hb_ot_layout_get_glyph_class(hb_face_t *, hb_codepoint_t);
void hb_ot_layout_get_glyphs_in_class(hb_face_t *, hb_ot_layout_glyph_class_t, hb_set_t *);
unsigned int hb_ot_layout_get_attach_points(hb_face_t *, hb_codepoint_t, unsigned int, unsigned int *, unsigned int *);
unsigned int hb_ot_layout_get_ligature_carets(hb_font_t *, hb_direction_t, hb_codepoint_t, unsigned int, unsigned int *, hb_position_t *);
unsigned int hb_ot_layout_table_get_script_tags(hb_face_t *, hb_tag_t, unsigned int, unsigned int *, hb_tag_t *);
hb_bool_t hb_ot_layout_table_find_script(hb_face_t *, hb_tag_t, hb_tag_t, unsigned int *);
hb_bool_t hb_ot_layout_table_select_script(hb_face_t *, hb_tag_t, unsigned int, const hb_tag_t *, unsigned int *, hb_tag_t *);
unsigned int hb_ot_layout_table_get_feature_tags(hb_face_t *, hb_tag_t, unsigned int, unsigned int *, hb_tag_t *);
unsigned int hb_ot_layout_script_get_language_tags(hb_face_t *, hb_tag_t, unsigned int, unsigned int, unsigned int *, hb_tag_t *);
hb_bool_t hb_ot_layout_script_select_language(hb_face_t *, hb_tag_t, unsigned int, unsigned int, const hb_tag_t *, unsigned int *);
hb_bool_t hb_ot_layout_language_get_required_feature_index(hb_face_t *, hb_tag_t, unsigned int, unsigned int, unsigned int *);
hb_bool_t hb_ot_layout_language_get_required_feature(hb_face_t *, hb_tag_t, unsigned int, unsigned int, unsigned int *, hb_tag_t *);
unsigned int hb_ot_layout_language_get_feature_indexes(hb_face_t *, hb_tag_t, unsigned int, unsigned int, unsigned int, unsigned int *, unsigned int *);
unsigned int hb_ot_layout_language_get_feature_tags(hb_face_t *, hb_tag_t, unsigned int, unsigned int, unsigned int, unsigned int *, hb_tag_t *);
hb_bool_t hb_ot_layout_language_find_feature(hb_face_t *, hb_tag_t, unsigned int, unsigned int, hb_tag_t, unsigned int *);
unsigned int hb_ot_layout_feature_get_lookups(hb_face_t *, hb_tag_t, unsigned int, unsigned int, unsigned int *, unsigned int *);
unsigned int hb_ot_layout_table_get_lookup_count(hb_face_t *, hb_tag_t);
void hb_ot_layout_collect_features(hb_face_t *, hb_tag_t, const hb_tag_t *, const hb_tag_t *, const hb_tag_t *, hb_set_t *);
void hb_ot_layout_collect_lookups(hb_face_t *, hb_tag_t, const hb_tag_t *, const hb_tag_t *, const hb_tag_t *, hb_set_t *);
void hb_ot_layout_lookup_collect_glyphs(hb_face_t *, hb_tag_t, unsigned int, hb_set_t *, hb_set_t *, hb_set_t *, hb_set_t *);
hb_bool_t hb_ot_layout_table_find_feature_variations(hb_face_t *, hb_tag_t, const int *, unsigned int, unsigned int *);
unsigned int hb_ot_layout_feature_with_variations_get_lookups(hb_face_t *, hb_tag_t, unsigned int, unsigned int, unsigned int, unsigned int *, unsigned int *);
hb_bool_t hb_ot_layout_has_substitution(hb_face_t *);
unsigned int hb_ot_layout_lookup_get_glyph_alternates(hb_face_t *, unsigned int, hb_codepoint_t, unsigned int, unsigned int *, hb_codepoint_t *);
hb_bool_t hb_ot_layout_lookup_would_substitute(hb_face_t *, unsigned int, const hb_codepoint_t *, unsigned int, hb_bool_t);
void hb_ot_layout_lookup_substitute_closure(hb_face_t *, unsigned int, hb_set_t *);
void hb_ot_layout_lookups_substitute_closure(hb_face_t *, const hb_set_t *, hb_set_t *);
hb_bool_t hb_ot_layout_has_positioning(hb_face_t *);
hb_bool_t hb_ot_layout_get_size_params(hb_face_t *, unsigned int *, unsigned int *, hb_ot_name_id_t *, unsigned int *, unsigned int *);
hb_bool_t hb_ot_layout_feature_get_name_ids(hb_face_t *, hb_tag_t, unsigned int, hb_ot_name_id_t *, hb_ot_name_id_t *, hb_ot_name_id_t *, unsigned int *, hb_ot_name_id_t *);
unsigned int hb_ot_layout_feature_get_characters(hb_face_t *, hb_tag_t, unsigned int, unsigned int, unsigned int *, hb_codepoint_t *);
hb_bool_t hb_ot_layout_get_baseline(hb_font_t *, hb_ot_layout_baseline_tag_t, hb_direction_t, hb_tag_t, hb_tag_t, hb_position_t *);
hb_bool_t hb_ot_math_has_data(hb_face_t *);
hb_position_t hb_ot_math_get_constant(hb_font_t *, hb_ot_math_constant_t);
hb_position_t hb_ot_math_get_glyph_italics_correction(hb_font_t *, hb_codepoint_t);
hb_position_t hb_ot_math_get_glyph_top_accent_attachment(hb_font_t *, hb_codepoint_t);
hb_bool_t hb_ot_math_is_glyph_extended_shape(hb_face_t *, hb_codepoint_t);
hb_position_t hb_ot_math_get_glyph_kerning(hb_font_t *, hb_codepoint_t, hb_ot_math_kern_t, hb_position_t);
unsigned int hb_ot_math_get_glyph_variants(hb_font_t *, hb_codepoint_t, hb_direction_t, unsigned int, unsigned int *, hb_ot_math_glyph_variant_t *);
hb_position_t hb_ot_math_get_min_connector_overlap(hb_font_t *, hb_direction_t);
unsigned int hb_ot_math_get_glyph_assembly(hb_font_t *, hb_codepoint_t, hb_direction_t, unsigned int, unsigned int *, hb_ot_math_glyph_part_t *, hb_position_t *);
unsigned int hb_ot_meta_get_entry_tags(hb_face_t *, unsigned int, unsigned int *, hb_ot_meta_tag_t *);
hb_blob_t *hb_ot_meta_reference_entry(hb_face_t *, hb_ot_meta_tag_t);
hb_bool_t hb_ot_metrics_get_position(hb_font_t *, hb_ot_metrics_tag_t, hb_position_t *);
float hb_ot_metrics_get_variation(hb_font_t *, hb_ot_metrics_tag_t);
hb_position_t hb_ot_metrics_get_x_variation(hb_font_t *, hb_ot_metrics_tag_t);
hb_position_t hb_ot_metrics_get_y_variation(hb_font_t *, hb_ot_metrics_tag_t);
void hb_ot_shape_glyphs_closure(hb_font_t *, hb_buffer_t *, const hb_feature_t *, unsigned int, hb_set_t *);
void hb_ot_shape_plan_collect_lookups(hb_shape_plan_t *, hb_tag_t, hb_set_t *);
hb_bool_t hb_ot_var_has_data(hb_face_t *);
unsigned int hb_ot_var_get_axis_count(hb_face_t *);
unsigned int hb_ot_var_get_axis_infos(hb_face_t *, unsigned int, unsigned int *, hb_ot_var_axis_info_t *);
hb_bool_t hb_ot_var_find_axis_info(hb_face_t *, hb_tag_t, hb_ot_var_axis_info_t *);
unsigned int hb_ot_var_get_named_instance_count(hb_face_t *);
hb_ot_name_id_t hb_ot_var_named_instance_get_subfamily_name_id(hb_face_t *, unsigned int);
hb_ot_name_id_t hb_ot_var_named_instance_get_postscript_name_id(hb_face_t *, unsigned int);
unsigned int hb_ot_var_named_instance_get_design_coords(hb_face_t *, unsigned int, unsigned int *, float *);
void hb_ot_var_normalize_variations(hb_face_t *, const hb_variation_t *, unsigned int, int *, unsigned int);
void hb_ot_var_normalize_coords(hb_face_t *, unsigned int, const float *, int *);
static const int HB_OT_NAME_ID_COPYRIGHT = 0;
static const int HB_OT_NAME_ID_FONT_FAMILY = 1;
static const int HB_OT_NAME_ID_FONT_SUBFAMILY = 2;
static const int HB_OT_NAME_ID_UNIQUE_ID = 3;
static const int HB_OT_NAME_ID_FULL_NAME = 4;
static const int HB_OT_NAME_ID_VERSION_STRING = 5;
static const int HB_OT_NAME_ID_POSTSCRIPT_NAME = 6;
static const int HB_OT_NAME_ID_TRADEMARK = 7;
static const int HB_OT_NAME_ID_MANUFACTURER = 8;
static const int HB_OT_NAME_ID_DESIGNER = 9;
static const int HB_OT_NAME_ID_DESCRIPTION = 10;
static const int HB_OT_NAME_ID_VENDOR_URL = 11;
static const int HB_OT_NAME_ID_DESIGNER_URL = 12;
static const int HB_OT_NAME_ID_LICENSE = 13;
static const int HB_OT_NAME_ID_LICENSE_URL = 14;
static const int HB_OT_NAME_ID_TYPOGRAPHIC_FAMILY = 16;
static const int HB_OT_NAME_ID_TYPOGRAPHIC_SUBFAMILY = 17;
static const int HB_OT_NAME_ID_MAC_FULL_NAME = 18;
static const int HB_OT_NAME_ID_SAMPLE_TEXT = 19;
static const int HB_OT_NAME_ID_CID_FINDFONT_NAME = 20;
static const int HB_OT_NAME_ID_WWS_FAMILY = 21;
static const int HB_OT_NAME_ID_WWS_SUBFAMILY = 22;
static const int HB_OT_NAME_ID_LIGHT_BACKGROUND = 23;
static const int HB_OT_NAME_ID_DARK_BACKGROUND = 24;
static const int HB_OT_NAME_ID_VARIATIONS_PS_PREFIX = 25;
hb_bool_t hb_buffer_has_positions(hb_buffer_t *);
unsigned int hb_buffer_serialize(hb_buffer_t *, unsigned int, unsigned int, char *, unsigned int, unsigned int *, hb_font_t *, hb_buffer_serialize_format_t, hb_buffer_serialize_flags_t);
unsigned int hb_buffer_serialize_unicode(hb_buffer_t *, unsigned int, unsigned int, char *, unsigned int, unsigned int *, hb_buffer_serialize_format_t, hb_buffer_serialize_flags_t);
hb_bool_t hb_buffer_deserialize_unicode(hb_buffer_t *, const char *, int, const char **, hb_buffer_serialize_format_t);
hb_blob_t *hb_blob_create_or_fail(const char *, unsigned int, hb_memory_mode_t, void *, hb_destroy_func_t);
hb_blob_t *hb_blob_create_from_file_or_fail(const char *);
hb_set_t *hb_set_copy(const hb_set_t *);
typedef enum {
  HB_STYLE_TAG_ITALIC = 1769234796,
  HB_STYLE_TAG_OPTICAL_SIZE = 1869640570,
  HB_STYLE_TAG_SLANT_ANGLE = 1936486004,
  HB_STYLE_TAG_SLANT_RATIO = 1399615092,
  HB_STYLE_TAG_WIDTH = 2003072104,
  HB_STYLE_TAG_WEIGHT = 2003265652,
  _HB_STYLE_TAG_MAX_VALUE = 2147483647,
} hb_style_tag_t;
float hb_style_get_value(hb_font_t *, hb_style_tag_t);
void hb_buffer_set_not_found_glyph(hb_buffer_t *, hb_codepoint_t);
hb_codepoint_t hb_buffer_get_not_found_glyph(const hb_buffer_t *);
void hb_segment_properties_overlay(hb_segment_properties_t *, const hb_segment_properties_t *);
hb_buffer_t *hb_buffer_create_similar(const hb_buffer_t *);
void hb_font_set_synthetic_slant(hb_font_t *, float);
float hb_font_get_synthetic_slant(hb_font_t *);
const float *hb_font_get_var_coords_design(hb_font_t *, unsigned int *);
static const int HB_OT_TAG_MATH_SCRIPT = 1835103336;
typedef struct {
  hb_position_t max_correction_height;
  hb_position_t kern_value;
} hb_ot_math_kern_entry_t;
unsigned int hb_ot_math_get_glyph_kernings(hb_font_t *, hb_codepoint_t, hb_ot_math_kern_t, unsigned int, unsigned int *, hb_ot_math_kern_entry_t *);
union _hb_var_num_t {
  float f;
  uint32_t u32;
  int32_t i32;
  uint16_t u16[2];
  int16_t i16[2];
  uint8_t u8[4];
  int8_t i8[4];
};
typedef union _hb_var_num_t hb_var_num_t;
struct hb_draw_state_t {
  hb_bool_t path_open;
  float path_start_x;
  float path_start_y;
  float current_x;
  float current_y;
  hb_var_num_t reserved1;
  hb_var_num_t reserved2;
  hb_var_num_t reserved3;
  hb_var_num_t reserved4;
  hb_var_num_t reserved5;
  hb_var_num_t reserved6;
  hb_var_num_t reserved7;
};
typedef struct hb_draw_state_t hb_draw_state_t;
typedef struct hb_draw_funcs_t hb_draw_funcs_t;
hb_draw_funcs_t *hb_draw_funcs_create(void);
hb_draw_funcs_t *hb_draw_funcs_reference(hb_draw_funcs_t *);
void hb_draw_funcs_destroy(hb_draw_funcs_t *);
hb_bool_t hb_draw_funcs_is_immutable(hb_draw_funcs_t *);
void hb_draw_funcs_make_immutable(hb_draw_funcs_t *);
typedef void (*hb_draw_move_to_func_t)(hb_draw_funcs_t *, void *, hb_draw_state_t *, float, float, void *);
void hb_draw_funcs_set_move_to_func(hb_draw_funcs_t *, hb_draw_move_to_func_t, void *, hb_destroy_func_t);
typedef void (*hb_draw_line_to_func_t)(hb_draw_funcs_t *, void *, hb_draw_state_t *, float, float, void *);
void hb_draw_funcs_set_line_to_func(hb_draw_funcs_t *, hb_draw_line_to_func_t, void *, hb_destroy_func_t);
typedef void (*hb_draw_quadratic_to_func_t)(hb_draw_funcs_t *, void *, hb_draw_state_t *, float, float, float, float, void *);
void hb_draw_funcs_set_quadratic_to_func(hb_draw_funcs_t *, hb_draw_quadratic_to_func_t, void *, hb_destroy_func_t);
typedef void (*hb_draw_cubic_to_func_t)(hb_draw_funcs_t *, void *, hb_draw_state_t *, float, float, float, float, float, float, void *);
void hb_draw_funcs_set_cubic_to_func(hb_draw_funcs_t *, hb_draw_cubic_to_func_t, void *, hb_destroy_func_t);
typedef void (*hb_draw_close_path_func_t)(hb_draw_funcs_t *, void *, hb_draw_state_t *, void *);
void hb_draw_funcs_set_close_path_func(hb_draw_funcs_t *, hb_draw_close_path_func_t, void *, hb_destroy_func_t);
void hb_draw_move_to(hb_draw_funcs_t *, void *, hb_draw_state_t *, float, float);
void hb_draw_line_to(hb_draw_funcs_t *, void *, hb_draw_state_t *, float, float);
void hb_draw_quadratic_to(hb_draw_funcs_t *, void *, hb_draw_state_t *, float, float, float, float);
void hb_draw_cubic_to(hb_draw_funcs_t *, void *, hb_draw_state_t *, float, float, float, float, float, float);
void hb_draw_close_path(hb_draw_funcs_t *, void *, hb_draw_state_t *);
typedef void (*hb_font_get_glyph_shape_func_t)(hb_font_t *, void *, hb_codepoint_t, hb_draw_funcs_t *, void *, void *);
void hb_font_funcs_set_glyph_shape_func(hb_font_funcs_t *, hb_font_get_glyph_shape_func_t, void *, hb_destroy_func_t);
void hb_font_get_glyph_shape(hb_font_t *, hb_codepoint_t, hb_draw_funcs_t *, void *);
hb_ot_layout_baseline_tag_t hb_ot_layout_get_horizontal_baseline_tag_for_script(hb_script_t);
void hb_ot_layout_get_baseline_with_fallback(hb_font_t *, hb_ot_layout_baseline_tag_t, hb_direction_t, hb_tag_t, hb_tag_t, hb_position_t *);
void hb_ot_metrics_get_position_with_fallback(hb_font_t *, hb_ot_metrics_tag_t, hb_position_t *);
void hb_set_add_sorted_array(hb_set_t *, const hb_codepoint_t *, unsigned int);
unsigned int hb_set_next_many(const hb_set_t *, hb_codepoint_t, hb_codepoint_t *, unsigned int);
hb_bool_t hb_map_is_equal(const hb_map_t *, const hb_map_t *);
void hb_font_changed(hb_font_t *);
unsigned int hb_font_get_serial(hb_font_t *);
hb_bool_t hb_ft_hb_font_changed(hb_font_t *);
unsigned int hb_set_hash(const hb_set_t *);
hb_map_t *hb_map_copy(const hb_map_t *);
unsigned int hb_map_hash(const hb_map_t *);
hb_bool_t hb_language_matches(hb_language_t, hb_language_t);
]]
