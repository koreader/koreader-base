#include <linux/ioctl.h>
// specialized eink framebuffer headers
#include "include/mxcfb-kobo.h"
#include "include/mtk-kobo.h"

#include "ffi-cdecl.h"

cdecl_const(UPDATE_MODE_PARTIAL)
cdecl_const(UPDATE_MODE_FULL)

cdecl_const(WAVEFORM_MODE_INIT)
cdecl_const(WAVEFORM_MODE_DU)
cdecl_const(WAVEFORM_MODE_GC16)
cdecl_const(WAVEFORM_MODE_GC4)
cdecl_const(WAVEFORM_MODE_A2)
cdecl_const(WAVEFORM_MODE_GL16)
cdecl_const(WAVEFORM_MODE_REAGL)
cdecl_const(WAVEFORM_MODE_REAGLD)
cdecl_const(WAVEFORM_MODE_DU4)
cdecl_const(WAVEFORM_MODE_GCK16)
cdecl_const(WAVEFORM_MODE_GLKW16)
cdecl_const(WAVEFORM_MODE_AUTO)

cdecl_const(TEMP_USE_AMBIENT)

cdecl_const(EPDC_FLAG_ENABLE_INVERSION)
cdecl_const(EPDC_FLAG_FORCE_MONOCHROME)
cdecl_const(EPDC_FLAG_USE_CMAP)
cdecl_const(EPDC_FLAG_USE_ALT_BUFFER)
cdecl_const(EPDC_FLAG_USE_AAD)

cdecl_const(EPDC_FLAG_TEST_COLLISION)
cdecl_const(EPDC_FLAG_GROUP_UPDATE)
cdecl_const(EPDC_FLAG_USE_DITHERING_Y1)
cdecl_const(EPDC_FLAG_USE_DITHERING_Y4)
cdecl_const(EPDC_FLAG_USE_REGAL)
cdecl_const(EPDC_FLAG_USE_DITHERING_NTX_D8)

cdecl_enum(mxcfb_dithering_mode)

cdecl_struct(mxcfb_rect)
cdecl_struct(mxcfb_alt_buffer_data_ntx)
cdecl_struct(mxcfb_update_data_v1_ntx)

cdecl_struct(mxcfb_alt_buffer_data)
cdecl_struct(mxcfb_update_data_v1)		// Aura
cdecl_struct(mxcfb_update_data_v2)		// Mark 7

cdecl_struct(mxcfb_update_marker_data)		// Mark 7

cdecl_const(MXCFB_SEND_UPDATE_V1_NTX)
cdecl_const(MXCFB_WAIT_FOR_UPDATE_COMPLETE_V1)

cdecl_const(MXCFB_SEND_UPDATE_V1)		// Aura
cdecl_const(MXCFB_SEND_UPDATE_V2)		// Mark 7
cdecl_const(MXCFB_WAIT_FOR_UPDATE_COMPLETE_V3)	// Mark 7

cdecl_const(MXCFB_SET_PWRDOWN_DELAY)
cdecl_const(MXCFB_GET_PWRDOWN_DELAY)

// And now for MTK stuff
cdecl_const(HWTCON_FLAG_USE_DITHERING)
cdecl_const(HWTCON_FLAG_FORCE_A2_OUTPUT)
cdecl_const(HWTCON_FLAG_FORCE_A2_OUTPUT_WHITE)
cdecl_const(HWTCON_FLAG_FORCE_A2_OUTPUT_BLACK)
cdecl_const(HWTCON_FLAG_CFA_EINK_G1)
cdecl_const(HWTCON_FLAG_CFA_EINK_G2)
cdecl_const(HWTCON_FLAG_CFA_SKIP)

cdecl_const(TEMP_USE_SENSOR)

cdecl_enum(HWTCON_WAVEFORM_MODE_ENUM)

cdecl_enum(hwtcon_dithering_mode)

cdecl_struct(hwtcon_rect)
cdecl_struct(hwtcon_update_marker_data)
cdecl_struct(hwtcon_update_data)

cdecl_const(HWTCON_SET_TEMPERATURE)
cdecl_const(HWTCON_SEND_UPDATE)
cdecl_const(HWTCON_WAIT_FOR_UPDATE_SUBMISSION)
cdecl_const(HWTCON_WAIT_FOR_UPDATE_COMPLETE)
