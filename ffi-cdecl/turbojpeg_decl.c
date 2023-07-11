#include <turbojpeg.h>

#include "ffi-cdecl.h"

cdecl_enum(TJINIT)
cdecl_enum(TJSAMP)
cdecl_enum(TJPF)
cdecl_enum(TJPARAM)

cdecl_type(tjhandle)

cdecl_func(tj3Init)
cdecl_func(tj3Set)
cdecl_func(tj3Get)
cdecl_func(tj3Compress8)
cdecl_func(tj3DecompressHeader)
cdecl_func(tj3Decompress8)
cdecl_func(tj3Destroy)
cdecl_func(tj3SaveImage8)
cdecl_func(tj3Free)
