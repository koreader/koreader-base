-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
typedef uint8_t utf8proc_uint8_t;
typedef int32_t utf8proc_int32_t;
typedef ptrdiff_t utf8proc_ssize_t;
utf8proc_ssize_t utf8proc_encode_char(utf8proc_int32_t codepoint, utf8proc_uint8_t *dst);
utf8proc_ssize_t utf8proc_iterate(const utf8proc_uint8_t *str, utf8proc_ssize_t strlen, utf8proc_int32_t *codepoint_ref);
utf8proc_uint8_t *utf8proc_NFC(const utf8proc_uint8_t *str);
utf8proc_uint8_t *utf8proc_NFKC_Casefold(const utf8proc_uint8_t *str);
utf8proc_int32_t utf8proc_tolower(utf8proc_int32_t c);
utf8proc_int32_t utf8proc_toupper(utf8proc_int32_t c);
]]
