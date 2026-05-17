#include <tree_sitter/api.h>
#include <tree_sitter/tree-sitter-c.h>

#include "ffi-cdecl.h"

cdecl_enum(TSQueryError);
cdecl_type(TSQueryError);

cdecl_type(TSFieldId);
cdecl_type(TSLanguage);
cdecl_type(TSParser);
cdecl_type(TSQuery);
cdecl_type(TSQueryCursor);
cdecl_type(TSSymbol);
cdecl_type(TSTree);

cdecl_type(TSPoint);
cdecl_struct(TSPoint);

cdecl_type(TSInputEdit);
cdecl_struct(TSInputEdit);

cdecl_type(TSNode);
cdecl_struct(TSNode);

cdecl_type(TSQueryCapture);
cdecl_struct(TSQueryCapture);
cdecl_type(TSQueryMatch);
cdecl_struct(TSQueryMatch);

cdecl_func(ts_language_delete);
cdecl_func(ts_language_field_count);
cdecl_func(ts_language_field_id_for_name);
cdecl_func(ts_language_field_name_for_id);
cdecl_func(ts_language_symbol_for_name);
cdecl_func(ts_language_symbol_name);

cdecl_func(ts_node_child);
cdecl_func(ts_node_child_by_field_id);
cdecl_func(ts_node_child_count);
cdecl_func(ts_node_end_byte);
cdecl_func(ts_node_end_point);
cdecl_func(ts_node_is_named);
cdecl_func(ts_node_is_null);
cdecl_func(ts_node_named_child);
cdecl_func(ts_node_named_child_count);
cdecl_func(ts_node_next_sibling);
cdecl_func(ts_node_parent);
cdecl_func(ts_node_start_byte);
cdecl_func(ts_node_start_point);
cdecl_func(ts_node_string);
cdecl_func(ts_node_symbol);
cdecl_func(ts_node_type);

cdecl_func(ts_parser_delete);
cdecl_func(ts_parser_new);
cdecl_func(ts_parser_parse_string);
cdecl_func(ts_parser_reset);
cdecl_func(ts_parser_set_language);

cdecl_func(ts_query_cursor_delete);
cdecl_func(ts_query_cursor_exec);
cdecl_func(ts_query_cursor_new);
cdecl_func(ts_query_cursor_next_match);
cdecl_func(ts_query_cursor_set_max_start_depth);
cdecl_func(ts_query_delete);
cdecl_func(ts_query_new);

cdecl_func(ts_tree_delete);
cdecl_func(ts_tree_edit);
cdecl_func(ts_tree_root_node);

/* C grammar support */
cdecl_func(tree_sitter_c);
