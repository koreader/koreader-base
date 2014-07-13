// standard Linux framebuffer headers
#include <linux/fb.h>

#include <linux/ioctl.h>
// specialized eink framebuffer headers
typedef unsigned int uint;
#include "include/mxcfb-kobo.h"

#include "ffi-cdecl.h"
#include "ffi-cdecl-luajit.h"

cdecl_struct(mxcfb_rect)
cdecl_struct(mxcfb_alt_buffer_data)
cdecl_struct(mxcfb_update_data)

cdecl_const(MXCFB_SEND_UPDATE)

/* Might come in handy one day... */
cdecl_const(MXCFB_WAIT_FOR_UPDATE_COMPLETE)

/* Aura */
cdecl_struct(mxcfb_alt_buffer_data_org)
cdecl_struct(mxcfb_update_data_org)

cdecl_const(MXCFB_SEND_UPDATE_ORG)

