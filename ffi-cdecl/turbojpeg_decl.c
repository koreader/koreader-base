#include <turbojpeg.h>

#include "ffi-cdecl.h"
#include "ffi-cdecl-luajit.h"

cdecl_type(tjhandle)

cdecl_enum(TJPF)

cdecl_func(tjDestroy)
cdecl_func(tjInitDecompress)
cdecl_func(tjDecompressHeader2)
cdecl_func(tjDecompress2)
cdecl_func(tjDecompressToYUV)
