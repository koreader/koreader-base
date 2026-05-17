-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
enum TSQueryError {
  TSQueryErrorNone = 0,
  TSQueryErrorSyntax,
  TSQueryErrorNodeType,
  TSQueryErrorField,
  TSQueryErrorCapture,
  TSQueryErrorStructure,
  TSQueryErrorLanguage,
};
typedef enum TSQueryError TSQueryError;
typedef uint16_t TSFieldId;
typedef struct TSLanguage TSLanguage;
typedef struct TSParser TSParser;
typedef struct TSQuery TSQuery;
typedef struct TSQueryCursor TSQueryCursor;
typedef uint16_t TSSymbol;
typedef struct TSTree TSTree;
typedef struct TSPoint TSPoint;
struct TSPoint {
  uint32_t row;
  uint32_t column;
};
typedef struct TSInputEdit TSInputEdit;
struct TSInputEdit {
  uint32_t start_byte;
  uint32_t old_end_byte;
  uint32_t new_end_byte;
  TSPoint start_point;
  TSPoint old_end_point;
  TSPoint new_end_point;
};
typedef struct TSNode TSNode;
struct TSNode {
  uint32_t context[4];
  const void *id;
  const TSTree *tree;
};
typedef struct TSQueryCapture TSQueryCapture;
struct TSQueryCapture {
  TSNode node;
  uint32_t index;
};
typedef struct TSQueryMatch TSQueryMatch;
struct TSQueryMatch {
  uint32_t id;
  uint16_t pattern_index;
  uint16_t capture_count;
  const TSQueryCapture *captures;
};
void ts_language_delete(const TSLanguage *self);
uint32_t ts_language_field_count(const TSLanguage *self);
TSFieldId ts_language_field_id_for_name(const TSLanguage *self, const char *name, uint32_t name_length);
const char *ts_language_field_name_for_id(const TSLanguage *self, TSFieldId id);
TSSymbol ts_language_symbol_for_name(const TSLanguage *self, const char *string, uint32_t length, bool is_named);
const char *ts_language_symbol_name(const TSLanguage *self, TSSymbol symbol);
TSNode ts_node_child(TSNode self, uint32_t child_index);
TSNode ts_node_child_by_field_id(TSNode self, TSFieldId field_id);
uint32_t ts_node_child_count(TSNode self);
uint32_t ts_node_end_byte(TSNode self);
TSPoint ts_node_end_point(TSNode self);
bool ts_node_is_named(TSNode self);
bool ts_node_is_null(TSNode self);
TSNode ts_node_named_child(TSNode self, uint32_t child_index);
uint32_t ts_node_named_child_count(TSNode self);
TSNode ts_node_next_sibling(TSNode self);
TSNode ts_node_parent(TSNode self);
uint32_t ts_node_start_byte(TSNode self);
TSPoint ts_node_start_point(TSNode self);
char *ts_node_string(TSNode self);
TSSymbol ts_node_symbol(TSNode self);
const char *ts_node_type(TSNode self);
void ts_parser_delete(TSParser *self);
TSParser *ts_parser_new(void);
TSTree *ts_parser_parse_string(TSParser *self, const TSTree *old_tree, const char *string, uint32_t length);
void ts_parser_reset(TSParser *self);
bool ts_parser_set_language(TSParser *self, const TSLanguage *language);
void ts_query_cursor_delete(TSQueryCursor *self);
void ts_query_cursor_exec(TSQueryCursor *self, const TSQuery *query, TSNode node);
TSQueryCursor *ts_query_cursor_new(void);
bool ts_query_cursor_next_match(TSQueryCursor *self, TSQueryMatch *match);
void ts_query_cursor_set_max_start_depth(TSQueryCursor *self, uint32_t max_start_depth);
void ts_query_delete(TSQuery *self);
TSQuery *ts_query_new(const TSLanguage *language, const char *source, uint32_t source_len, uint32_t *error_offset, TSQueryError *error_type);
void ts_tree_delete(TSTree *self);
void ts_tree_edit(TSTree *self, const TSInputEdit *edit);
TSNode ts_tree_root_node(const TSTree *self);
const TSLanguage *tree_sitter_c(void);
]]
