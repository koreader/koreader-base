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

cdecl_type(ExtensionBlock)
cdecl_struct(ExtensionBlock)

cdecl_type(GraphicsControlBlock)
cdecl_struct(GraphicsControlBlock)

cdecl_type(SavedImage)
cdecl_struct(SavedImage)

cdecl_type(GifFileType)
cdecl_struct(GifFileType)

cdecl_func(DGifOpenFileName)
cdecl_func(DGifOpenFileHandle)
cdecl_func(DGifCloseFile)

cdecl_func(DGifSlurp)

cdecl_func(GifErrorString)

cdecl_func(DGifSavedExtensionToGCB)
cdecl_const(DISPOSAL_UNSPECIFIED)
cdecl_const(DISPOSE_DO_NOT)
cdecl_const(DISPOSE_BACKGROUND)
cdecl_const(DISPOSE_PREVIOUS)
cdecl_const(NO_TRANSPARENT_COLOR)

cdecl_type(InputFunc)
cdecl_func(DGifOpen)
