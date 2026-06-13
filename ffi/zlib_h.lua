-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
typedef unsigned char Byte;
typedef Byte Bytef;
typedef unsigned long uLong;
typedef uLong uLongf;
typedef unsigned uInt;
uLong compressBound(uLong);
int compress2(Bytef *, uLongf *, const Bytef *, uLong, int);
uLong crc32(uLong, const Bytef *, uInt);
int uncompress(Bytef *, uLongf *, const Bytef *, uLong);
]]
