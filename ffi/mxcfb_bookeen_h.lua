local ffi = require("ffi")

ffi.cdef[[
static const int UPDATE_MODE_PARTIAL = 0;
static const int UPDATE_MODE_FULL = 1;

static const int EINK_DU_MODE = 0x02;
static const int EINK_GC16_MODE = 0x04;
static const int EINK_GC4_MODE = 0x08;
static const int EINK_A2_MODE = 0x10;
static const int EINK_SHORT_GC16_LOCAL_MODE = 0x20;
static const int EINK_SHORT_DU_MODE = 0x40;
static const int EINK_LOCAL_MODE = 0x80;
static const int EINK_A2_OUT_MODE = 0x100;
static const int EINK_DITHERING_MODE = 0x200;
static const int EINK_RECTANGLE_MODE = 0x400;
static const int EINK_A2_IN_MODE = 0x800;

struct bookeen_region_t {
  unsigned int x_start;
  unsigned int x_end;
  unsigned int y_start;
  unsigned int y_end;
};

struct mxcfb_update_data_bookeen {
  unsigned int u0;
  unsigned int u1;
  unsigned int u2;
  unsigned int u3;
  struct bookeen_region_t update_region;
};

static const int DISP_CMD_EINK_UPDATE = 0x402;
static const int DISP_CMD_EINK_SET_MODE = 0x403;
static const int DISP_CMD_EINK_SET_TEMPERATURE = 0x404;
static const int DISP_CMD_EINK_GET_UPDATE_STATUS = 0x405;

]]

