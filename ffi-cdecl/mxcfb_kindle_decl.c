// standard Linux framebuffer headers
#include <linux/fb.h>

#include <linux/ioctl.h>
// specialized eink framebuffer headers
#include "include/mxcfb-kindle.h"

#include "ffi-cdecl.h"

cdecl_const(UPDATE_MODE_PARTIAL)
cdecl_const(UPDATE_MODE_FULL)

cdecl_const(WAVEFORM_MODE_INIT)
cdecl_const(WAVEFORM_MODE_DU)
cdecl_const(WAVEFORM_MODE_GC16)
cdecl_const(WAVEFORM_MODE_GC4)
cdecl_const(WAVEFORM_MODE_GC16_FAST)
cdecl_const(WAVEFORM_MODE_A2)
cdecl_const(WAVEFORM_MODE_GL16)
cdecl_const(WAVEFORM_MODE_GL16_FAST)
cdecl_const(WAVEFORM_MODE_DU4)
cdecl_const(WAVEFORM_MODE_REAGL)
cdecl_const(WAVEFORM_MODE_REAGLD)
cdecl_const(WAVEFORM_MODE_GL4)
cdecl_const(WAVEFORM_MODE_GL16_INV)
cdecl_const(WAVEFORM_MODE_AUTO)

cdecl_const(WAVEFORM_MODE_ZELDA_GL16)
cdecl_const(WAVEFORM_MODE_ZELDA_A2)
cdecl_const(WAVEFORM_MODE_ZELDA_LAST)
cdecl_const(WAVEFORM_MODE_ZELDA_REAGL)
cdecl_const(WAVEFORM_MODE_ZELDA_REAGLD)
cdecl_const(WAVEFORM_MODE_ZELDA_GC16_FAST)
cdecl_const(WAVEFORM_MODE_ZELDA_GL16_FAST)
cdecl_const(WAVEFORM_MODE_ZELDA_GLR16)
cdecl_const(WAVEFORM_MODE_ZELDA_GLD16)
cdecl_const(WAVEFORM_MODE_ZELDA_GCK16)
cdecl_const(WAVEFORM_MODE_ZELDA_GLKW16)
cdecl_const(WAVEFORM_MODE_ZELDA_GL4)
cdecl_const(WAVEFORM_MODE_ZELDA_GL16_INV)

cdecl_const(TEMP_USE_AMBIENT)
cdecl_const(TEMP_USE_PAPYRUS)
cdecl_const(TEMP_USE_AUTO)

cdecl_const(TEMP_USE_ZELDA_AUTO)

cdecl_const(EPDC_FLAG_ENABLE_INVERSION)
cdecl_const(EPDC_FLAG_FORCE_MONOCHROME)
cdecl_const(EPDC_FLAG_USE_CMAP)
cdecl_const(EPDC_FLAG_USE_ALT_BUFFER)
cdecl_const(EPDC_FLAG_TEST_COLLISION)
cdecl_const(EPDC_FLAG_GROUP_UPDATE)
cdecl_const(EPDC_FLAG_FORCE_Y2)
cdecl_const(EPDC_FLAG_USE_REAGLD)
cdecl_const(EPDC_FLAG_USE_DITHERING_Y1)
cdecl_const(EPDC_FLAG_USE_DITHERING_Y2)
cdecl_const(EPDC_FLAG_USE_DITHERING_Y4)

cdecl_const(EPDC_FLAG_USE_ZELDA_DITHERING_Y4)
cdecl_const(EPDC_FLAG_USE_ZELDA_REGAL)

cdecl_enum(mxcfb_dithering_mode)

cdecl_struct(mxcfb_rect)
cdecl_struct(mxcfb_alt_buffer_data)
cdecl_struct(mxcfb_update_data)

cdecl_struct(mxcfb_update_data_zelda)

cdecl_struct(mxcfb_update_data_rex)

cdecl_const(MXCFB_SEND_UPDATE)

cdecl_const(MXCFB_SEND_UPDATE_ZELDA)

cdecl_const(MXCFB_SEND_UPDATE_REX)

cdecl_struct(mxcfb_update_marker_data)
cdecl_const(MXCFB_WAIT_FOR_UPDATE_COMPLETE)

cdecl_const(MXCFB_WAIT_FOR_UPDATE_COMPLETE_PEARL)

cdecl_const(MXCFB_WAIT_FOR_UPDATE_SUBMISSION)

cdecl_const(NIGHTMODE_STRIDE_DEFAULT)
cdecl_const(NIGHTMODE_STRIDE_DEFAULT_REX)
cdecl_struct(mxcfb_nightmode_ctrl)
cdecl_const(MXCFB_SET_NIGHTMODE)
