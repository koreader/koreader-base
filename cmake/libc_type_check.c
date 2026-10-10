#include <features.h>
#if defined(__UCLIBC__)
#  define LIBC_TYPE  uClibc
#elif defined(__dietlibc__)
#  define LIBC_TYPE  dietlibc
#elif defined(__GLIBC__)
#  define LIBC_TYPE  GNU
#elif defined(__LLVM_LIBC__)
#  define LIBC_TYPE  LLVM
#elif defined(__mlibc__)
#  define LIBC_TYPE  mlibc
#else
#  include <stdarg.h>
#  ifdef __DEFINED_va_list
#    define LIBC_TYPE  musl
#  endif
#endif

libc_type=LIBC_TYPE
