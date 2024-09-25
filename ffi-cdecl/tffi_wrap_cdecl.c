#include "http-parser/http_parser.h"
#include "turbo_ffi_wrap.h"

#include "ffi-cdecl.h"

cdecl_func(http_body_is_final)
cdecl_func(http_errno_description)
cdecl_func(http_errno_name)
cdecl_func(http_method_str)
cdecl_func(http_parser_execute)
cdecl_func(http_parser_init)
cdecl_func(http_parser_parse_url)
cdecl_func(http_parser_parse_url)
cdecl_func(http_parser_pause)
cdecl_func(http_parser_settings_init)
cdecl_func(http_parser_url_init)
cdecl_func(http_parser_version)
cdecl_func(http_should_keep_alive)
cdecl_func(turbo_bswap_u64)
cdecl_func(turbo_parser_check)
cdecl_func(turbo_parser_wrapper_exit)
cdecl_func(turbo_parser_wrapper_init)
cdecl_func(turbo_websocket_mask)
cdecl_func(url_field)
cdecl_func(url_field_is_set)
cdecl_func(validate_hostname)
