local ffi = require("ffi")

ffi.cdef[[
long unsigned int compressBound(long unsigned int);
int compress2(unsigned char *, long unsigned int *, const unsigned char *, long unsigned int, int);
int uncompress(unsigned char *, long unsigned int *, const unsigned char *, long unsigned int);
]]
