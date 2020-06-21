#include <linux/fb.h>
#include <linux/ioctl.h>
#include "include/mxcfb-cervantes.h"
#include "ffi-cdecl.h"

cdecl_const(UPDATE_MODE_PARTIAL)
cdecl_const(UPDATE_MODE_FULL)

cdecl_const(TEMP_USE_AMBIENT)

cdecl_const(WAVEFORM_MODE_AUTO)

cdecl_const(WAVEFORM_MODE_INIT)
cdecl_const(WAVEFORM_MODE_DU)
cdecl_const(WAVEFORM_MODE_GC16)
cdecl_const(WAVEFORM_MODE_A2)
cdecl_const(WAVEFORM_MODE_GL16)
cdecl_const(WAVEFORM_MODE_GLR16)
cdecl_const(WAVEFORM_MODE_GLD16)

cdecl_const(EPDC_FLAG_ENABLE_INVERSION)
cdecl_const(EPDC_FLAG_FORCE_MONOCHROME)
cdecl_const(EPDC_FLAG_USE_ALT_BUFFER)
cdecl_const(EPDC_FLAG_USE_CMAP)
cdecl_const(EPDC_FLAG_TEST_COLLISION)
cdecl_const(EPDC_FLAG_GROUP_UPDATE)
cdecl_const(EPDC_FLAG_USE_DITHERING_Y1)
cdecl_const(EPDC_FLAG_USE_DITHERING_Y4)
cdecl_const(EPDC_FLAG_USE_AAD)
cdecl_const(EPDC_FLAG_USE_DITHERING_NTX_D8)

cdecl_struct(mxcfb_rect)

cdecl_struct(mxcfb_alt_buffer_data)
cdecl_struct(mxcfb_update_data)

cdecl_const(MXCFB_SEND_UPDATE)
cdecl_const(MXCFB_WAIT_FOR_UPDATE_COMPLETE)
