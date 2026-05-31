-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
struct area_info {
  unsigned x_top;
  unsigned y_top;
  unsigned x_bottom;
  unsigned y_bottom;
};
enum eink_update_mode {
  EINK_INIT_MODE = 0b00000000000000000000000000000001,
  EINK_DU_MODE = 0b00000000000000000000000000000010,
  EINK_GC16_MODE = 0b00000000000000000000000000000100,
  EINK_GC4_MODE = 0b00000000000000000000000000001000,
  EINK_A2_MODE = 0b00000000000000000000000000010000,
  EINK_GL16_MODE = 0b00000000000000000000000000100000,
  EINK_GLR16_MODE = 0b00000000000000000000000001000000,
  EINK_GLD16_MODE = 0b00000000000000000000000010000000,
  EINK_GU16_MODE = 0b00000000000000000000000010000100,
  EINK_GCK16_MODE = 0b00000000000000000000000010010000,
  EINK_GLK16_MODE = 0b00000000000000000000000010010100,
  EINK_CLEAR_MODE = 0b00000000000000000000000010001000,
  EINK_GC4L_MODE = 0b00000000000000000000000010001100,
  EINK_GCC16_MODE = 0b00000000000000000000000010100000,
  EINK_PARTIAL_MODE = 0b00000000000000000000010000000000,
  EINK_AUTO_MODE = 0b00000000000000001000000000000000,
  EINK_NEGATIVE_MODE = 0b00000000000000010000000000000000,
  EINK_REGAL_MODE = 0b00000000000010000000000000000000,
  EINK_GAMMA_CORRECT = 0b00000000001000000000000000000000,
  EINK_MONOCHROME = 0b00000000010000000000000000000000,
  EINK_DITHERING_Y1 = 0b00000001100000000000000000000000,
  EINK_DITHERING_Y4 = 0b00000010100000000000000000000000,
  EINK_DITHERING_SIMPLE = 0b00000100100000000000000000000000,
  EINK_DITHERING_NTX_Y1 = 0b00001000100000000000000000000000,
  EINK_NO_MERGE = 0b10000000000000000000000000000000,
};
struct disp_rectsz {
  unsigned width;
  unsigned height;
};
enum disp_pixel_format {
  DISP_FORMAT_ARGB_8888 = 0x00,
  DISP_FORMAT_ABGR_8888 = 0x01,
  DISP_FORMAT_RGBA_8888 = 0x02,
  DISP_FORMAT_BGRA_8888 = 0x03,
  DISP_FORMAT_XRGB_8888 = 0x04,
  DISP_FORMAT_XBGR_8888 = 0x05,
  DISP_FORMAT_RGBX_8888 = 0x06,
  DISP_FORMAT_BGRX_8888 = 0x07,
  DISP_FORMAT_RGB_888 = 0x08,
  DISP_FORMAT_BGR_888 = 0x09,
  DISP_FORMAT_RGB_565 = 0x0a,
  DISP_FORMAT_BGR_565 = 0x0b,
  DISP_FORMAT_ARGB_4444 = 0x0c,
  DISP_FORMAT_ABGR_4444 = 0x0d,
  DISP_FORMAT_RGBA_4444 = 0x0e,
  DISP_FORMAT_BGRA_4444 = 0x0f,
  DISP_FORMAT_ARGB_1555 = 0x10,
  DISP_FORMAT_ABGR_1555 = 0x11,
  DISP_FORMAT_RGBA_5551 = 0x12,
  DISP_FORMAT_BGRA_5551 = 0x13,
  DISP_FORMAT_A2R10G10B10 = 0x14,
  DISP_FORMAT_A2B10G10R10 = 0x15,
  DISP_FORMAT_R10G10B10A2 = 0x16,
  DISP_FORMAT_B10G10R10A2 = 0x17,
  DISP_FORMAT_YUV444_I_AYUV = 0x40,
  DISP_FORMAT_YUV444_I_VUYA = 0x41,
  DISP_FORMAT_YUV422_I_YVYU = 0x42,
  DISP_FORMAT_YUV422_I_YUYV = 0x43,
  DISP_FORMAT_YUV422_I_UYVY = 0x44,
  DISP_FORMAT_YUV422_I_VYUY = 0x45,
  DISP_FORMAT_YUV444_P = 0x46,
  DISP_FORMAT_YUV422_P = 0x47,
  DISP_FORMAT_YUV420_P = 0x48,
  DISP_FORMAT_YUV411_P = 0x49,
  DISP_FORMAT_YUV422_SP_UVUV = 0x4a,
  DISP_FORMAT_YUV422_SP_VUVU = 0x4b,
  DISP_FORMAT_YUV420_SP_UVUV = 0x4c,
  DISP_FORMAT_YUV420_SP_VUVU = 0x4d,
  DISP_FORMAT_YUV411_SP_UVUV = 0x4e,
  DISP_FORMAT_YUV411_SP_VUVU = 0x4f,
  DISP_FORMAT_8BIT_GRAY = 0x50,
  DISP_FORMAT_YUV444_I_AYUV_10BIT = 0x51,
  DISP_FORMAT_YUV444_I_VUYA_10BIT = 0x52,
  DISP_FORMAT_YUV422_I_YVYU_10BIT = 0x53,
  DISP_FORMAT_YUV422_I_YUYV_10BIT = 0x54,
  DISP_FORMAT_YUV422_I_UYVY_10BIT = 0x55,
  DISP_FORMAT_YUV422_I_VYUY_10BIT = 0x56,
  DISP_FORMAT_YUV444_P_10BIT = 0x57,
  DISP_FORMAT_YUV422_P_10BIT = 0x58,
  DISP_FORMAT_YUV420_P_10BIT = 0x59,
  DISP_FORMAT_YUV411_P_10BIT = 0x5a,
  DISP_FORMAT_YUV422_SP_UVUV_10BIT = 0x5b,
  DISP_FORMAT_YUV422_SP_VUVU_10BIT = 0x5c,
  DISP_FORMAT_YUV420_SP_UVUV_10BIT = 0x5d,
  DISP_FORMAT_YUV420_SP_VUVU_10BIT = 0x5e,
  DISP_FORMAT_YUV411_SP_UVUV_10BIT = 0x5f,
  DISP_FORMAT_YUV411_SP_VUVU_10BIT = 0x60,
  DISP_FORMAT_MAX,
};
enum disp_color_space {
  DISP_UNDEF = 0x00,
  DISP_UNDEF_F = 0x01,
  DISP_GBR = 0x100,
  DISP_BT709 = 0x101,
  DISP_FCC = 0x102,
  DISP_BT470BG = 0x103,
  DISP_BT601 = 0x104,
  DISP_SMPTE240M = 0x105,
  DISP_YCGCO = 0x106,
  DISP_BT2020NC = 0x107,
  DISP_BT2020C = 0x108,
  DISP_GBR_F = 0x200,
  DISP_BT709_F = 0x201,
  DISP_FCC_F = 0x202,
  DISP_BT470BG_F = 0x203,
  DISP_BT601_F = 0x204,
  DISP_SMPTE240M_F = 0x205,
  DISP_YCGCO_F = 0x206,
  DISP_BT2020NC_F = 0x207,
  DISP_BT2020C_F = 0x208,
  DISP_RESERVED = 0x300,
  DISP_RESERVED_F = 0x301,
};
struct disp_rect64 {
  long long x;
  long long y;
  long long width;
  long long height;
};
enum disp_buffer_flags {
  DISP_BF_NORMAL = 0,
  DISP_BF_STEREO_TB = 1 << 0,
  DISP_BF_STEREO_FP = 1 << 1,
  DISP_BF_STEREO_SSH = 1 << 2,
  DISP_BF_STEREO_SSF = 1 << 3,
  DISP_BF_STEREO_LI = 1 << 4,
  DISP_BF_STEREO_2D_DEPTH = 1 << 5,
};
enum disp_scan_flags {
  DISP_SCAN_PROGRESSIVE = 0,
  DISP_SCAN_INTERLACED_ODD_FLD_FIRST = 1 << 0,
  DISP_SCAN_INTERLACED_EVEN_FLD_FIRST = 1 << 1,
};
enum disp_layer_mode {
  LAYER_MODE_BUFFER = 0,
  LAYER_MODE_COLOR = 1,
};
struct disp_rect {
  int x;
  int y;
  unsigned width;
  unsigned height;
};
enum disp_3d_out_mode {
  DISP_3D_OUT_MODE_CI_1 = 0x5,
  DISP_3D_OUT_MODE_CI_2 = 0x6,
  DISP_3D_OUT_MODE_CI_3 = 0x7,
  DISP_3D_OUT_MODE_CI_4 = 0x8,
  DISP_3D_OUT_MODE_LIRGB = 0x9,
  DISP_3D_OUT_MODE_TB = 0x0,
  DISP_3D_OUT_MODE_FP = 0x1,
  DISP_3D_OUT_MODE_SSF = 0x2,
  DISP_3D_OUT_MODE_SSH = 0x3,
  DISP_3D_OUT_MODE_LI = 0x4,
  DISP_3D_OUT_MODE_FA = 0xa,
};
enum disp_eotf {
  DISP_EOTF_RESERVED = 0x000,
  DISP_EOTF_BT709 = 0x001,
  DISP_EOTF_UNDEF = 0x002,
  DISP_EOTF_GAMMA22 = 0x004,
  DISP_EOTF_GAMMA28 = 0x005,
  DISP_EOTF_BT601 = 0x006,
  DISP_EOTF_SMPTE240M = 0x007,
  DISP_EOTF_LINEAR = 0x008,
  DISP_EOTF_LOG100 = 0x009,
  DISP_EOTF_LOG100S10 = 0x00a,
  DISP_EOTF_IEC61966_2_4 = 0x00b,
  DISP_EOTF_BT1361 = 0x00c,
  DISP_EOTF_IEC61966_2_1 = 0X00d,
  DISP_EOTF_BT2020_0 = 0x00e,
  DISP_EOTF_BT2020_1 = 0x00f,
  DISP_EOTF_SMPTE2084 = 0x010,
  DISP_EOTF_SMPTE428_1 = 0x011,
  DISP_EOTF_ARIB_STD_B67 = 0x012,
};
enum disp_atw_mode {
  NORMAL_MODE,
  LEFT_RIGHT_MODE,
  UP_DOWN_MODE,
};
struct disp_atw_info {
  bool used;
  enum disp_atw_mode mode;
  unsigned b_row;
  unsigned b_col;
  int cof_fd;
};
struct disp_fb_info2 {
  int fd;
  int y8_fd;
  struct disp_rectsz size[3];
  unsigned align[3];
  enum disp_pixel_format format;
  enum disp_color_space color_space;
  int trd_right_fd;
  bool pre_multiply;
  struct disp_rect64 crop;
  enum disp_buffer_flags flags;
  enum disp_scan_flags scan;
  enum disp_eotf eotf;
  int depth;
  unsigned fbd_en;
  int metadata_fd;
  unsigned metadata_size;
  unsigned metadata_flag;
};
struct disp_layer_info2 {
  enum disp_layer_mode mode;
  unsigned char zorder;
  unsigned char alpha_mode;
  unsigned char alpha_value;
  struct disp_rect screen_win;
  bool b_trd_out;
  enum disp_3d_out_mode out_trd_mode;
  union {
    unsigned color;
    struct disp_fb_info2 fb;
  };
  unsigned id;
  struct disp_atw_info atw;
};
struct disp_layer_config2 {
  struct disp_layer_info2 info;
  bool enable;
  unsigned channel;
  unsigned layer_id;
};
static const unsigned DISP_EINK_UPDATE2 = 1030;
static const unsigned DISP_EINK_WAIT_BEFORE_LCD_INT_COMPLETE = 16402;
static const unsigned DISP_EINK_SET_UPDATE_CONTROL = 16403;
static const unsigned DISP_EINK_WAIT_FRAME_SYNC_COMPLETE = 16404;
static const unsigned DISP_EINK_SET_NTX_HANDWRITE_ONOFF = 16405;
static const unsigned DISP_EINK_SET_WAIT_MODE_ONOFF = 16406;
typedef struct {
  unsigned long u0;
  unsigned long u1;
  unsigned long u2;
  unsigned long u3;
  unsigned long u4;
  unsigned long u5;
  unsigned long u6;
} sunxi_disp_raw_ioctl;
typedef struct {
  struct area_info *area;
  unsigned long layer_num;
  unsigned long update_mode;
  struct disp_layer_config2 *lyr_cfg2;
  unsigned *frame_id;
  uint32_t *rotate;
  unsigned long cfa_use;
} sunxi_disp_eink_update2;
typedef struct {
  bool enable;
} sunxi_disp_eink_set_update_control;
typedef struct {
  uint32_t frame_id;
} sunxi_disp_eink_wait_frame_sync_complete;
typedef struct {
  bool enable;
} sunxi_disp_eink_set_ntx_handwrite_onoff;
typedef struct {
  bool enable;
} sunxi_disp_eink_set_wait_mode_onoff;
struct disp_fb_info {
  unsigned long long addr[3];
  struct disp_rectsz size[3];
  unsigned align[3];
  enum disp_pixel_format format;
  enum disp_color_space color_space;
  unsigned trd_right_addr[3];
  bool pre_multiply;
  struct disp_rect64 crop;
  enum disp_buffer_flags flags;
  enum disp_scan_flags scan;
};
struct disp_layer_info {
  enum disp_layer_mode mode;
  unsigned char zorder;
  unsigned char alpha_mode;
  unsigned char alpha_value;
  struct disp_rect screen_win;
  bool b_trd_out;
  enum disp_3d_out_mode out_trd_mode;
  union {
    unsigned color;
    struct disp_fb_info fb;
  };
  unsigned id;
};
struct disp_layer_config {
  struct disp_layer_info info;
  bool enable;
  unsigned channel;
  unsigned layer_id;
};
typedef struct {
  struct area_info *area;
  unsigned long layer_num;
  unsigned long update_mode;
  struct disp_layer_config *lyr_cfg;
  unsigned long u4;
  unsigned long rotate;
  unsigned long cfa_use;
} sunxi_disp_eink_update;
typedef struct {
  unsigned long temp;
} sunxi_disp_eink_set_temp;
typedef struct {
  unsigned long skip;
} sunxi_disp_eink_overlap_skip;
typedef struct {
  unsigned long count;
} sunxi_disp_eink_set_gc_count;
struct cfa_enable {
  bool bg_enable;
  int is_cfa;
};
typedef struct {
  struct cfa_enable cfa;
} sunxi_disp_eink_set_bg_onoff;
typedef struct {
  int screen_id;
  struct disp_layer_config2 *lyr_cfg2;
  unsigned long layer_num;
} sunxi_disp_layer_get_config2;
typedef struct {
  int screen_id;
  struct disp_layer_config *lyr_cfg;
  unsigned long layer_num;
} sunxi_disp_layer_get_config;
typedef struct {
  int screen_id;
} sunxi_disp_layer_generic_get;
typedef union {
  sunxi_disp_raw_ioctl raw;
  sunxi_disp_eink_update update;
  sunxi_disp_eink_update2 update2;
  sunxi_disp_eink_set_temp set_temp;
  sunxi_disp_eink_overlap_skip op_skip;
  sunxi_disp_eink_set_gc_count gc_cnt;
  sunxi_disp_eink_set_bg_onoff toggle_bg;
  sunxi_disp_eink_set_update_control upd_ctrl;
  sunxi_disp_eink_wait_frame_sync_complete wait_for;
  sunxi_disp_eink_set_ntx_handwrite_onoff toggle_handw;
  sunxi_disp_eink_set_wait_mode_onoff toggle_wait;
  sunxi_disp_layer_get_config get_layer;
  sunxi_disp_layer_get_config2 get_layer2;
  sunxi_disp_layer_generic_get get;
} sunxi_disp_eink_ioctl;
]]
