/*
 * Copyright 2004-2011 Freescale Semiconductor, Inc. All Rights Reserved.
 */

/*
 * The code contained herein is licensed under the GNU Lesser General
 * Public License.  You may obtain a copy of the GNU Lesser General
 * Public License Version 2.1 or later at the following locations:
 *
 * http://www.opensource.org/licenses/lgpl-license.html
 * http://www.gnu.org/copyleft/lgpl.html
 */

/*
 * @file arch-mxc/   mxcfb.h
 *
 * @brief Global header file for the MXC Frame buffer
 *
 * @ingroup Framebuffer
 */
#ifndef __ASM_ARCH_MXCFB_H__
#define __ASM_ARCH_MXCFB_H__

#include <linux/fb.h>

#define FB_SYNC_OE_LOW_ACT	0x80000000
#define FB_SYNC_CLK_LAT_FALL	0x40000000
#define FB_SYNC_DATA_INVERT	0x20000000
#define FB_SYNC_CLK_IDLE_EN	0x10000000
#define FB_SYNC_SHARP_MODE	0x08000000
#define FB_SYNC_SWAP_RGB	0x04000000

struct mxcfb_gbl_alpha {
	int enable;
	int alpha;
};

struct mxcfb_loc_alpha {
	int enable;
	int alpha_in_pixel;
	unsigned long alpha_phy_addr0;
	unsigned long alpha_phy_addr1;
};

struct mxcfb_color_key {
	int enable;
	__u32 color_key;
};

struct mxcfb_pos {
	__u16 x;
	__u16 y;
};

struct mxcfb_gamma {
	int enable;
	int constk[16];
	int slopek[16];
};

struct mxcfb_rect {
	__u32 top;
	__u32 left;
	__u32 width;
	__u32 height;
};

#define GRAYSCALE_8BIT				0x1
#define GRAYSCALE_8BIT_INVERTED			0x2

#define AUTO_UPDATE_MODE_REGION_MODE		0
#define AUTO_UPDATE_MODE_AUTOMATIC_MODE		1

#define UPDATE_SCHEME_SNAPSHOT			0
#define UPDATE_SCHEME_QUEUE			1
#define UPDATE_SCHEME_QUEUE_AND_MERGE		2

#define UPDATE_MODE_PARTIAL			0x0
#define UPDATE_MODE_FULL			0x1

#define WAVEFORM_MODE_AUTO			257

#define TEMP_USE_AMBIENT			0x1000
#define TEMP_USE_AUTO				0x1001

#define EPDC_FLAG_ENABLE_INVERSION		0x01
#define EPDC_FLAG_FORCE_MONOCHROME		0x02
#define EPDC_FLAG_USE_ALT_BUFFER		0x100

#define EPDC_FLAG_SP1_1				0x10000
#define EPDC_FLAG_SP1_2				0x20000

#define FB_POWERDOWN_DISABLE			-1

/* 2011/03/30 FY11 : Defined max marker value for user process. */
/*                   (The value larger than this is for driver.)*/
#define UPDATE_MARKER_MAX			0x80000000

struct mxcfb_alt_buffer_data {
	void *virt_addr;
	__u32 phys_addr;
	__u32 width;	/* width of entire buffer */
	__u32 height;	/* height of entire buffer */
	struct mxcfb_rect alt_update_region;	/* region within buffer to update */
};

struct mxcfb_update_data {
	struct mxcfb_rect update_region;
	__u32 waveform_mode;
	__u32 update_mode;
	__u32 update_marker;
	int temp;
	uint flags;
	struct mxcfb_alt_buffer_data alt_buffer_data;
};

/*
 * Structure used to define waveform modes for driver
 * Needed for driver to perform auto-waveform selection
 */
struct mxcfb_waveform_modes {
	int mode_init;
	int mode_du;
	int mode_gc4;
	int mode_gc8;
	int mode_gc16;
	int mode_gc32;
	int mode_a2;	/* 2011/03/05 FY11 : Supported A2 mode limitations. */
};


/* 2011/2/24 FY11 : Added waveform version struct. */
#define WF_VER_LEN	10
struct mxcfb_waveform_version {
	__u8 version[WF_VER_LEN];
};


/* 2011/03/08 FY11 : Supported to write waveform. */
struct mxcfb_waveform_data
{
	__u32 uiSize;
	__u8 *pcData;
};


#define MXCFB_WAIT_FOR_VSYNC	_IOW('F', 0x20, u_int32_t)
#define MXCFB_SET_GBL_ALPHA     _IOW('F', 0x21, struct mxcfb_gbl_alpha)
#define MXCFB_SET_CLR_KEY       _IOW('F', 0x22, struct mxcfb_color_key)
#define MXCFB_SET_OVERLAY_POS   _IOWR('F', 0x24, struct mxcfb_pos)
#define MXCFB_GET_FB_IPU_CHAN 	_IOR('F', 0x25, u_int32_t)
#define MXCFB_SET_LOC_ALPHA     _IOWR('F', 0x26, struct mxcfb_loc_alpha)
#define MXCFB_SET_LOC_ALP_BUF    _IOW('F', 0x27, unsigned long)
#define MXCFB_SET_GAMMA	       _IOW('F', 0x28, struct mxcfb_gamma)
#define MXCFB_GET_FB_IPU_DI 	_IOR('F', 0x29, u_int32_t)
#define MXCFB_GET_DIFMT	       _IOR('F', 0x2A, u_int32_t)
#define MXCFB_GET_FB_BLANK     _IOR('F', 0x2B, u_int32_t)
#define MXCFB_SET_DIFMT		_IOW('F', 0x2C, u_int32_t)

/* IOCTLs for E-ink panel updates */
#define MXCFB_SET_WAVEFORM_MODES	_IOW('F', 0x2B, struct mxcfb_waveform_modes)
#define MXCFB_SET_TEMPERATURE		_IOW('F', 0x2C, int32_t)
#define MXCFB_SET_AUTO_UPDATE_MODE	_IOW('F', 0x2D, __u32)
#define MXCFB_SEND_UPDATE		_IOW('F', 0x2E, struct mxcfb_update_data)
#define MXCFB_WAIT_FOR_UPDATE_COMPLETE	_IOW('F', 0x2F, __u32)
#define MXCFB_SET_PWRDOWN_DELAY		_IOW('F', 0x30, int32_t)
#define MXCFB_GET_PWRDOWN_DELAY		_IOR('F', 0x31, int32_t)
#define MXCFB_SET_UPDATE_SCHEME		_IOW('F', 0x32, __u32)
#define MXCFB_GET_PMIC_TEMPERATURE	_IOR('F', 0x33, int32_t)
#define MXCFB_SET_BORDER_MODE		_IOR('F', 0x34, int32_t)
#define MXCFB_SET_EPD_PWR0_CTRL		_IOR('F', 0x35, int32_t)
#define MXCFB_SET_EPD_PWR2_CTRL		_IOR('F', 0x36, int32_t)

/* 2011/1/19 FY11 : Added commands to read/write VCOM. */
#define MXCFB_SET_VCOM			_IOW('F', 0x37, __u32)
#define MXCFB_GET_VCOM			_IOR('F', 0x38, __u32)

/* 2011/2/24 FY11 : Added commands to read waveform version. */
#define MXCFB_GET_WF_VERSION		_IOR('F', 0x39, struct mxcfb_waveform_version)
/* 2011/03/08 FY11 : Supported to write waveform. */
#define MXCFB_WRITE_WF			_IOW('F', 0x3A, struct mxcfb_waveform_data)
/* 2011/03/30 FY11 : Supported to write standby screen image. */
#define MXCFB_WRITE_SSCREEN		_IOW('F', 0x3B, __u8*)
/* 2011/04/12 FY11 : Supported to write panel init flag. */
#define MXCFB_SET_PANELINIT		_IOW('F', 0x3C, __u8)

/* 2012/02/03 : Add pending function. */
#define MXCFB_SET_PENDING       _IOW('F', 0x3E, __u8)

#ifdef __KERNEL__

extern struct fb_videomode mxcfb_modedb[];
extern int mxcfb_modedb_sz;

enum {
	MXCFB_REFRESH_OFF,
	MXCFB_REFRESH_AUTO,
	MXCFB_REFRESH_PARTIAL,
};

int mxcfb_set_refresh_mode(struct fb_info *fbi, int mode,
			   struct mxcfb_rect *update_region);

int mxc_elcdif_frame_addr_setup(dma_addr_t phys);

#endif				/* __KERNEL__ */
#endif
