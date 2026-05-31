-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
static const unsigned UPDATE_MODE_PARTIAL = 0;
static const unsigned UPDATE_MODE_FULL = 1;
static const unsigned WAVEFORM_MODE_INIT = 0;
static const unsigned WAVEFORM_MODE_DU = 1;
static const unsigned WAVEFORM_MODE_GC16 = 2;
static const unsigned WAVEFORM_MODE_GC4 = 3;
static const unsigned WAVEFORM_MODE_A2 = 4;
static const unsigned WAVEFORM_MODE_GL16 = 5;
static const unsigned WAVEFORM_MODE_REAGL = 6;
static const unsigned WAVEFORM_MODE_REAGLD = 7;
static const unsigned WAVEFORM_MODE_DU4 = 8;
static const unsigned WAVEFORM_MODE_GCK16 = 9;
static const unsigned WAVEFORM_MODE_GLKW16 = 10;
static const unsigned WAVEFORM_MODE_AUTO = 257;
static const unsigned TEMP_USE_AMBIENT = 4096;
static const unsigned EPDC_FLAG_ENABLE_INVERSION = 1;
static const unsigned EPDC_FLAG_FORCE_MONOCHROME = 2;
static const unsigned EPDC_FLAG_USE_CMAP = 4;
static const unsigned EPDC_FLAG_USE_ALT_BUFFER = 256;
static const unsigned EPDC_FLAG_USE_AAD = 4096;
static const unsigned EPDC_FLAG_TEST_COLLISION = 512;
static const unsigned EPDC_FLAG_GROUP_UPDATE = 1024;
static const unsigned EPDC_FLAG_USE_DITHERING_Y1 = 8192;
static const unsigned EPDC_FLAG_USE_DITHERING_Y4 = 16384;
static const unsigned EPDC_FLAG_USE_REGAL = 32768;
static const unsigned EPDC_FLAG_USE_DITHERING_NTX_D8 = 1048576;
enum mxcfb_dithering_mode {
  EPDC_FLAG_USE_DITHERING_PASSTHROUGH = 0x0,
  EPDC_FLAG_USE_DITHERING_FLOYD_STEINBERG,
  EPDC_FLAG_USE_DITHERING_ATKINSON,
  EPDC_FLAG_USE_DITHERING_ORDERED,
  EPDC_FLAG_USE_DITHERING_QUANT_ONLY,
  EPDC_FLAG_USE_DITHERING_MAX,
};
struct mxcfb_rect {
  uint32_t top;
  uint32_t left;
  uint32_t width;
  uint32_t height;
};
struct mxcfb_alt_buffer_data_ntx {
  void *virt_addr;
  uint32_t phys_addr;
  uint32_t width;
  uint32_t height;
  struct mxcfb_rect alt_update_region;
};
struct mxcfb_update_data_v1_ntx {
  struct mxcfb_rect update_region;
  uint32_t waveform_mode;
  uint32_t update_mode;
  uint32_t update_marker;
  int temp;
  unsigned flags;
  struct mxcfb_alt_buffer_data_ntx alt_buffer_data;
};
struct mxcfb_alt_buffer_data {
  uint32_t phys_addr;
  uint32_t width;
  uint32_t height;
  struct mxcfb_rect alt_update_region;
};
struct mxcfb_update_data_v1 {
  struct mxcfb_rect update_region;
  uint32_t waveform_mode;
  uint32_t update_mode;
  uint32_t update_marker;
  int temp;
  unsigned flags;
  struct mxcfb_alt_buffer_data alt_buffer_data;
};
struct mxcfb_update_data {
  struct mxcfb_rect update_region;
  uint32_t waveform_mode;
  uint32_t update_mode;
  uint32_t update_marker;
  int temp;
  unsigned flags;
  int dither_mode;
  int quant_bit;
  struct mxcfb_alt_buffer_data alt_buffer_data;
};
struct mxcfb_update_marker_data {
  uint32_t update_marker;
  uint32_t collision_test;
};
static const unsigned MXCFB_SEND_UPDATE_V1_NTX = 1078216238;
static const unsigned MXCFB_WAIT_FOR_UPDATE_COMPLETE_V1 = 1074021935;
static const unsigned MXCFB_SEND_UPDATE_V1 = 1077954094;
static const unsigned MXCFB_SEND_UPDATE_V2 = 1078478382;
static const unsigned MXCFB_WAIT_FOR_UPDATE_COMPLETE_V3 = 3221767727;
static const unsigned MXCFB_SET_PWRDOWN_DELAY = 1074021936;
static const unsigned MXCFB_GET_PWRDOWN_DELAY = 2147763761;
static const unsigned HWTCON_FLAG_USE_DITHERING = 1;
static const unsigned HWTCON_FLAG_FORCE_A2_OUTPUT = 16;
static const unsigned HWTCON_FLAG_FORCE_A2_OUTPUT_WHITE = 32;
static const unsigned HWTCON_FLAG_FORCE_A2_OUTPUT_BLACK = 64;
static const unsigned HWTCON_FLAG_CFA_EINK_G1 = 256;
static const unsigned HWTCON_FLAG_CFA_EINK_G2 = 1536;
static const unsigned HWTCON_FLAG_CFA_SKIP = 32768;
static const unsigned TEMP_USE_SENSOR = 1048576;
enum HWTCON_WAVEFORM_MODE_ENUM {
  HWTCON_WAVEFORM_MODE_INIT = 0,
  HWTCON_WAVEFORM_MODE_DU = 1,
  HWTCON_WAVEFORM_MODE_GC16 = 2,
  HWTCON_WAVEFORM_MODE_GL16 = 3,
  HWTCON_WAVEFORM_MODE_GLR16 = 4,
  HWTCON_WAVEFORM_MODE_REAGL = 4,
  HWTCON_WAVEFORM_MODE_A2 = 6,
  HWTCON_WAVEFORM_MODE_GCK16 = 8,
  HWTCON_WAVEFORM_MODE_GLKW16 = 9,
  HWTCON_WAVEFORM_MODE_GCC16 = 10,
  HWTCON_WAVEFORM_MODE_GLRC16 = 11,
  HWTCON_WAVEFORM_MODE_AUTO = 257,
};
enum hwtcon_dithering_mode {
  HWTCON_FLAG_USE_DITHERING_Y8_Y4_Q = 0x100,
  HWTCON_FLAG_USE_DITHERING_Y8_Y2_Q = 0x200,
  HWTCON_FLAG_USE_DITHERING_Y8_Y1_Q = 0x300,
  HWTCON_FLAG_USE_DITHERING_Y4_Y2_Q = 0x10200,
  HWTCON_FLAG_USE_DITHERING_Y4_Y1_Q = 0x10300,
  HWTCON_FLAG_USE_DITHERING_Y8_Y4_B = 0x101,
  HWTCON_FLAG_USE_DITHERING_Y8_Y2_B = 0x201,
  HWTCON_FLAG_USE_DITHERING_Y8_Y1_B = 0x301,
  HWTCON_FLAG_USE_DITHERING_Y4_Y2_B = 0x10201,
  HWTCON_FLAG_USE_DITHERING_Y4_Y1_B = 0x10301,
  HWTCON_FLAG_USE_DITHERING_Y8_Y4_S = 0x102,
  HWTCON_FLAG_USE_DITHERING_Y8_Y2_S = 0x202,
  HWTCON_FLAG_USE_DITHERING_Y8_Y1_S = 0x302,
  HWTCON_FLAG_USE_DITHERING_Y4_Y2_S = 0x10202,
  HWTCON_FLAG_USE_DITHERING_Y4_Y1_S = 0x10302,
};
struct hwtcon_rect {
  uint32_t top;
  uint32_t left;
  uint32_t width;
  uint32_t height;
};
struct hwtcon_update_marker_data {
  uint32_t update_marker;
  uint32_t collision_test;
};
struct hwtcon_update_data {
  struct hwtcon_rect update_region;
  uint32_t waveform_mode;
  uint32_t update_mode;
  uint32_t update_marker;
  unsigned flags;
  int dither_mode;
};
static const unsigned HWTCON_SET_TEMPERATURE = 1074021932;
static const unsigned HWTCON_SEND_UPDATE = 1076119086;
static const unsigned HWTCON_WAIT_FOR_UPDATE_SUBMISSION = 1074021943;
static const unsigned HWTCON_WAIT_FOR_UPDATE_COMPLETE = 3221767727;
]]
