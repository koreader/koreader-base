local ffi = require("ffi")
ffi.cdef[[
char *setlocale(int, const char *) __attribute__((__nothrow__, __leaf__));
char *bindtextdomain(const char *, const char *) __attribute__((__nothrow__, __leaf__));
char *textdomain(const char *) __attribute__((__nothrow__, __leaf__));
char *gettext(const char *) __attribute__((__nothrow__, __leaf__));
int setenv(const char *, const char *, int) __attribute__((__nothrow__, __leaf__));
static const int LC_ALL = 6;
]]
