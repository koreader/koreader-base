// standard Linux framebuffer headers
#include <linux/fb.h>

#include <linux/ioctl.h>

#include "ffi-cdecl.h"

cdecl_const(FBIOGET_FSCREENINFO)
cdecl_const(FBIOGET_VSCREENINFO)
cdecl_const(FBIOPUT_VSCREENINFO)

cdecl_const(FB_TYPE_PACKED_PIXELS)

cdecl_struct(fb_bitfield)
cdecl_struct(fb_fix_screeninfo)
cdecl_struct(fb_var_screeninfo)
