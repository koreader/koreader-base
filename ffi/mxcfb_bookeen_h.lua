-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
struct bookeen_region_t {
  __u32 x_start;
  __u32 x_end;
  __u32 y_start;
  __u32 y_end;
};
struct mxcfb_update_data_bookeen {
  __u32 u0;
  __u32 u1;
  __u32 u2;
  __u32 u3;
  struct bookeen_region_t update_region;
};
static const unsigned UPDATE_MODE_PARTIAL = 0;
static const unsigned UPDATE_MODE_FULL = 1;
static const unsigned EINK_DU_MODE = 2;
static const unsigned EINK_GC16_MODE = 4;
static const unsigned EINK_GC4_MODE = 8;
static const unsigned EINK_A2_MODE = 16;
static const unsigned EINK_SHORT_GC16_LOCAL_MODE = 32;
static const unsigned EINK_SHORT_DU_MODE = 64;
static const unsigned EINK_LOCAL_MODE = 128;
static const unsigned EINK_A2_OUT_MODE = 256;
static const unsigned EINK_DITHERING_MODE = 512;
static const unsigned EINK_RECTANGLE_MODE = 1024;
static const unsigned EINK_A2_IN_MODE = 2048;
static const unsigned DISP_CMD_EINK_UPDATE = 1026;
static const unsigned DISP_CMD_EINK_SET_MODE = 1027;
static const unsigned DISP_CMD_EINK_SET_TEMPERATURE = 1028;
static const unsigned DISP_CMD_EINK_GET_UPDATE_STATUS = 1029;
]]
