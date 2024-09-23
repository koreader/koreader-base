--[[--
Leptonica cheatsheet:
    -- Data structures:
    PIX -- basic data structure - stores image
    BOX -- stores rectangle (x, y, w, h)
    BOXA -- array of BOX
    NUMA -- array of numbers

    -- Functions:
    -- note that all of them take/return pointers, or null/nil on failure

    pixDestroy(pix) -- free memory from PIX
    boxDestroy(box) -- free memory from BOX
    selDestroy(sel) -- free memory from SEL
    boxaDestroy(boxa) -- free memory from BOXA
    numaGetIValue(nai, counter_w, counter_l) -- returns int value from NUMA
    pixGetWidth(pix) -- return pix width
    pixGetHeight(pix) -- return pix height
    pixConvertTo32(pix) -- converts pix to 32bpp
    boxaCombineOverlaps(boxa) -- return intersection of all box in a boxa
    boxCreate(x, y, w, h) -- create box with given dimensions
    boxaGetCount(boxa) -- get number of elements in boxa array

    -- get element from BOXA flag can be C.L_COPY (creates new copy) or
    -- C.L_CLONE (returns ref-counted handle)
    boxaGetBox(boxa, index, flag)

    -- add box to boxa array, flag can be C.L_INSERT, or C.L_COPY
    boxaAddBox(boxa, box, flag)

    -- adjust box's size by given deltas and write it to boxd
    boxAdjustSides(boxd, boxs, d_left, d_right, d_top, d_bottom)

    -- returns boxa where each element intersects with box,
    -- or is removed if it doesn't intersect
    boxaClipToBox(boxa, box)

    -- returns intersection of both box, or null if they don't intersect
    boxOverlapRegion(box, box)

    -- returns new black-white PIX,
    -- if the source pixel is < threshold,
    -- resulting pixel is 1 (black),
    -- otherwise 0 (white)
    pixThresholdToBinary(pix, threshold)

    -- returns 0 on success and 1 on failure, output_* are PIX
    pixGetRegionsBinary(input_pix,
                        output_halftonemask,
                        output_textline_mask,
                        output_textblock_mask,
                        debug)

    -- draw boxa elements in random color with given width
    pixDrawBoxaRandom(pix, boxa, width)

    -- creates png from pix, useful for debugging
    pixWritePng(path, pix, gamma)

    -- multiplies box part of pixs by color and writes it to pixd
    pixMultiplyByColor(pixd, pixs, box, color)

    -- converts float_array to NUMA, flag is either C.L_INSERT or C.L_COPY
    numaCreateFromFArray(float_array, size, flag)

@module ffi.koptcontext
]]

local ffi = require("ffi")
local C = ffi.C

require("ffi/koptcontext_h")
require("ffi/leptonica_h")
local Blitbuffer = require("ffi/blitbuffer")
local leptonica = ffi.loadlib("leptonica", "6")
local k2pdfopt = ffi.loadlib("k2pdfopt", "2")

local KOPTContext = {
    k2pdfopt = k2pdfopt -- offer the libraries' functions to other users
}
local KOPTContext_mt = {__index={}}

local __VERSION__ = "1.0.1"

local function _gc_ptr(p, destructor)
    return p and ffi.gc(p, destructor)
end

local function boxDestroy(box)
    leptonica.boxDestroy(ffi.new('BOX *[1]', box))
    ffi.gc(box, nil)
end

local function boxCreate(...)
    return _gc_ptr(leptonica.boxCreate(...), boxDestroy)
end

local function boxGetGeometry(box)
    local geo = ffi.new('l_int32[4]')
    leptonica.boxGetGeometry(box, geo, geo + 1, geo + 2, geo + 3)
    return tonumber(geo[0]), tonumber(geo[1]), tonumber(geo[2]), tonumber(geo[3])
end

local function boxaDestroy(boxa)
    leptonica.boxaDestroy(ffi.new('BOXA *[1]', boxa))
    ffi.gc(boxa, nil)
end

local function boxaIterBoxes(boxa, count)
    count = count or leptonica.boxaGetCount(boxa)
    local index = 0
    return function ()
        if index < count then
            local box = _gc_ptr(leptonica.boxaGetBox(boxa, index, leptonica.L_CLONE), boxDestroy)
            index = index + 1
            return box
        end
    end
end

local function boxaIterBoxGeometries(boxa)
    local count = leptonica.boxaGetCount(boxa)
    local geo = ffi.new('l_int32[4]')
    local index = 0
    return function ()
        if index < count then
            leptonica.boxaGetBoxGeometry(boxa, index, geo, geo + 1, geo + 2, geo + 3)
            index = index + 1
            return tonumber(geo[0]), tonumber(geo[1]), tonumber(geo[2]), tonumber(geo[3])
        end
    end
end

local function boxa_to_table(boxa)
    local boxes = {}
    for box_x, box_y, box_w, box_h in boxaIterBoxGeometries(boxa) do
        table.insert(boxes, {box_x, box_y, box_w, box_h})
    end
    return boxes
end

local function boxa_from_table(t)
    local rboxa = leptonica.boxaCreate(#t)
    for i, box in ipairs(t) do
        leptonica.boxaAddBox(rboxa, leptonica.boxCreate(table.unpack(box)), leptonica.L_NOCOPY)
    end
    return rboxa
end

local function pixDestroy(pix)
    leptonica.pixDestroy(ffi.new('PIX *[1]', pix))
    ffi.gc(pix, nil)
end

local function bitmap2pix(...)
    return _gc_ptr(k2pdfopt.bitmap2pix(...), pixDestroy)
end

local function numaDestroy(numa)
    leptonica.numaDestroy(ffi.new('NUMA *[1]', numa))
    ffi.gc(numa, nil)
end

local function numa_to_string(numa)
    local count = leptonica.numaGetCount(numa)
    if count == 0 then
        return
    end
    return ffi.string(leptonica.numaGetFArray(numa, leptonica.L_NOCOPY), 4 * count)
end

local function numa_from_string(s)
    return leptonica.numaCreateFromFArray(ffi.cast("l_float32*", s), #s / 4, leptonica.L_COPY)
end

function KOPTContext_mt.__index:setBBox(x0, y0, x1, y1)
    self.bbox.x0, self.bbox.y0, self.bbox.x1, self.bbox.y1 = x0, y0, x1, y1
end
function KOPTContext_mt.__index:setTrim(trim) self.trim = trim end
function KOPTContext_mt.__index:setWrap(wrap) self.wrap = wrap end
function KOPTContext_mt.__index:setWhite(white) self.white = white end
function KOPTContext_mt.__index:setIndent(indent) self.indent = indent end
function KOPTContext_mt.__index:setRotate(rotate) self.rotate = rotate end
function KOPTContext_mt.__index:setColumns(columns) self.columns = columns end
function KOPTContext_mt.__index:setDeviceDim(w, h) self.dev_width, self.dev_height = w, h end
function KOPTContext_mt.__index:setDeviceDPI(dpi) self.dev_dpi = dpi end
function KOPTContext_mt.__index:setStraighten(straighten) self.straighten = straighten end
function KOPTContext_mt.__index:setJustification(justification) self.justification = justification end
function KOPTContext_mt.__index:setWritingDirection(direction) self.writing_direction = direction end
function KOPTContext_mt.__index:setMargin(margin) self.margin = margin end
function KOPTContext_mt.__index:setZoom(zoom) self.zoom = zoom end
function KOPTContext_mt.__index:setQuality(quality) self.quality = quality end
function KOPTContext_mt.__index:setContrast(contrast) self.contrast = contrast end
function KOPTContext_mt.__index:setDefectSize(defect_size) self.defect_size = defect_size end
function KOPTContext_mt.__index:setLineSpacing(line_spacing) self.line_spacing = line_spacing end
function KOPTContext_mt.__index:setWordSpacing(word_spacing) self.word_spacing = word_spacing end
function KOPTContext_mt.__index:setLanguage(language)
    if self.language then
        C.free(self.language)
        self.language = nil
    end
    if language then
        -- As `self` is a struct, and `self.language` a `char *`,
        -- we need to make a C copy of the language string.
        self.language = C.strdup(language)
    end
end

function KOPTContext_mt.__index:setDebug() self.debug = 1 end
function KOPTContext_mt.__index:setCJKChar() self.cjkchar = 1 end
function KOPTContext_mt.__index:setPreCache() self.precache = 1 end

function KOPTContext_mt.__index:getTrim() return self.trim end
function KOPTContext_mt.__index:getZoom() return self.zoom end
function KOPTContext_mt.__index:getWrap() return self.wrap end
function KOPTContext_mt.__index:isPreCache() return self.precache end
function KOPTContext_mt.__index:getLanguage() return ffi.string(self.language) end
function KOPTContext_mt.__index:getPageDim() return self.page_width, self.page_height end
function KOPTContext_mt.__index:getBBox(x0, y0, x1, y1) return self.bbox.x0, self.bbox.y0, self.bbox.x1, self.bbox.y1 end

function KOPTContext_mt.__index:copyDestBMP(src)
    if src.dst.bpp == 8 or src.dst.bpp == 24 or src.dst.bpp == 32 then
        k2pdfopt.bmp_copy(self.dst, src.dst)
    end
end

function KOPTContext_mt.__index:dstToBlitBuffer()
    local bb
    if self.dst.bpp == 8 then
        bb = Blitbuffer.new(self.dst.width, self.dst.height, Blitbuffer.TYPE_BB8, self.dst.data):copy()
    elseif self.dst.bpp == 24 then
        bb = Blitbuffer.new(self.dst.width, self.dst.height, Blitbuffer.TYPE_BBRGB24, self.dst.data):copy()
    elseif self.dst.bpp == 32 then
        bb = Blitbuffer.new(self.dst.width, self.dst.height, Blitbuffer.TYPE_BBRGB32, self.dst.data):copy()
    end
    return bb
end

function KOPTContext_mt.__index:getWordBoxes(bmp, x, y, w, h, box_type)
    local boxa
    local nai

    if box_type == 0 then
        k2pdfopt.k2pdfopt_get_reflowed_word_boxes(self,
            bmp == "src" and self.src or self.dst, x, y, w, h)
        boxa = self.rboxa
        nai = self.rnai
    elseif box_type == 1 then
        k2pdfopt.k2pdfopt_get_native_word_boxes(self,
            bmp == "src" and self.src or self.dst, x, y, w, h)
        boxa = self.nboxa
        nai = self.nnai
    end

    if boxa == nil or nai == nil then return end

    -- get number of words in this area
    local nr_word = leptonica.boxaGetCount(boxa)
    assert(nr_word == leptonica.numaGetCount(nai))

    local boxes = {}
    local lbox, current_line
    local counter_w = 0
    local l_x0, l_y0, l_x1, l_y1
    local counter_l = ffi.new("int[1]")

    for box_x, box_y, box_w, box_h in boxaIterBoxGeometries(boxa) do
        leptonica.numaGetIValue(nai, counter_w, counter_l)
        if current_line ~= counter_l[0] then
            if lbox then
                -- box for the whole line
                lbox.x0, lbox.y0, lbox.x1, lbox.y1 = l_x0, l_y0, l_x1, l_y1
            end
            l_x0, l_y0, l_x1, l_y1 = 9999, 9999, 0, 0
            current_line = counter_l[0]
            lbox = {}
            table.insert(boxes, lbox)
        end
        l_x0 = box_x < l_x0 and box_x or l_x0
        l_y0 = box_y < l_y0 and box_y or l_y0
        l_x1 = box_x + box_w > l_x1 and box_x + box_w or l_x1
        l_y1 = box_y + box_h > l_y1 and box_y + box_h or l_y1
        -- box for a single word
        table.insert(lbox, {
            x0 = box_x, y0 = box_y,
            x1 = box_x + box_w,
            y1 = box_y + box_h,
        })
        counter_w = counter_w + 1
    end

    if lbox then
        -- box for the whole line
        lbox.x0, lbox.y0, lbox.x1, lbox.y1 = l_x0, l_y0, l_x1, l_y1
    end

    return boxes, nr_word
end

function KOPTContext_mt.__index:getReflowedWordBoxes(bmp, x, y, w, h)
    return self:getWordBoxes(bmp, x, y, w, h, 0)
end

function KOPTContext_mt.__index:getNativeWordBoxes(bmp, x, y, w, h)
    return self:getWordBoxes(bmp, x, y, w, h, 1)
end

function KOPTContext_mt.__index:reflowToNativePosTransform(xc, yc, wr, hr)
    local function wrectmap_reflow_distance(wrmap, x, y)
        local function wrectmap_reflow_inside(wrmap_inside, x_inside, y_inside)
            return k2pdfopt.wrectmap_inside(wrmap_inside, x_inside, y_inside) ~= 0
        end
        if wrectmap_reflow_inside(wrmap, x, y) then
            return 0
        else
            local x0, y0 = x, y
            local x1 = wrmap.coords[1].x + wrmap.coords[2].x / 2
            local y1 = wrmap.coords[1].y + wrmap.coords[2].y / 2
            return (x0 - x1)*(x0 - x1) + (y0 - y1)*(y0 - y1)
        end
    end

    local m = 0
    for i = 0, self.rectmaps.n - 1 do
        if wrectmap_reflow_distance(self.rectmaps.wrectmap + m, xc, yc) >
            wrectmap_reflow_distance(self.rectmaps.wrectmap + i, xc, yc) then
            m = i
        end
    end
    if self.rectmaps.n > m then
        local rectmap = self.rectmaps.wrectmap + m
        local x = rectmap.coords[0].x*self.dev_dpi*self.quality/rectmap.srcdpiw
        local y = rectmap.coords[0].y*self.dev_dpi*self.quality/rectmap.srcdpih
        local w = rectmap.coords[2].x*self.dev_dpi*self.quality/rectmap.srcdpiw
        local h = rectmap.coords[2].y*self.dev_dpi*self.quality/rectmap.srcdpih
        return (x+w*wr)/self.zoom+self.bbox.x0, (y+h*hr)/self.zoom+self.bbox.y0
    end
end

function KOPTContext_mt.__index:nativeToReflowPosTransform(xc, yc)
    local function wrectmap_native_distance(wrmap, x0, y0)
        local x = wrmap.coords[0].x*self.dev_dpi*self.quality/wrmap.srcdpiw
        local y = wrmap.coords[0].y*self.dev_dpi*self.quality/wrmap.srcdpih
        local w = wrmap.coords[2].x*self.dev_dpi*self.quality/wrmap.srcdpiw
        local h = wrmap.coords[2].y*self.dev_dpi*self.quality/wrmap.srcdpih
        local function wrectmap_native_inside(wrmap_inside, x0_inside, y0_inside)
            return x <= x0_inside and y <= y0_inside
                    and x + w >= x0_inside
                    and y + h >= y0_inside
        end
        if wrectmap_native_inside(wrmap, x0, y0) then
            return 0
        else
            local x1, y1 = x + w/2, y + h/2
            return (x0 - x1)*(x0 - x1) + (y0 - y1)*(y0 - y1)
        end
    end

    local m = 0
    local x0, y0 = (xc - self.bbox.x0) * self.zoom, (yc - self.bbox.y0) * self.zoom
    for i = 0, self.rectmaps.n - 1 do
        if wrectmap_native_distance(self.rectmaps.wrectmap + m, x0, y0) >
            wrectmap_native_distance(self.rectmaps.wrectmap + i, x0, y0) then
            m = i
        end
    end
    local rectmap = self.rectmaps.wrectmap + m
    return rectmap.coords[1].x + rectmap.coords[2].x/2, rectmap.coords[1].y + rectmap.coords[2].y/2
end

function KOPTContext_mt.__index:getTOCRWord(bmp, x, y, w, h, datadir, lang, ocr_type, allow_spaces, std_proc, dpi)
    local word = ffi.new("char[256]")
    local err = k2pdfopt.k2pdfopt_tocr_single_word(bmp == "src" and self.src or self.dst,
        x, y, w, h, dpi or self.dev_dpi, word, 256, ffi.cast("char*", datadir), ffi.cast("char*", lang),
        ocr_type, allow_spaces, std_proc)
    return err == 0 and ffi.string(word) or nil
end

function KOPTContext_mt.__index:getAutoBBox()
    -- fall back to default writing direction when detecting bbox
    self:setWritingDirection(0)
    k2pdfopt.k2pdfopt_crop_bmp(self)
    local x0 = self.bbox.x0/self.zoom
    local y0 = self.bbox.y0/self.zoom
    local x1 = self.bbox.x1/self.zoom
    local y1 = self.bbox.y1/self.zoom
    return x0, y0, x1, y1
end

function KOPTContext_mt.__index:findPageBlocks()
    if self.src.data then
        local pixs = bitmap2pix(self.src, 0, 0, self.src.width, self.src.height)
        local pixr = _gc_ptr(leptonica.pixThresholdToBinary(pixs, 128), pixDestroy)
        local pixtb = ffi.new("PIX *[1]")
        local status = leptonica.pixGetRegionsBinary(pixr, nil, nil, pixtb, nil)
        pixtb = _gc_ptr(pixtb[0], pixDestroy)
        if status == 0 then
            assert(self.nboxa == nil and self.rboxa == nil)
            self.nboxa = leptonica.pixSplitIntoBoxa(pixtb, 5, 10, 20, 80, 10, 0)
            for box in boxaIterBoxes(self.nboxa) do
                leptonica.boxAdjustSides(box, box, -1, 0, -1, 0)
            end
            self.rboxa = leptonica.boxaCombineOverlaps(self.nboxa, nil)
            self.page_width = leptonica.pixGetWidth(pixr)
            self.page_height = leptonica.pixGetHeight(pixr)
            -- uncomment this to show text blocks in situ
            --leptonica.pixWritePng("textblock-mask.png", pixtb, 0.0)
        end
    end
end

function KOPTContext_mt.__index:getPanelFromPage(pos)
    local function isInRect(x, y, w, h, pos_x, pos_y)
        return x < pos_x and y < pos_y and x + w > pos_x and y + h > pos_y
    end

    if self.src.data then
        local pixs = bitmap2pix(self.src, 0, 0, self.src.width, self.src.height)
        local pixg
        if leptonica.pixGetDepth(pixs) == 32 then
            pixg = leptonica.pixConvertRGBToGrayFast(pixs)
        else
            pixg = leptonica.pixClone(pixs)
        end
        pixg = _gc_ptr(pixg, pixDestroy)

        -- leptonica's threshold gets pixels lighter than X, we want to get
        -- pixels darker than X, to do that we invert the image, threshold it,
        -- and invert the result back. Math: ~(~img < X) <=> img > X
        local pix_inverted = _gc_ptr(leptonica.pixInvert(nil, pixg), pixDestroy)
        local pix_thresholded = _gc_ptr(leptonica.pixThresholdToBinary(pix_inverted, 50), pixDestroy)
        leptonica.pixInvert(pix_thresholded, pix_thresholded)

        -- find connected components (in our case panels)
        local bb = _gc_ptr(leptonica.pixConnCompBB(pix_thresholded, 8), boxaDestroy)

        local img_w = leptonica.pixGetWidth(pixs)
        local img_h = leptonica.pixGetHeight(pixs)
        local res

        for box in boxaIterBoxes(bb) do
            local pix_tmp = _gc_ptr(leptonica.pixClipRectangle(pixs, box, nil), pixDestroy)
            local w = leptonica.pixGetWidth(pix_tmp)
            local h = leptonica.pixGetHeight(pix_tmp)
            -- check if it's panel or part of the panel, if it's part of the panel skip
            if w >= img_w / 8 and h >= img_h / 8 then
                local box_x, box_y, box_w, box_h = boxGetGeometry(box)
                if isInRect(box_x, box_y, box_w, box_h, pos.x, pos.y) then
                    res = {
                        x = box_x,
                        y = box_y,
                        w = box_w,
                        h = box_h,
                    }
                    break -- we found panel, exit the loop and clean up memory
                end
            end
        end
        return res
    end
end

--[[
-- get page block in location x, y both of which in range [0, 1] relative to page
-- width and height respectively
--]]
function KOPTContext_mt.__index:getPageBlock(x_rel, y_rel)
    local block = nil
    if self.src.data and self.nboxa ~= nil and self.rboxa ~= nil then
        local w, h = self:getPageDim()
        local tbox = boxCreate(0, y_rel * h, w, 2)
        local boxa = _gc_ptr(leptonica.boxaClipToBox(self.nboxa, tbox), boxaDestroy)
        for box in boxaIterBoxes(boxa) do
            leptonica.boxAdjustSides(box, box, -1, 0, -1, 0)
        end
        local boxatb = _gc_ptr(leptonica.boxaCombineOverlaps(boxa, nil), boxaDestroy)
        local clipped_box, unclipped_box
        for box_x, box_y, box_w, box_h in boxaIterBoxGeometries(boxatb) do
            if box_x / w <= x_rel and (box_x + box_w) / w >= x_rel then
                clipped_box = boxCreate(box_x, 0, box_w, h)
                if clipped_box ~= nil then break end
            end
        end
        for box_x, box_y, box_w, box_h in boxaIterBoxGeometries(self.rboxa) do
            if box_x / w <= x_rel and (box_x + box_w) / w >= x_rel
                and box_y / h <= y_rel and (box_y + box_h) / h >= y_rel then
                unclipped_box = boxCreate(box_x, box_y, box_w, box_h)
                if unclipped_box ~= nil then break end
            end
        end
        if clipped_box ~= nil and unclipped_box ~= nil then
            local box = _gc_ptr(leptonica.boxOverlapRegion(clipped_box, unclipped_box), boxDestroy)
            if box ~= nil then
                local box_x, box_y, box_w, box_h = boxGetGeometry(box)
                block = {
                    x0 = box_x / w, y0 = box_y / h,
                    x1 = (box_x + box_w) / w,
                    y1 = (box_y + box_h) / h,
                }
            end
        end

        -- uncomment this to show text blocks in situ
        --[[
        if block then
            local w, h = self.src.width, self.src.height
            local box = boxCreate(block.x0*w, block.y0*h,
                (block.x1-block.x0)*w, (block.y1-block.y0)*h)
            local boxa = _gc_ptr(leptonica.boxaCreate(1), boxaDestroy)
            leptonica.boxaAddBox(boxa, box, C.L_COPY)
            local pixs = bitmap2pix(self.src,
                0, 0, self.src.width, self.src.height)
            local pixc = _gc_ptr(pixDrawBoxaRandom(pixs, boxa, 8), pixDestroy)
            leptonica.pixWritePng("textblock.png", pixc, 0.0)
        end
        --]]
    end

    return block
end

--[[
-- draw highlights into pix and return leptonica pixmap
--]]
function KOPTContext_mt.__index:getSrcPix(pboxes, drawer)
    if self.src.data ~= nil then
        local pix1 = bitmap2pix(self.src, 0, 0, self.src.width, self.src.height)
        if pboxes and drawer == "lighten" then
            local color = 0xFFFF0000
            local bbox = self.bbox
            local pix2 = _gc_ptr(leptonica.pixConvertTo32(pix1), pixDestroy)
            for _, pbox in ipairs(pboxes) do
                local box = boxCreate(pbox.x - bbox.x0, pbox.y - bbox.y0, pbox.w, pbox.h)
                leptonica.pixMultiplyByColor(pix2, pix2, box, ffi.new("uint32_t", color))
            end
            return pix2
        else
            return pix1
        end
    end
end

function KOPTContext_mt.__index:exportSrcPNGFile(pboxes, drawer, filename)
    local pix = self:getSrcPix(pboxes, drawer)
    if pix ~= nil then
        leptonica.pixWritePng(filename, pix, ffi.new("float", 0.0))
    end
end

function KOPTContext_mt.__index:exportSrcPNGString(pboxes, drawer)
    local pix = self:getSrcPix(pboxes, drawer)
    if pix ~= nil then
        local pdata = ffi.new("char *[1]")
        local psize = ffi.new("size_t[1]")
        leptonica.pixWriteMemPng(pdata, psize, pix, 0.0)
        if pdata[0] ~= nil then
           local pngstr = ffi.string(pdata[0], psize[0])
           C.free(pdata[0])
           return pngstr
       end
    end
end

function KOPTContext_mt.__index:optimizePage()
    k2pdfopt.k2pdfopt_optimize_bmp(self)
end

function KOPTContext_mt.__index:free()
    -- NOTE: Jump through a large amount of shitty hoops to avoid double-frees,
    --       now that __gc may actually call us on collection long after an earlier explicit free...
    --- @fixme: Invest in a saner KOPTContext struct, possibly with a private bool to store the free state,
    ---         àla BlitBuffer/lj-sqlite3...
    self.rnai = numaDestroy(self.rnai)
    self.nnai = numaDestroy(self.nnai)
    self.rboxa = boxaDestroy(self.rboxa)
    self.nboxa = boxaDestroy(self.nboxa)
    self:setLanguage(nil)
    -- Already guards against NULL data pointers
    k2pdfopt.bmp_free(self.src)
    -- Already guards against NULL data pointers
    k2pdfopt.bmp_free(self.dst)
    if self.rectmaps.n ~= 0 then
        k2pdfopt.wrectmaps_free(self.rectmaps)
    end
end

function KOPTContext_mt:__gc()
    self:free()
end

function KOPTContext_mt.__index:freeOCR() k2pdfopt.k2pdfopt_tocr_end() end

-- NOTE: KOPTContext is a cdata struct, which is what makes __gc works here ;).
local kctype = ffi.metatype("KOPTContext", KOPTContext_mt)

function KOPTContext.new()
    local kc = kctype()
    -- integer values
    kc.trim = 1
    kc.wrap = 1
    kc.white = -1
    kc.indent = 1
    kc.rotate = 0
    kc.columns = 2
    kc.offset_x = 0
    kc.offset_y = 0
    kc.dev_dpi = 160
    kc.dev_width = 600
    kc.dev_height = 800
    kc.page_width = 600
    kc.page_height = 800
    kc.straighten = 0
    kc.justification = -1
    kc.read_max_width = 3000
    kc.read_max_height = 4000
    kc.writing_direction = 0
    -- number values
    kc.zoom = 1.0
    kc.margin = 0.06
    kc.quality = 1.0
    kc.contrast = 1.0
    kc.defect_size = 1.0
    kc.line_spacing = 1.2
    kc.word_spacing = -1
    kc.shrink_factor = 0.9
    -- states
    kc.precache = 0
    kc.debug = 0
    kc.cjkchar = 0
    -- struct
    kc.bbox = ffi.new("BBox", {0.0, 0.0, 0.0, 0.0})
    -- pointers
    kc.rboxa = nil
    kc.rnai = nil
    kc.nboxa = nil
    kc.nnai = nil
    kc.language = nil
    -- 1. in page reflowing context,
    --  `src` is the source page image fed into k2pdfopt, and `dst` is the reflowed
    --  page image. They usually have different page sizes.
    -- 2. in page optimization context,
    --  `src` is the source page image fed into k2pdfopt, and `dst` is the
    --  de-watermarked page image. They have the same page size.
    -- 3. in page segmentation context,
    --  `src` is the source page image fed into leptonica, and `dst` is the
    --  text block mask. They usually have different page sizes (the mask will be
    --  scaled down to half width and height).
    -- 4. in OCR context,
    --  `src` is an image of a word to be OCRed fed into k2pdfopt, and `dst` is unused.
    -- 5. in page cropping context,
    --  `src` is the source page image fed into k2pdfopt, and `dst` is unused.
    -- 6. in words boxing context,
    --  `src` is the source page image fed into k2pdfopt, and `dst` is unused.
    -- 7. in page drawing context,
    --  `src` is the source page image fed into leptonica, and `dst` is unused.
    k2pdfopt.bmp_init(kc.src)
    k2pdfopt.bmp_init(kc.dst)
    -- only used in words boxing context
    k2pdfopt.wrectmaps_init(kc.rectmaps)

    return kc
end

function KOPTContext.totable(kc)
    local context = {}
    -- version
    context.__version__ = __VERSION__
    -- integer values
    context.trim = kc.trim
    context.wrap = kc.wrap
    context.white = kc.white
    context.indent = kc.indent
    context.rotate = kc.rotate
    context.columns = kc.columns
    context.offset_x = kc.offset_x
    context.offset_y = kc.offset_y
    context.dev_dpi = kc.dev_dpi
    context.dev_width = kc.dev_width
    context.dev_height = kc.dev_height
    context.page_width = kc.page_width
    context.page_height = kc.page_height
    context.straighten = kc.straighten
    context.justification = kc.justification
    context.read_max_width = kc.read_max_width
    context.read_max_height = kc.read_max_height
    context.writing_direction = kc.writing_direction
    -- number values
    context.zoom = kc.zoom
    context.margin = kc.margin
    context.quality = kc.quality
    context.contrast = kc.contrast
    context.defect_size = kc.defect_size
    context.line_spacing = kc.line_spacing
    context.word_spacing = kc.word_spacing
    context.shrink_factor = kc.shrink_factor
    -- states
    context.precache = kc.precache
    context.debug = kc.debug
    context.cjkchar = kc.cjkchar
    -- struct
    context.bbox = ffi.string(kc.bbox, ffi.sizeof(kc.bbox))
    -- pointers
    context.rboxa = kc.rboxa and boxa_to_table(kc.rboxa)
    context.rnai = numa_to_string(kc.rnai)
    context.nboxa = kc.nboxa and boxa_to_table(kc.nboxa)
    context.nnai = numa_to_string(kc.nnai)
    context.language = kc.language and ffi.string(kc.language)
    -- bmp structs
    context.src = ffi.string(kc.src, ffi.sizeof(kc.src))
    if kc.src.size_allocated > 0 then
        context.src_data = ffi.string(kc.src.data, kc.src.size_allocated)
    else
        context.src_data = ""
    end
    context.dst = ffi.string(kc.dst, ffi.sizeof(kc.dst))
    if kc.dst.size_allocated > 0 then
        context.dst_data = ffi.string(kc.dst.data, kc.dst.size_allocated)
    else
        context.dst_data = ""
    end
    -- rectmaps struct
    context.rectmaps = {
        n = kc.rectmaps.n,
        na = kc.rectmaps.n,
        wrectmap = ffi.string(kc.rectmaps.wrectmap,
                ffi.sizeof("WRECTMAP")*kc.rectmaps.n)
    }

    return context
end

function KOPTContext.fromtable(context)
    -- check version first
    if __VERSION__ ~= context.__version__ then
        error("mismatched versions")
    end
    local kc = kctype()
    -- integer values
    kc.trim = context.trim
    kc.wrap = context.wrap
    kc.white = context.white
    kc.indent = context.indent
    kc.rotate = context.rotate
    kc.columns = context.columns
    kc.offset_x = context.offset_x
    kc.offset_y = context.offset_y
    kc.dev_dpi = context.dev_dpi
    kc.dev_width = context.dev_width
    kc.dev_height = context.dev_height
    kc.page_width = context.page_width
    kc.page_height = context.page_height
    kc.straighten = context.straighten
    kc.justification = context.justification
    kc.read_max_width = context.read_max_width
    kc.read_max_height = context.read_max_height
    kc.writing_direction = context.writing_direction
    -- number values
    kc.zoom = context.zoom
    kc.margin = context.margin
    kc.quality = context.quality
    kc.contrast = context.contrast
    kc.defect_size = context.defect_size
    kc.line_spacing = context.line_spacing
    kc.word_spacing = context.word_spacing
    kc.shrink_factor = context.shrink_factor
    -- states
    kc.precache = context.precache
    kc.debug = context.debug
    kc.cjkchar = context.cjkchar
    -- struct
    if context.bbox ~= "" then
        ffi.copy(kc.bbox, context.bbox, ffi.sizeof(kc.bbox))
    end
    -- pointers
    kc.rboxa = context.rboxa and boxa_from_table(context.rboxa)
    kc.rnai = context.rnai and numa_from_string(context.rnai)
    kc.nboxa = context.nboxa and boxa_from_table(context.nboxa)
    kc.nnai = context.nnai and numa_from_string(context.nnai)
    kc:setLanguage(context.language)

    k2pdfopt.bmp_init(kc.src)
    ffi.copy(kc.src, context.src, ffi.sizeof(kc.src))
    if context.src_data ~= "" then
        kc.src.data = C.malloc(#context.src_data)
        ffi.copy(kc.src.data, context.src_data, #context.src_data)
    else
        kc.src.data = nil
    end
    k2pdfopt.bmp_init(kc.dst)
    ffi.copy(kc.dst, context.dst, ffi.sizeof(kc.dst))
    if context.dst_data ~= "" then
        kc.dst.data = C.malloc(#context.dst_data)
        ffi.copy(kc.dst.data, context.dst_data, #context.dst_data)
    else
        kc.dst.data = nil
    end
    k2pdfopt.wrectmaps_init(kc.rectmaps)
    kc.rectmaps.n = context.rectmaps.n
    kc.rectmaps.na = context.rectmaps.n
    if context.rectmaps.wrectmap ~= "" then
        kc.rectmaps.wrectmap = C.malloc(#context.rectmaps.wrectmap)
        ffi.copy(kc.rectmaps.wrectmap,
                context.rectmaps.wrectmap, #context.rectmaps.wrectmap)
    else
        kc.rectmaps.wrectmap = nil
    end

    return kc
end

return KOPTContext
