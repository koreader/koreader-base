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
  unsigned int hist_bw_waveform_mode;
  unsigned int hist_gray_waveform_mode;
  int temp;
  unsigned int flags;
  struct mxcfb_alt_buffer_data alt_buffer_data;
};
static const int MXCFB_SEND_UPDATE = 1078478382;
struct mxcfb_update_marker_data {
  unsigned int update_marker;
  unsigned int collision_test;
};
static const int MXCFB_WAIT_FOR_UPDATE_COMPLETE = 3221767727;
static const int MXCFB_WAIT_FOR_UPDATE_COMPLETE_PEARL = 1074021935;
static const int MXCFB_WAIT_FOR_UPDATE_SUBMISSION = 1074021943;
]]
