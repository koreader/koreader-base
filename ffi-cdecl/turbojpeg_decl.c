#include <turbojpeg.h>

#include "ffi-cdecl.h"

cdecl_type(tjhandle)

cdecl_enum(TJPF)

cdecl_func(tjDestroy)
cdecl_func(tjInitDecompress)
cdecl_func(tjDecompressHeader2)
cdecl_func(tjDecompressHeader3)
cdecl_func(tjDecompress2)
cdecl_func(tjDecompressToYUV)
cdecl_func(tjInitCompress)
cdecl_func(tjFree)
cdecl_func(tjCompress2)
cdecl_func(tjSaveImage)
