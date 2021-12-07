#include <linux/ioctl.h>
// specialized sunxi disp/eink headers
#include "include/sunxi-kobo.h"

#include "ffi-cdecl.h"

cdecl_struct(area_info)
cdecl_enum(eink_update_mode)
cdecl_struct(disp_rectsz)
cdecl_enum(disp_pixel_format)
cdecl_enum(disp_color_space)
cdecl_struct(disp_rect64)
cdecl_enum(disp_buffer_flags)
cdecl_enum(disp_scan_flags)
cdecl_enum(disp_layer_mode)
cdecl_struct(disp_rect)
cdecl_enum(disp_3d_out_mode)
cdecl_enum(disp_eotf)
cdecl_enum(disp_atw_mode)
cdecl_struct(disp_atw_info)
cdecl_struct(disp_fb_info2)
cdecl_struct(disp_layer_info2)
cdecl_struct(disp_layer_config2)

cdecl_const(DISP_EINK_UPDATE2)
cdecl_const(DISP_EINK_WAIT_BEFORE_LCD_INT_COMPLETE)
cdecl_const(DISP_EINK_SET_UPDATE_CONTROL)
cdecl_const(DISP_EINK_WAIT_FRAME_SYNC_COMPLETE)
cdecl_const(DISP_EINK_SET_NTX_HANDWRITE_ONOFF)
cdecl_const(DISP_EINK_SET_WAIT_MODE_ONOFF)

cdecl_type(sunxi_disp_raw_ioctl)
cdecl_type(sunxi_disp_eink_update2)
cdecl_type(sunxi_disp_eink_set_update_control)
cdecl_type(sunxi_disp_eink_wait_frame_sync_complete)
cdecl_type(sunxi_disp_eink_set_ntx_handwrite_onoff)
cdecl_type(sunxi_disp_eink_set_wait_mode_onoff)

cdecl_struct(disp_fb_info)
cdecl_struct(disp_layer_info)
cdecl_struct(disp_layer_config)
cdecl_type(sunxi_disp_eink_update)
cdecl_type(sunxi_disp_eink_set_temp)
cdecl_type(sunxi_disp_eink_overlap_skip)
cdecl_type(sunxi_disp_eink_set_gc_count)
cdecl_struct(cfa_enable)
cdecl_type(sunxi_disp_eink_set_bg_onoff)
cdecl_type(sunxi_disp_layer_get_config2)
cdecl_type(sunxi_disp_layer_get_config)
cdecl_type(sunxi_disp_layer_generic_get)

cdecl_type(sunxi_disp_eink_ioctl)
