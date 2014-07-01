--[[
converting pdf page to willus bmp
--]]

local ffi = require("ffi")
local dummy = require("ffi/mupdf_h")
local dummy = require("ffi/koptcontext_h")
local mupdf = ffi.load("libs/libmupdf.so")
local k2pdfopt = ffi.load("libs/libk2pdfopt.so.2")

local Bitmap = {}

function Bitmap:pixmap_to_bmp(bmp, ctx, pixmap)
    bmp.width = mupdf.fz_pixmap_width(ctx, pixmap)
    bmp.height = mupdf.fz_pixmap_height(ctx, pixmap)
    local ncomp = mupdf.fz_pixmap_components(ctx, pixmap)
    if ncomp ~= 2 and ncomp ~= 4 then return -1 end
    bmp.bpp = ncomp == 2 and 8 or 24
    k2pdfopt.bmp_alloc(bmp)
    if ncomp == 2 then
        for i=0, 255 do
            bmp.red[i] = i
            bmp.green[i] = i
            bmp.blue[i] = i
        end
    end
    local p = mupdf.fz_pixmap_samples(ctx, pixmap)
    if ncomp == 2 then
        for row=0, bmp.height - 1 do
            local dest = k2pdfopt.bmp_rowptr_from_top(bmp, row)
            for col=0, bmp.width - 1 do
                dest[0] = p[0]
                dest = dest + 1
                p = p + 2
            end
        end
    end
    return 0
end

function Bitmap:pdffile_to_bmp(bmp, filename, pageno, dpi, bpp)
	local ctx = mupdf.fz_new_context_imp(nil, nil, bit.lshift(8, 20), "1.4")
    if ctx == nil then return -1 end
    mupdf.fz_register_document_handlers(ctx)
    local colorspace = bpp == 8 and mupdf.fz_device_gray(ctx) or mupdf.fz_device_rgb(ctx)
    local doc = mupdf.fz_open_document(ctx, filename)
    if mupdf.fz_count_pages(doc) < pageno or pageno < 1 then
        return -1
    end
    local page = mupdf.fz_load_page(doc, pageno-1)
    local ctm = ffi.new("fz_matrix[1]")[0]
    local bbox = ffi.new("fz_irect[1]")[0]
    local bounds = ffi.new("fz_rect[1]")[0]
    mupdf.fz_bound_page(doc, page, bounds)
    mupdf.fz_scale(ctm, dpi/72, dpi/72)
    mupdf.fz_transform_rect(bounds, ctm)
    mupdf.fz_round_rect(bbox, bounds)
    local pix = mupdf.fz_new_pixmap_with_bbox(ctx, colorspace, bbox)
    mupdf.fz_clear_pixmap_with_value(ctx, pix, 0xFF)
    local dev = mupdf.fz_new_draw_device(ctx, pix)
    mupdf.fz_run_page(doc, page, dev, ctm, nil)
    mupdf.fz_free_device(dev)
    if self:pixmap_to_bmp(bmp, ctx, pix) ~= 0 then return -1 end
    mupdf.fz_drop_pixmap(ctx, pix)
    mupdf.fz_free_page(doc, page)
    mupdf.fz_close_document(doc)
    mupdf.fz_free_context(ctx)

    return 0
end

return Bitmap
