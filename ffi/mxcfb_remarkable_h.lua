-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
typedef unsigned __u32;
static const unsigned UPDATE_MODE_PARTIAL = 0;
static const unsigned UPDATE_MODE_FULL = 1;
static const unsigned WAVEFORM_MODE_INIT = 0;
static const unsigned WAVEFORM_MODE_DU = 1;
static const unsigned WAVEFORM_MODE_GC16 = 2;
static const unsigned WAVEFORM_MODE_GL16 = 3;
static const unsigned WAVEFORM_MODE_A2 = 4;
static const unsigned WAVEFORM_MODE_AUTO = 257;
static const unsigned TEMP_USE_AMBIENT = 4096;
static const unsigned TEMP_USE_REMARKABLE = 24;
static const unsigned EPDC_FLAG_ENABLE_INVERSION = 1;
static const unsigned EPDC_FLAG_FORCE_MONOCHROME = 2;
static const unsigned EPDC_FLAG_USE_CMAP = 4;
static const unsigned EPDC_FLAG_USE_ALT_BUFFER = 256;
static const unsigned EPDC_FLAG_USE_DITHERING_Y1 = 8192;
static const unsigned EPDC_FLAG_USE_DITHERING_Y4 = 16384;
static const unsigned EPDC_FLAG_USE_REGAL = 32768;
enum mxcfb_dithering_mode {
  EPDC_FLAG_USE_DITHERING_PASSTHROUGH = 0x0,
  EPDC_FLAG_USE_DITHERING_FLOYD_STEINBERG,
  EPDC_FLAG_USE_DITHERING_ATKINSON,
  EPDC_FLAG_USE_DITHERING_ORDERED,
  EPDC_FLAG_USE_DITHERING_QUANT_ONLY,
  EPDC_FLAG_USE_DITHERING_MAX,
};
struct mxcfb_rect {
  __u32 top;
  __u32 left;
  __u32 width;
  __u32 height;
};
struct mxcfb_alt_buffer_data {
  __u32 phys_addr;
  __u32 width;
  __u32 height;
  struct mxcfb_rect alt_update_region;
};
struct mxcfb_update_data {
  struct mxcfb_rect update_region;
  __u32 waveform_mode;
  __u32 update_mode;
  __u32 update_marker;
  int temp;
  unsigned flags;
  int dither_mode;
  int quant_bit;
  struct mxcfb_alt_buffer_data alt_buffer_data;
};
struct mxcfb_update_marker_data {
  __u32 update_marker;
  __u32 collision_test;
};
static const unsigned MXCFB_SEND_UPDATE = 1078478382;
static const unsigned MXCFB_WAIT_FOR_UPDATE_COMPLETE = 3221767727;
]]
