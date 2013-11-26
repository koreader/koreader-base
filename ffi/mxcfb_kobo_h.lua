local ffi = require("ffi")
ffi.cdef[[
struct mxcfb_rect {
  unsigned int top;
  unsigned int left;
  unsigned int width;
  unsigned int height;
};
struct mxcfb_alt_buffer_data {
  void *virt_addr;
  unsigned int phys_addr;
  unsigned int width;
  unsigned int height;
  struct mxcfb_rect alt_update_region;
};
struct mxcfb_alt_buffer_data_kobo;
struct mxcfb_update_data {
  struct mxcfb_rect update_region;
  unsigned int waveform_mode;
  unsigned int update_mode;
  unsigned int update_marker;
  int temp;
  unsigned int flags;
  struct mxcfb_alt_buffer_data alt_buffer_data;
};
struct mxcfb_update_data_kobo;
static const int MXCFB_SEND_UPDATE = 0x4044462e;
]]
