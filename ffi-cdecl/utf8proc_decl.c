#include <utf8proc.h>

#include "ffi-cdecl.h"

cdecl_c99_type(utf8proc_uint8_t, uint8_t);
cdecl_c99_type(utf8proc_int32_t, int32_t);
cdecl_c99_type(utf8proc_ssize_t, ssize_t);

cdecl_func(utf8proc_encode_char);
cdecl_func(utf8proc_iterate);
cdecl_func(utf8proc_NFC);
cdecl_func(utf8proc_NFKC_Casefold);
cdecl_func(utf8proc_tolower);
cdecl_func(utf8proc_toupper);
