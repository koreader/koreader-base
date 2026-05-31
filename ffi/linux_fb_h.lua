-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
typedef unsigned short __u16;
typedef unsigned __u32;
static const unsigned FBIOGET_FSCREENINFO = 17922;
static const unsigned FBIOGET_VSCREENINFO = 17920;
static const unsigned FBIOPUT_VSCREENINFO = 17921;
static const unsigned FB_TYPE_PACKED_PIXELS = 0;
static const unsigned FB_ROTATE_UR = 0;
static const unsigned FB_ROTATE_CW = 1;
static const unsigned FB_ROTATE_UD = 2;
static const unsigned FB_ROTATE_CCW = 3;
struct fb_bitfield {
  __u32 offset;
  __u32 length;
  __u32 msb_right;
};
struct fb_fix_screeninfo {
  char id[16];
  unsigned long smem_start;
  __u32 smem_len;
  __u32 type;
  __u32 type_aux;
  __u32 visual;
  __u16 xpanstep;
  __u16 ypanstep;
  __u16 ywrapstep;
  __u32 line_length;
  unsigned long mmio_start;
  __u32 mmio_len;
  __u32 accel;
  __u16 capabilities;
  __u16 reserved[2];
};
struct fb_var_screeninfo {
  __u32 xres;
  __u32 yres;
  __u32 xres_virtual;
  __u32 yres_virtual;
  __u32 xoffset;
  __u32 yoffset;
  __u32 bits_per_pixel;
  __u32 grayscale;
  struct fb_bitfield red;
  struct fb_bitfield green;
  struct fb_bitfield blue;
  struct fb_bitfield transp;
  __u32 nonstd;
  __u32 activate;
  __u32 height;
  __u32 width;
  __u32 accel_flags;
  __u32 pixclock;
  __u32 left_margin;
  __u32 right_margin;
  __u32 upper_margin;
  __u32 lower_margin;
  __u32 hsync_len;
  __u32 vsync_len;
  __u32 sync;
  __u32 vmode;
  __u32 rotate;
  __u32 colorspace;
  __u32 reserved[4];
};
]]
