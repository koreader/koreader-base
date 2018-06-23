#include <pthread.h>

#include "ffi-cdecl.h"

cdecl_type(pthread_t)

// NOTE: This is... annoying. The array's size depends on the arch (c.f., __SIZEOF_PTHREAD_ATTR_T).
//       We dispatch loading the right one with a bit of trickery in ffi/pthread_h.lua
//       c.f., https://github.com/koreader/koreader/pull/4016#issuecomment-399692355 for the full story
//cdecl_const(__SIZEOF_PTHREAD_ATTR_T)

//cdecl_union(pthread_attr_t)
cdecl_type(pthread_attr_t)

cdecl_func(pthread_attr_init)
cdecl_func(pthread_attr_setdetachstate)
cdecl_func(pthread_attr_destroy)

cdecl_const(PTHREAD_CREATE_DETACHED)

cdecl_func(pthread_create)

