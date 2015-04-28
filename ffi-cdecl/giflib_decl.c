#include <gif_lib.h>

#include "ffi-cdecl.h"

cdecl_const(GIF_OK)
cdecl_const(GIF_ERROR)

cdecl_type(GifWord)
cdecl_type(GifByteType)

cdecl_type(GifColorType)
cdecl_struct(GifColorType)

cdecl_type(ColorMapObject)
cdecl_struct(ColorMapObject)

cdecl_type(GifImageDesc)
cdecl_struct(GifImageDesc)

cdecl_type(SavedImage)
cdecl_struct(SavedImage)

cdecl_type(GifFileType)
cdecl_struct(GifFileType)

cdecl_func(DGifOpenFileName)
cdecl_func(DGifOpenFileHandle)
cdecl_func(DGifCloseFile)

cdecl_func(DGifSlurp)

cdecl_func(GifErrorString)
