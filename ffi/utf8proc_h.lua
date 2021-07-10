local ffi = require("ffi")

ffi.cdef[[
typedef ptrdiff_t utf8proc_ssize_t;

int32_t utf8proc_tolower(int32_t c);

utf8proc_ssize_t utf8proc_iterate(const uint8_t *str, utf8proc_ssize_t strlen, int32_t *codepoint_ref);

utf8proc_ssize_t utf8proc_encode_char(int32_t codepoint, uint8_t *dst);

uint8_t* utf8proc_NFKC_Casefold(const uint8_t * str);
]]
