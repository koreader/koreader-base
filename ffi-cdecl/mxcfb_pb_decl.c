// CPPFLAGS="-I/home/niluje/MPLAYER/koreader-base/ffi-cdecl -m32" ./ffi-cdecl x86_64-pc-linux-gnu-gcc /home/niluje/MPLAYER/koreader-base/ffi-cdecl/mxcfb_pb_decl.c /home/niluje/MPLAYER/koreader-base/ffi/mxcfb_pocketbook_h.lua
// standard Linux framebuffer headers
#include <linux/fb.h>

#include <linux/ioctl.h>
// specialized eink framebuffer headers
#include "include/mxcfb-pb.h"

#include "ffi-cdecl.h"

cdecl_const(UPDATE_MODE_PARTIAL)
cdecl_const(UPDATE_MODE_FULL)
cdecl_const(UPDATE_MODE_PARTIALHQ)
cdecl_const(UPDATE_MODE_FULLHQ)

cdecl_const(EPDC_WFTYPE_INIT)
cdecl_const(EPDC_WFTYPE_DU)
cdecl_const(EPDC_WFTYPE_GC16)
cdecl_const(EPDC_WFTYPE_GC4)
cdecl_const(EPDC_WFTYPE_A2)
cdecl_const(EPDC_WFTYPE_GL16)
cdecl_const(EPDC_WFTYPE_GS16)
cdecl_const(EPDC_WFTYPE_A2IN)
cdecl_const(EPDC_WFTYPE_A2OUT)
cdecl_const(EPDC_WFTYPE_DU4)
cdecl_const(EPDC_WFTYPE_AA)
cdecl_const(EPDC_WFTYPE_AAD)
cdecl_const(EPDC_WFTYPE_GC16HQ)
cdecl_const(WAVEFORM_MODE_INIT)
cdecl_const(WAVEFORM_MODE_DU)
cdecl_const(WAVEFORM_MODE_GC16)
cdecl_const(WAVEFORM_MODE_GC4)
cdecl_const(WAVEFORM_MODE_A2)
cdecl_const(WAVEFORM_MODE_GL16)
cdecl_const(WAVEFORM_MODE_GS16)
cdecl_const(WAVEFORM_MODE_A2IN)
cdecl_const(WAVEFORM_MODE_A2OUT)
cdecl_const(WAVEFORM_MODE_DU4)
cdecl_const(WAVEFORM_MODE_REAGL)
cdecl_const(WAVEFORM_MODE_REAGLD)
cdecl_const(WAVEFORM_MODE_GC16HQ)
cdecl_const(WAVEFORM_MODE_AUTO)

cdecl_const(TEMP_USE_AMBIENT)

cdecl_const(EPDC_FLAG_ENABLE_INVERSION)
cdecl_const(EPDC_FLAG_FORCE_MONOCHROME)
cdecl_const(EPDC_FLAG_USE_CMAP)
cdecl_const(EPDC_FLAG_USE_ALT_BUFFER)
cdecl_const(EPDC_FLAG_TEST_COLLISION)
cdecl_const(EPDC_FLAG_GROUP_UPDATE)
cdecl_const(EPDC_FLAG_USE_AAD)
cdecl_const(EPDC_FLAG_USE_DITHERING_Y1)
cdecl_const(EPDC_FLAG_USE_DITHERING_Y4)
cdecl_const(EPDC_FLAG_USE_DITHERING_NTX_D8)


cdecl_struct(mxcfb_rect)

cdecl_struct(mxcfb_alt_buffer_data)
cdecl_struct(mxcfb_update_data)
cdecl_struct(mxcfb_update_marker_data)

cdecl_const(MXCFB_SEND_UPDATE)
cdecl_const(MXCFB_WAIT_FOR_UPDATE_COMPLETE_PB)
cdecl_const(EPDC_GET_UPDATE_STATE)
