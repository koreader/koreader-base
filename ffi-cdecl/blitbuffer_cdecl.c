#include "blitbuffer.h"
#include "ffi-cdecl.h"

/* cdecl_type(Color4L) */
/* cdecl_struct(Color4L) */
/* cdecl_type(Color4U) */
/* cdecl_struct(Color4U) */
cdecl_type(Color8)
cdecl_struct(Color8)
cdecl_type(Color8A)
cdecl_struct(Color8A)
cdecl_type(ColorRGB16)
cdecl_struct(ColorRGB16)
cdecl_type(ColorRGB24)
cdecl_struct(ColorRGB24)
cdecl_type(ColorRGB32)
cdecl_struct(ColorRGB32)

cdecl_type(BlitBuffer)
cdecl_struct(BlitBuffer)
/* cdecl_type(BlitBuffer4) */
/* cdecl_struct(BlitBuffer4) */
cdecl_type(BlitBuffer8)
cdecl_struct(BlitBuffer8)
cdecl_type(BlitBuffer8A)
cdecl_struct(BlitBuffer8A)
cdecl_type(BlitBufferRGB16)
cdecl_struct(BlitBufferRGB16)
cdecl_type(BlitBufferRGB24)
cdecl_struct(BlitBufferRGB24)
cdecl_type(BlitBufferRGB32)
cdecl_struct(BlitBufferRGB32)

cdecl_func(BB_add_blit_from)
cdecl_func(BB_alpha_blit_from)
cdecl_func(BB_blend_rect)
cdecl_func(BB_blend_RGB32_over_rect)
cdecl_func(BB_blend_RGB_multiply_rect)
cdecl_func(BB_blend_RGB32_multiply_rect)
cdecl_func(BB_blit_to)
cdecl_func(BB_color_blit_from)
cdecl_func(BB_color_blit_from_RGB32)
cdecl_func(BB_dither_alpha_blit_from)
cdecl_func(BB_dither_blit_to)
cdecl_func(BB_dither_pmulalpha_blit_from)
cdecl_func(BB_fill)
cdecl_func(BB_fill_rect)
cdecl_func(BB_fill_rect_RGB32)
cdecl_func(BB_hatch_rect)
cdecl_func(BB_invert_blit_from)
cdecl_func(BB_invert_rect)
cdecl_func(BB_paint_rounded_corner)
cdecl_func(BB_pmulalpha_blit_from)
