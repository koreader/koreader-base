-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
typedef uint32_t hb_codepoint_t;
union _hb_var_int_t {
  uint32_t u32;
  int32_t i32;
  uint16_t u16[2];
  int16_t i16[2];
  uint8_t u8[4];
  int8_t i8[4];
};
typedef union _hb_var_int_t hb_var_int_t;
typedef struct hb_face_t hb_face_t;
typedef const struct hb_language_impl_t *hb_language_t;
typedef unsigned hb_ot_name_id_t;
struct hb_ot_name_entry_t {
  hb_ot_name_id_t name_id;
  hb_var_int_t var;
  hb_language_t language;
};
typedef struct hb_ot_name_entry_t hb_ot_name_entry_t;
typedef struct hb_set_t hb_set_t;
const hb_ot_name_entry_t *hb_ot_name_list_names(hb_face_t *face, unsigned *num_entries);
const char *hb_language_to_string(hb_language_t language);
unsigned hb_ot_name_get_utf8(hb_face_t *face, hb_ot_name_id_t name_id, hb_language_t language, unsigned *text_size, char *text);
hb_set_t *hb_set_create(void);
void hb_face_collect_unicodes(hb_face_t *face, hb_set_t *out);
void hb_set_set(hb_set_t *set, const hb_set_t *other);
void hb_set_intersect(hb_set_t *set, const hb_set_t *other);
unsigned hb_set_get_population(const hb_set_t *set);
void hb_set_destroy(hb_set_t *set);
void hb_face_destroy(hb_face_t *face);
void hb_set_add_range(hb_set_t *set, hb_codepoint_t first, hb_codepoint_t last);
typedef struct hb_blob_t hb_blob_t;
typedef enum {
  HB_MEMORY_MODE_DUPLICATE,
  HB_MEMORY_MODE_READONLY,
  HB_MEMORY_MODE_WRITABLE,
  HB_MEMORY_MODE_READONLY_MAY_MAKE_WRITABLE,
} hb_memory_mode_t;
typedef void (*hb_destroy_func_t)(void *user_data);
static const unsigned HB_OT_NAME_ID_FONT_FAMILY = 1;
static const unsigned HB_OT_NAME_ID_FONT_SUBFAMILY = 2;
static const unsigned HB_OT_NAME_ID_FULL_NAME = 4;
typedef struct FT_FaceRec_ *FT_Face;
hb_blob_t *hb_blob_create(const char *data, unsigned length, hb_memory_mode_t mode, void *user_data, hb_destroy_func_t destroy);
hb_face_t *hb_face_create(hb_blob_t *blob, unsigned index);
void hb_blob_destroy(hb_blob_t *blob);
unsigned hb_face_get_glyph_count(const hb_face_t *face);
hb_face_t *hb_ft_face_create_referenced(FT_Face ft_face);
]]
