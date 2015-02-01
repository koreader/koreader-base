local ffi = require("ffi")

ffi.cdef[[
struct mxcfb_rect {
  unsigned int top;
  unsigned int left;
  unsigned int width;
  unsigned int height;
};
struct mxcfb_alt_buffer_data {
  unsigned int phys_addr;
  unsigned int width;
  unsigned int height;
  struct mxcfb_rect alt_update_region;
};
struct mxcfb_update_data {
  struct mxcfb_rect update_region;
  unsigned int waveform_mode;
  unsigned int update_mode;
  unsigned int update_marker;
  int temp;
  unsigned int flags;
  struct mxcfb_alt_buffer_data alt_buffer_data;
};
struct mxcfb_update_marker_data {
  unsigned int update_marker;
  unsigned int collision_test;
};
static const int UPDATE_MODE_PARTIAL = 0;
static const int UPDATE_MODE_FULL = 1;
static const int WAVEFORM_MODE_INIT = 0;
static const int WAVEFORM_MODE_DU = 1;
static const int WAVEFORM_MODE_GC16 = 2;
static const int WAVEFORM_MODE_GC4 = 3;
static const int WAVEFORM_MODE_A2 = 4;
static const int WAVEFORM_MODE_GL16 = 5;
static const int WAVEFORM_MODE_A2IN = 6;
static const int WAVEFORM_MODE_A2OUT = 7;
static const int WAVEFORM_MODE_GL4 = 10;
static const int WAVEFORM_MODE_GL16_INV = 11;
static const int WAVEFORM_MODE_AUTO = 257;
static const int TEMP_USE_AMBIENT = 4096;
static const int TEMP_USE_PAPYRUS = 4097;
static const int TEMP_USE_AUTO = 4097;
static const int EPDC_FLAG_ENABLE_INVERSION = 1;
static const int EPDC_FLAG_FORCE_MONOCHROME = 2;
static const int EPDC_FLAG_USE_CMAP = 4;
static const int EPDC_FLAG_USE_ALT_BUFFER = 256;
static const int EPDC_FLAG_TEST_COLLISION = 512;
static const int EPDC_FLAG_GROUP_UPDATE = 1024;
static const int EPDC_FLAG_FORCE_Y2 = 2048;
static const int EPDC_FLAG_USE_REAGLD = 4096;
static const int EPDC_FLAG_USE_DITHERING_Y1 = 8192;
static const int EPDC_FLAG_USE_DITHERING_Y2 = 16384;
static const int EPDC_FLAG_USE_DITHERING_Y4 = 32768;
static const int MXCFB_SEND_UPDATE = 1077954094;
static const int MXCFB_WAIT_FOR_UPDATE_COMPLETE = 1074021935;
]]
