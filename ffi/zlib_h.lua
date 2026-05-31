-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
typedef unsigned char Byte;
typedef Byte Bytef;
typedef unsigned long uLong;
typedef uLong uLongf;
typedef unsigned uInt;
uLong compressBound(uLong sourceLen);
int compress2(Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen, int level);
uLong crc32(uLong crc, const Bytef *buf, uInt len);
int uncompress(Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen);
]]
