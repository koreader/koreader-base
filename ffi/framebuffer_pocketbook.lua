local ffi = require("ffi")
local BB = require("ffi/blitbuffer")
local inkview = ffi.load("inkview")

require("ffi/inkview_h")
require("ffi/linux_fb_h")

local framebuffer = {

}

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
    self.native_rotation_mode = self.forced_rotation and self.forced_rotation.default or self.ORIENTATION_PORTRAIT
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
    self.debug("refresh: inkview partial", x, y, w, h)
    inkview.PartialUpdate(x, y, w, h)
end

function framebuffer:refreshFlashPartialImp(x, y, w, h, dither)
    self.debug("refresh: inkview partial", x, y, w, h)
    inkview.PartialUpdate(x, y, w, h)
end

function framebuffer:refreshUIImp(x, y, w, h, dither)
    self.debug("refresh: inkview partial", x, y, w, h)
    inkview.PartialUpdate(x, y, w, h)
end

function framebuffer:refreshFlashUIImp(x, y, w, h, dither)
    self.debug("refresh: inkview partial", x, y, w, h)
    inkview.PartialUpdate(x, y, w, h)
end

function framebuffer:refreshFullImp(x, y, w, h, dither)
    self.debug("refresh: inkview partial", x, y, w, h)
    inkview.FullUpdate()
end

function framebuffer:refreshFastImp(x, y, w, h, dither)
    self.debug("refresh: inkview dynamic", x, y, w, h)
    inkview.DynamicUpdate(x, y, w, h)
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
