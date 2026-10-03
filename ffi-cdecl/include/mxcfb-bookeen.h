#ifndef __BOOKEEN_MXCFB_H__
#define __BOOKEEN_MXCFB_H__

#include <linux/fb.h>

struct bookeen_region_t {
  __u32 x_start;
  __u32 x_end;
  __u32 y_start;
  __u32 y_end;
};

// Based on Bookeen linux kernel sources;
// The uX fields mean different things in different contexts.
// All IOCTLs use this structure.
// I think we ALWAYS have to pass it even if some fields are unused
// because the handler actually reads each field.
struct mxcfb_update_data_bookeen {
  __u32 u0;  // usually `sel` = 0
  __u32 u1;  // usually a flag
  __u32 u2;
  __u32 u3;
  struct bookeen_region_t update_region;
};

#define UPDATE_MODE_PARTIAL			0x0
#define UPDATE_MODE_FULL			0x1

// From __eink_update_mode enum
#define	EINK_DU_MODE			 0x02
#define	EINK_GC16_MODE			 0x04  // Full refresh
#define	EINK_GC4_MODE			 0x08
#define	EINK_A2_MODE			 0x10
#define	EINK_SHORT_GC16_LOCAL_MODE 	 0x20
#define	EINK_SHORT_DU_MODE		 0x40
#define	EINK_LOCAL_MODE			 0x80  // Partial refresh
#define	EINK_A2_OUT_MODE		 0x100
#define	EINK_DITHERING_MODE		 0x200
#define	EINK_RECTANGLE_MODE		 0x400
#define	EINK_A2_IN_MODE			 0x800

// Codes from vendor kernel's __disp_cmd_t enum (drv_display_sun4i.h).
// Keep the kernel's spelling; disp_ioctl expects these bare command numbers
// (not _IOC-encoded). Handler reads a fixed 8-long structure.
#define DISP_CMD_EINK_INIT			0x400
#define DISP_CMD_EINK_UNINIT			0x401
#define DISP_CMD_EINK_UPDATE			0x402
#define DISP_CMD_EINK_SET_MODE			0x403
#define DISP_CMD_EINK_SET_TEMPERATURE		0x404
#define DISP_CMD_EINK_GET_UPDATE_STATUS		0x405
#define DISP_CMD_SET_3V3			0x407

#endif
