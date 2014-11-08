// standard Linux framebuffer headers
#include <linux/fb.h>

#include <linux/ioctl.h>
// specialized eink framebuffer headers
typedef unsigned int uint;
#include "include/mxcfb-kobo.h"

#include "ffi-cdecl.h"
#include "ffi-cdecl-luajit.h"

cdecl_const(UPDATE_MODE_PARTIAL)
cdecl_const(UPDATE_MODE_FULL)

cdecl_const(WAVEFORM_MODE_KOBO_REGAL)
cdecl_const(WAVEFORM_MODE_AUTO)

cdecl_const(TEMP_USE_AMBIENT)

cdecl_const(EPDC_FLAG_ENABLE_INVERSION)
cdecl_const(EPDC_FLAG_FORCE_MONOCHROME)
cdecl_const(EPDC_FLAG_USE_CMAP)
cdecl_const(EPDC_FLAG_USE_ALT_BUFFER)
cdecl_const(EPDC_FLAG_USE_AAD)

cdecl_struct(mxcfb_rect)
cdecl_struct(mxcfb_alt_buffer_data)
cdecl_struct(mxcfb_update_data)

cdecl_const(MXCFB_SEND_UPDATE)
cdecl_const(MXCFB_WAIT_FOR_UPDATE_COMPLETE)

/* Aura */
cdecl_struct(mxcfb_alt_buffer_data_org)
cdecl_struct(mxcfb_update_data_org)

cdecl_const(MXCFB_SEND_UPDATE_ORG)

