#include <pthread.h>

#include "ffi-cdecl.h"

cdecl_type(pthread_t)

cdecl_type(pthread_attr_t)
cdecl_union(pthread_attr_t)

cdecl_func(pthread_attr_init)
cdecl_func(pthread_attr_setdetachstate)
cdecl_func(pthread_attr_destroy)

cdecl_const(PTHREAD_CREATE_DETACHED)

cdecl_func(pthread_create)

