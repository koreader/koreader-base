#include <linux/fb.h>
#include <linux/ioctl.h>
#include "include/mxcfb-bookeen.h"
#include "ffi-cdecl.h"

cdecl_struct(bookeen_region_t)
cdecl_struct(mxcfb_update_data_bookeen)

cdecl_const(UPDATE_MODE_PARTIAL)
cdecl_const(UPDATE_MODE_FULL)

cdecl_const(EINK_DU_MODE)
cdecl_const(EINK_GC16_MODE)
cdecl_const(EINK_GC4_MODE)
cdecl_const(EINK_A2_MODE)
cdecl_const(EINK_SHORT_GC16_LOCAL_MODE)
cdecl_const(EINK_SHORT_DU_MODE)
cdecl_const(EINK_LOCAL_MODE)
cdecl_const(EINK_A2_OUT_MODE)
cdecl_const(EINK_DITHERING_MODE)
cdecl_const(EINK_RECTANGLE_MODE)
cdecl_const(EINK_A2_IN_MODE)

cdecl_const(DISP_CMD_EINK_UPDATE)
cdecl_const(DISP_CMD_EINK_SET_MODE)
cdecl_const(DISP_CMD_EINK_SET_TEMPERATURE)
cdecl_const(DISP_CMD_EINK_GET_UPDATE_STATUS)
