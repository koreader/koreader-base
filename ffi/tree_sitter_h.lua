-- Automatically generated with ffi-cdecl.

local ffi = require("ffi")

ffi.cdef[[
enum TSQueryError {
  TSQueryErrorNone = 0,
  TSQueryErrorSyntax = 1,
  TSQueryErrorNodeType = 2,
  TSQueryErrorField = 3,
  TSQueryErrorCapture = 4,
  TSQueryErrorStructure = 5,
  TSQueryErrorLanguage = 6,
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
void ts_language_delete(const TSLanguage *);
uint32_t ts_language_field_count(const TSLanguage *);
TSFieldId ts_language_field_id_for_name(const TSLanguage *, const char *, uint32_t);
const char *ts_language_field_name_for_id(const TSLanguage *, TSFieldId);
TSSymbol ts_language_symbol_for_name(const TSLanguage *, const char *, uint32_t, bool);
const char *ts_language_symbol_name(const TSLanguage *, TSSymbol);
TSNode ts_node_child(TSNode, uint32_t);
TSNode ts_node_child_by_field_id(TSNode, TSFieldId);
uint32_t ts_node_child_count(TSNode);
uint32_t ts_node_end_byte(TSNode);
TSPoint ts_node_end_point(TSNode);
bool ts_node_is_named(TSNode);
bool ts_node_is_null(TSNode);
TSNode ts_node_named_child(TSNode, uint32_t);
uint32_t ts_node_named_child_count(TSNode);
TSNode ts_node_next_sibling(TSNode);
TSNode ts_node_parent(TSNode);
uint32_t ts_node_start_byte(TSNode);
TSPoint ts_node_start_point(TSNode);
char *ts_node_string(TSNode);
TSSymbol ts_node_symbol(TSNode);
const char *ts_node_type(TSNode);
void ts_parser_delete(TSParser *);
TSParser *ts_parser_new(void);
TSTree *ts_parser_parse_string(TSParser *, const TSTree *, const char *, uint32_t);
void ts_parser_reset(TSParser *);
bool ts_parser_set_language(TSParser *, const TSLanguage *);
void ts_query_cursor_delete(TSQueryCursor *);
void ts_query_cursor_exec(TSQueryCursor *, const TSQuery *, TSNode);
TSQueryCursor *ts_query_cursor_new(void);
bool ts_query_cursor_next_match(TSQueryCursor *, TSQueryMatch *);
void ts_query_cursor_set_max_start_depth(TSQueryCursor *, uint32_t);
void ts_query_delete(TSQuery *);
TSQuery *ts_query_new(const TSLanguage *, const char *, uint32_t, uint32_t *, TSQueryError *);
void ts_tree_delete(TSTree *);
void ts_tree_edit(TSTree *, const TSInputEdit *);
TSNode ts_tree_root_node(const TSTree *);
const TSLanguage *tree_sitter_c(void);
]]
