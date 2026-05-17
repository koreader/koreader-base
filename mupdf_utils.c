#include "mupdf_utils.h"
#include <mupdf/fitz.h>

typedef struct
{
    fz_device super;
    fz_device *default_device;
} isolated_smask_device;

static void smask_fill_image(fz_context *ctx, fz_device *dev, fz_image *img, fz_matrix ctm, float alpha, fz_color_params color_params)
{
    isolated_smask_device *smask_dev = (isolated_smask_device*)dev;
    if (img->mask)
    {
        float black[1] = { 0.0f };
        fz_fill_image_mask(ctx, smask_dev->default_device, img->mask, ctm,
                           fz_device_gray(ctx), black, alpha, color_params);
    }
}

fz_device *fz_new_isolated_smask_device(fz_context *ctx, fz_device *dev)
{
    isolated_smask_device *smask_dev = fz_new_derived_device(ctx, isolated_smask_device);
    smask_dev->default_device = dev;
    smask_dev->super.fill_image = smask_fill_image;
    return (fz_device *)smask_dev;
}