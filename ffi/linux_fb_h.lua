local ffi = require("ffi")
ffi.cdef[[
static const int FBIOGET_FSCREENINFO = 17922;
static const int FBIOGET_VSCREENINFO = 17920;
static const int FB_TYPE_PACKED_PIXELS = 0;
struct fb_bitfield {
  unsigned int offset;
  unsigned int length;
  unsigned int msb_right;
};
struct fb_fix_screeninfo {
  char id[16];
  long unsigned int smem_start;
  unsigned int smem_len;
  unsigned int type;
  unsigned int type_aux;
  unsigned int visual;
  short unsigned int xpanstep;
  short unsigned int ypanstep;
  short unsigned int ywrapstep;
  unsigned int line_length;
  long unsigned int mmio_start;
  unsigned int mmio_len;
  unsigned int accel;
  short unsigned int capabilities;
  short unsigned int reserved[2];
};
struct fb_var_screeninfo {
  unsigned int xres;
  unsigned int yres;
  unsigned int xres_virtual;
  unsigned int yres_virtual;
  unsigned int xoffset;
  unsigned int yoffset;
  unsigned int bits_per_pixel;
  unsigned int grayscale;
  struct fb_bitfield red;
  struct fb_bitfield green;
  struct fb_bitfield blue;
  struct fb_bitfield transp;
  unsigned int nonstd;
  unsigned int activate;
  unsigned int height;
  unsigned int width;
  unsigned int accel_flags;
  unsigned int pixclock;
  unsigned int left_margin;
  unsigned int right_margin;
  unsigned int upper_margin;
  unsigned int lower_margin;
  unsigned int hsync_len;
  unsigned int vsync_len;
  unsigned int sync;
  unsigned int vmode;
  unsigned int rotate;
  unsigned int colorspace;
  unsigned int reserved[4];
};
enum fx_type {
  fx_mask = 11,
  fx_buf_is_mask = 14,
  fx_none = -1,
  fx_flash = 20,
  fx_invert = 21,
  fx_update_partial = 0,
  fx_update_full = 1,
};
struct update_area_t {
  int x1;
  int y1;
  int x2;
  int y2;
  enum fx_type which_fx;
  unsigned char *buffer;
};
enum orientation_t {
  orientation_portrait = 0,
  orientation_portrait_upside_down = 1,
  orientation_landscape = 2,
  orientation_landscape_upside_down = 3,
};
enum einkfb_events_t {
  einkfb_event_update_display = 0,
  einkfb_event_update_display_area = 1,
  einkfb_event_blank_display = 2,
  einkfb_event_rotate_display = 3,
  einkfb_event_null = -1,
};
struct einkfb_event_t {
  enum einkfb_events_t event;
  enum fx_type update_mode;
  int x1;
  int y1;
  int x2;
  int y2;
  enum orientation_t orientation;
};
static const int FBIO_EINK_UPDATE_DISPLAY = 18139;
static const int FBIO_EINK_UPDATE_DISPLAY_AREA = 18141;
static const int FBIO_EINK_SET_DISPLAY_ORIENTATION = 18160;
static const int FBIO_EINK_GET_DISPLAY_ORIENTATION = 18161;
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
struct mxcfb_alt_buffer_data_kobo {
  void *virt_addr;
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
struct mxcfb_update_data_kobo {
  struct mxcfb_rect update_region;
  unsigned int waveform_mode;
  unsigned int update_mode;
  unsigned int update_marker;
  int temp;
  unsigned int flags;
  struct mxcfb_alt_buffer_data_kobo alt_buffer_data;
};
static const int MXCFB_SEND_UPDATE = 1078478382;
]]
