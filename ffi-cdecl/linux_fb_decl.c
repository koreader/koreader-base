// standard Linux framebuffer headers
#include <linux/fb.h>

#include <linux/ioctl.h>
// specialized eink framebuffer headers
typedef unsigned int u_int;
typedef unsigned long u_long;
#include "include/einkfb.h"
typedef unsigned int uint;
#include "include/mxcfb.h"

#include "cdecl.h"

cdecl_const(FBIOGET_FSCREENINFO)
cdecl_const(FBIOGET_VSCREENINFO)

cdecl_const(FB_TYPE_PACKED_PIXELS)

cdecl_struct(fb_bitfield)
cdecl_struct(fb_fix_screeninfo)
cdecl_struct(fb_var_screeninfo)

// einkfb:

cdecl_enum(fx_type)
cdecl_struct(update_area_t)
cdecl_enum(orientation_t)

cdecl_enum(einkfb_events_t)
cdecl_struct(einkfb_event_t)

cdecl_const(FBIO_EINK_UPDATE_DISPLAY)
cdecl_const(FBIO_EINK_UPDATE_DISPLAY_AREA)
cdecl_const(FBIO_EINK_SET_DISPLAY_ORIENTATION)
cdecl_const(FBIO_EINK_GET_DISPLAY_ORIENTATION)

// mxcfb:

cdecl_struct(mxcfb_rect)
cdecl_struct(mxcfb_alt_buffer_data)
cdecl_struct(mxcfb_alt_buffer_data_kobo)
cdecl_struct(mxcfb_update_data)
cdecl_struct(mxcfb_update_data_kobo)

cdecl_const(MXCFB_SEND_UPDATE)
