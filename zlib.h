#include <zlib.h>

// Symbol visibility
#define DLL_PUBLIC __attribute__((visibility("default")))
#define DLL_LOCAL  __attribute__((visibility("hidden")))

DLL_PUBLIC int uncompress_raw(Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen);