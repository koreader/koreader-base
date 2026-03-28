#ifndef MINICONV_CONFIG_H
#define MINICONV_CONFIG_H

#include <stddef.h>
#include <stdint.h>

#if defined(__BYTE_ORDER__) && defined(__ORDER_BIG_ENDIAN__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#  define __BIG_ENDIAN__
#endif

#define MINICONV_BE_ICONV
#define MINICONV_INLINE  static inline
#define MINICONV_PUBLIC  __attribute__((visibility("default")))

typedef uint16_t miniconv_uint16_t;
typedef uint32_t miniconv_uint32_t;

#endif

// vim: ft=c
