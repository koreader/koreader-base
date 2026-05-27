#include <avif/avif.h>

cdecl_const(AVIF_VERSION)
cdecl_type(avifBool)
cdecl_enum(avifResult)
cdecl_type(avifResult)

cdecl_struct(avifROData)
cdecl_type(avifROData)
cdecl_struct(avifRWData)
cdecl_type(avifRWData)

cdecl_enum(avifPixelFormat)
cdecl_type(avifPixelFormat)
cdecl_enum(avifRange)
cdecl_type(avifRange)

cdecl_struct(avifDiagnostics)
cdecl_type(avifDiagnostics)

cdecl_struct(avifImage)
cdecl_type(avifImage)
cdecl_struct(avifRGBImage)
cdecl_type(avifRGBImage)

cdecl_struct(avifDecoder)
cdecl_type(avifDecoder)
cdecl_struct(avifIO)
cdecl_type(avifIO)

cdecl_func(avifDecoderCreate)
cdecl_func(avifDecoderDestroy)
cdecl_func(avifDecoderParse)
cdecl_func(avifDecoderNextImage)
cdecl_func(avifDecoderSetIOMemory)
cdecl_func(avifDecoderSetIOFile)
cdecl_func(avifImageYUVToRGB)
cdecl_func(avifRGBImageSetDefaults)
cdecl_func(avifRGBImageAllocatePixels)
cdecl_func(avifRGBImageFreePixels)
cdecl_func(avifDecoderReadMemory)
cdecl_func(avifDecoderReadFile)
cdecl_func(avifDecoderRead)
cdecl_func(avifResultToString)
