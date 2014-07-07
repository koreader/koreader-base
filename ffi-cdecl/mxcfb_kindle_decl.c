// standard Linux framebuffer headers
#include <linux/fb.h>

#include <linux/ioctl.h>
// specialized eink framebuffer headers
typedef unsigned int uint;
#include "include/mxcfb-kindle.h"

#include "cdecl.h"

cdecl_struct(mxcfb_rect)
cdecl_struct(mxcfb_alt_buffer_data)
cdecl_struct(mxcfb_update_data)

cdecl_const(MXCFB_SEND_UPDATE)

/* Might come in handy one day... */
cdecl_struct(mxcfb_update_marker_data)
cdecl_const(MXCFB_WAIT_FOR_UPDATE_COMPLETE)

cdecl_const(MXCFB_WAIT_FOR_UPDATE_COMPLETE_PEARL)

cdecl_const(MXCFB_WAIT_FOR_UPDATE_SUBMISSION)
