/*
 * Copyright 2004-2013 Freescale Semiconductor, Inc. All Rights Reserved.
 *
 * Unified header for BQ Cervantes/Fnac Touchlight devices.
 * https://github.com/bq/cervantes-qt/tree/eink-imx508/src/plugins/gfxdrivers/einkfb
 *
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

#define UPDATE_MODE_PARTIAL		0x0
#define UPDATE_MODE_FULL		0x1

#define WAVEFORM_MODE_AUTO		257

#define TEMP_USE_AMBIENT		0x1000

/* from https://github.com/bq/cervantes-qt/blob/eink-imx508/src/plugins/gfxdrivers/einkfb/einkfb.cpp */
#define WAVEFORM_MODE_INIT		0	/* init mode, turn the screen white */
#define WAVEFORM_MODE_DU		1	/* fast 1bit update without flashing */
#define WAVEFORM_MODE_GC16		2	/* High fidelity (flashing) */
#define WAVEFORM_MODE_A2		4	/* Fast page flipping at reduced contrast */

/* new waveform modes introduced in Cervantes 2013 (from drivers/video/mxc/mxc_epdc_fb.c */
#define WAVEFORM_MODE_GL16		5	/* High fidelity from white transition */
#define WAVEFORM_MODE_GLR16		6	/* Ghost compensation waveform */
#define WAVEFORM_MODE_GLD16		7	/* Ghost compensation waveform with dithering */

#define EPDC_FLAG_ENABLE_INVERSION      0x01
#define EPDC_FLAG_FORCE_MONOCHROME      0x02
#define EPDC_FLAG_USE_ALT_BUFFER        0x100

struct mxcfb_rect {
        __u32 top;
        __u32 left;
        __u32 width;
        __u32 height;
};

struct mxcfb_alt_buffer_data {
	void *virt_addr;
	__u32 phys_addr;
	__u32 width;	/* width of entire buffer */
	__u32 height;	/* height of entire buffer */
	struct mxcfb_rect alt_update_region; /* region within buffer to update */
};

struct mxcfb_update_data {
        struct mxcfb_rect update_region;
        __u32 waveform_mode;
        __u32 update_mode;
        __u32 update_marker;
        int temp;
        unsigned int flags;
        struct mxcfb_alt_buffer_data alt_buffer_data;
};

/* IOCTLs for E-ink panel updates */
#define MXCFB_SEND_UPDATE		_IOW('F', 0x2E, struct mxcfb_update_data)
#define MXCFB_WAIT_FOR_UPDATE_COMPLETE	_IOW('F', 0x2F, __u32)

#endif
