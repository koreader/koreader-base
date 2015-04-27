// standard Linux framebuffer headers
#include <linux/fb.h>

#include <linux/ioctl.h>
// specialized eink framebuffer headers
typedef unsigned int u_int;
typedef unsigned long u_long;
#include "include/einkfb.h"

#include "ffi-cdecl.h"

cdecl_enum(fx_type)
cdecl_struct(update_area_t)
cdecl_enum(orientation_t)

cdecl_enum(einkfb_events_t)
cdecl_struct(einkfb_event_t)

cdecl_const(FBIO_EINK_UPDATE_DISPLAY)
cdecl_const(FBIO_EINK_UPDATE_DISPLAY_AREA)
cdecl_const(FBIO_EINK_SET_DISPLAY_ORIENTATION)
cdecl_const(FBIO_EINK_GET_DISPLAY_ORIENTATION)

