local ffi = require("ffi")
local BB = require("ffi/blitbuffer")
local inkview = ffi.load("inkview")

require("ffi/linux_fb_h")

local uint8pt_rodata = ffi.typeof("const uint8_t*")

local framebuffer = {
    panel_has_color = true,
}

local function _getPhysicalRect(fb, x, y, w, h)
    local bb = fb.full_bb or fb.bb
    x, y, w, h = bb:getBoundedRect(x, y, w, h)
    return bb:getPhysicalRect(x, y, w, h)
end

local function _hasColorInPhysicalRect(bb, px, py, pw, ph)
    if not bb or pw <= 0 or ph <= 0 then
        return false
    end
    local bpp = bb:getBytesPerPixel()
    if bpp == 3 or bpp == 4 then
        local base = ffi.cast(uint8pt_rodata, bb.data)
        local stride = tonumber(bb.stride)
        local row_start = py * stride + px * bpp
        local row_span = (pw - 1) * bpp
        for _ = 1, ph do
            for idx = row_start, row_start + row_span, bpp do
                local r = base[idx]
                if r ~= base[idx + 1] or r ~= base[idx + 2] then
                    return true
                end
            end
            row_start = row_start + stride
        end
    end
    return false
end

local function _shouldUseColorRefresh(fb, px, py, pw, ph)
    local bb = fb.full_bb or fb.bb
    local rect_has_color = _hasColorInPhysicalRect(bb, px, py, pw, ph)
    local is_page_sized = (pw * ph) >= (bb.w * bb.h * 0.5)

    local use_color = fb.panel_has_color or rect_has_color

    if is_page_sized then
        fb.panel_has_color = rect_has_color
    elseif rect_has_color then
        fb.panel_has_color = true
    end

    return use_color, rect_has_color
end

local function _adjustAreaColours(fb)
    if fb.device.hasColorScreen() then
        fb.debug("adjusting image color saturation")

        inkview.adjustAreaDefault(fb.data, fb._finfo.line_length, fb._vinfo.width, fb._vinfo.height)
    end
end

local function _updatePartial(fb, x, y, w, h, dither)
    x, y, w, h = _getPhysicalRect(fb, x, y, w, h)

    fb.debug("refresh: inkview partial", x, y, w, h, dither)

    if fb.device.hasColorScreen() then
        local use_color, rect_has_color = _shouldUseColorRefresh(fb, x, y, w, h)
        if use_color then
            dither = rect_has_color
            if dither then
                -- inkview.adjustAreaDefault updates buffer in-place, with additional refreshes mangling content.
                -- We need to restore the original buffer to make sure it won't be adjusted twice.
                fb:saveCurrentBB()
                _adjustAreaColours(fb)
            end
            inkview.PartialUpdateHQ(x, y, w, h)
            if dither then
                fb:restoreFromSavedBB()
            end
            return
        end
    end

    inkview.PartialUpdate(x, y, w, h)
end

local function _updateFull(fb, x, y, w, h, dither)
    fb.debug("refresh: inkview full", x, y, w, h, dither)

    if fb.device.hasColorScreen() then
        local bb = fb.full_bb or fb.bb
        local use_color, rect_has_color = _shouldUseColorRefresh(fb, 0, 0, bb.w, bb.h)
        if use_color then
            dither = rect_has_color
            if dither then
                fb:saveCurrentBB()
                _adjustAreaColours(fb)
            end
            inkview.FullUpdateHQ()
            if dither then
                fb:restoreFromSavedBB()
            end
            return
        end
    end

    inkview.FullUpdate()
end

local function _updateFast(fb, x, y, w, h, dither)
    x, y, w, h = _getPhysicalRect(fb, x, y, w, h)

    fb.debug("refresh: inkview fast", x, y, w, h, dither)

    if fb.device.hasColorScreen() then
        local _, rect_has_color = _shouldUseColorRefresh(fb, x, y, w, h)
        dither = rect_has_color
    else
        dither = false
    end

    if dither then
        fb:saveCurrentBB()
        _adjustAreaColours(fb)
    end

    inkview.DynamicUpdate(x, y, w, h)

    if dither then
        fb:restoreFromSavedBB()
    end
end

function framebuffer:init()
    self._finfo = ffi.new("struct fb_fix_screeninfo")
    self._vinfo = ffi.new("struct fb_var_screeninfo")

    local finfo = self._finfo
    local vinfo = self._vinfo

    self.debug("Initialize inkview screen")
    inkview.OpenScreen()

    local pb_fb = inkview.GetTaskFramebuffer(inkview.GetCurrentTask())

    self._finfo.line_length = pb_fb.scanline
    self._vinfo.xres = pb_fb.width
    self._vinfo.yres = pb_fb.height
    self.fb_size = self._finfo.line_length * self._vinfo.yres

    self._vinfo.width = pb_fb.width
    self._vinfo.height = pb_fb.height


    local bpp = pb_fb.depth

    self.data = pb_fb.addr
    self.bb = BB.new(pb_fb.width, pb_fb.height, BB["TYPE_BB"..bpp] or BB["TYPE_BBRGB"..bpp], self.data, pb_fb.scanline, pb_fb.width)

    self.blitbuffer_rotation_mode = self.bb:getRotation()
    self.screen_size = self:getRawSize()
    self.native_rotation_mode = self.forced_rotation and self.forced_rotation.default or self.DEVICE_ROTATED_UPRIGHT
    self.cur_rotation_mode = self.native_rotation_mode


    self.debug("FB info (post fixup)", {
        fb_size = self.fb_size,
        xres = vinfo.xres,
        yres = vinfo.yres,
        xoffset = vinfo.xoffset,
        yoffset = vinfo.yoffset,
        bpp = bpp,
        xres_virtual = vinfo.xres,
        yres_virtual = vinfo.yres,
        line_length = finfo.line_length,
        stride_pixels = finfo.line_length,
        smem_len = finfo.smem_len,
        type = finfo.type,
        mmio_len = finfo.mmio_len,
        rotate = vinfo.rotate,
        width_mm = vinfo.width,
        height_mm = vinfo.height,
    })
end

function framebuffer:close(reinit)
    if self.bb ~= nil then
        self.bb:free()
        self.bb = nil
    end
end

--[[ framebuffer API ]]--

function framebuffer:refreshPartialImp(x, y, w, h, dither)
    _updatePartial(self, x, y, w, h, dither)
end

function framebuffer:refreshFlashPartialImp(x, y, w, h, dither)
    _updatePartial(self, x, y, w, h, dither)
end

function framebuffer:refreshUIImp(x, y, w, h, dither)
    _updatePartial(self, x, y, w, h, dither)
end

function framebuffer:refreshFlashUIImp(x, y, w, h, dither)
    _updatePartial(self, x, y, w, h, dither)
end

function framebuffer:refreshFullImp(x, y, w, h, dither)
    _updateFull(self, x, y, w, h, dither)
end

function framebuffer:refreshFastImp(x, y, w, h, dither)
    _updateFast(self, x, y, w, h, dither)
end

function framebuffer:refreshWaitForLastImp()
    if self.mech_wait_update_complete and self.dont_wait_for_marker ~= self.marker then
        self.debug("refresh: inkview waiting for previous update", self.marker)
        -- self:mech_wait_update_complete(self.marker)
        inkview.WaitForUpdateComplete()
        self.dont_wait_for_marker = self.marker
    end
end

return require("ffi/framebuffer_linux"):extend(framebuffer)
