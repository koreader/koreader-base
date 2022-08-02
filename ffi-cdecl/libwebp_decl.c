#include <webp/decode.h>
#include <webp/demux.h>
#include <webp/types.h>

#include "ffi-cdecl.h"

cdecl_const(WEBP_DEMUX_ABI_VERSION)
cdecl_enum(WEBP_CSP_MODE)

cdecl_struct(WebPData)
cdecl_type(WebPData)

cdecl_struct(WebPAnimInfo)
cdecl_type(WebPAnimInfo)

cdecl_struct(WebPAnimDecoderOptions)
cdecl_type(WebPAnimDecoderOptions)
// cdecl_func(WebPAnimDecoderOptionsInit)      // inline in demux.h
cdecl_func(WebPAnimDecoderOptionsInitInternal) // we need to use this one

cdecl_struct(WebPAnimDecoder)
cdecl_type(WebPAnimDecoder)
// cdecl_func(WebPAnimDecoderNew)      // inline in demux.h
cdecl_func(WebPAnimDecoderNewInternal) // we need to use this one
cdecl_func(WebPAnimDecoderGetInfo)
cdecl_func(WebPAnimDecoderGetNext)
cdecl_func(WebPAnimDecoderReset)
cdecl_func(WebPAnimDecoderDelete)
