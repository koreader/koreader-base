#ifndef MUPDF_UTILS_H
#define MUPDF_UTILS_H

typedef struct fz_device fz_device;
typedef struct fz_context fz_context;
typedef struct fz_page fz_page;

/**
	Create a device to draw an isolated soft mask on a pixmap.

	dev: Default draw device
*/
fz_device* fz_new_isolated_smask_device(fz_context* ctx, fz_device* dev);

#endif