local ffi = require("ffi")
local bit = require("bit")
local BB = require("ffi/blitbuffer")
local C = ffi.C

require("ffi/linux_fb_h")
require("ffi/posix_h")

local framebuffer = {
    device_node = "/dev/fb0",
    fd = -1,
    fb_size = nil,
    data = nil,
}

--[[

The raw framebuffer memory is managed through Blitbuffer. When creating the
Blitbuffer, we bind it to a framebuffer memory size of `vinfo.xres *
finfo.line_length` assuming portrait mode by default.

Here are couple interesting framebuffer attributes to watch out when porting to
new devices:

* vinfo.bits_per_pixel: Size of each pixel, for example, 16bits, 32bits, etc.
* finfo.smem_len: Size of the actual framebuffer memory provided by the kernel.
* finfo.line_length: Size of each row for the framebuffer.
                     Usually, it would be close to `vinfo.xres_virtual * vinfo.bits_per_pixel / 8`.
* vinfo.xres: Number of pixels in one row on physical screen, i.e. physical screen width
* vinfo.yres: Number of pixels in one column on physical screen, i.e. physical screen height
* vinfo.xres_virtual: Number of pixels in one row on scrollable virtual screen, for fb_pan_display.
                      Usually `vinfo.xres_virtual` >= `vinfo.xres`.
* vinfo.yres_virtual: Number of pixels in one column on scrollable virtual screen, for fb_pan_display.
                      Usually `vinfo.yres_virtual` >= `vinfo.yres`.

NOTE for Kobo:

By definition, `finfo.smem_len` should always be larger than or equal to
`vinfo.xres_virtual * vinfo.yres_virtual * vinfo.bits_per_pixel / 8`.

However, turns out this is not the case on Kobo when the framebuffer is
operating at 32bits mode.

On Kobo Aura One, under 16bits mode, we got:

    finfo.line_length: 2816
    finfo.smem_len: 10813440
    vinfo.bits_per_pixel: 16
    vinfo.xres: 1404
    vinfo.yres: 1872
    vinfo.xres_virtual: 1408
    vinfo.yres_virtual: 3840

But under 32bits mode, we got:

    finfo.line_length: 5632
    finfo.smem_len: 10813440
    vinfo.bits_per_pixel: 32
    vinfo.xres: 1404
    vinfo.yres: 1872
    vinfo.xres_virtual: 1408
    vinfo.yres_virtual: 3840

The only settings that got changed are `finfo.line_length` and `vinfo.bits_per_pixel`.
`finfo.smem_len` still remains at 10813440.

--]]
function framebuffer:init()
    local finfo = ffi.new("struct fb_fix_screeninfo")
    local vinfo = ffi.new("struct fb_var_screeninfo")

    self.fd = C.open(self.device_node, C.O_RDWR)
    assert(self.fd ~= -1, "cannot open framebuffer")

    -- Get fixed screen information
    assert(C.ioctl(self.fd, C.FBIOGET_FSCREENINFO, finfo) == 0, "cannot get screen info")
    assert(C.ioctl(self.fd, C.FBIOGET_VSCREENINFO, vinfo) == 0,
           "cannot get variable screen info")

    assert(finfo.type == C.FB_TYPE_PACKED_PIXELS, "video type not supported")
    assert(vinfo.xres_virtual > 0 and vinfo.yres_virtual > 0, "invalid framebuffer resolution")

    -- Classic eink framebuffer (Kindle 2, 3, DXG, 4)
    if ffi.string(finfo.id, 7) == "eink_fb" then
        self.fb_size = vinfo.xres_virtual * vinfo.yres_virtual * vinfo.bits_per_pixel / 8
    -- Newer eink framebuffer (Kindle Touch, Paperwhite, Kobo)
    elseif ffi.string(finfo.id, 11) == "mxc_epdc_fb" then
        -- it seems that finfo.smem_len is unreliable on kobo
        -- Figure out the size of the screen in bytes
        self.fb_size = vinfo.xres_virtual * vinfo.yres_virtual * vinfo.bits_per_pixel / 8
        -- Kobo hasn't updated smem_len when the depth was changed from 16 to 32
        if vinfo.bits_per_pixel == 32 then
            self.fb_size = finfo.smem_len
        end
    -- PocketBook eink framebuffer seems to have no finfo.id
    elseif string.byte(ffi.string(finfo.id, 16), 1, 1) == 0 then
        -- finfo.line_length needs to be 16-bytes aligned
        finfo.line_length = bit.band(finfo.line_length * vinfo.bits_per_pixel / 8 + 15, bit.bnot(15))
        self.fb_size = finfo.line_length * vinfo.yres_virtual
    else
        error("framebuffer model not supported");
    end

    self.data = C.mmap(nil,
                           self.fb_size,
                           bit.bor(C.PROT_READ, C.PROT_WRITE),
                           C.MAP_SHARED,
                           self.fd,
                           0)
    assert(tonumber(ffi.cast("intptr_t", self.data)) ~= C.MAP_FAILED,
           "can not mmap() framebuffer")
    if vinfo.bits_per_pixel == 32 then
        self.bb = BB.new(vinfo.xres, vinfo.yres, BB.TYPE_BBRGB32, self.data, finfo.line_length)
    elseif vinfo.bits_per_pixel == 16 then
        self.bb = BB.new(vinfo.xres, vinfo.yres, BB.TYPE_BBRGB16, self.data, finfo.line_length)
    elseif vinfo.bits_per_pixel == 8 then
        self.bb = BB.new(vinfo.xres, vinfo.yres, BB.TYPE_BB8, self.data, finfo.line_length)
    elseif vinfo.bits_per_pixel == 4 then
        self.bb = BB.new(vinfo.xres, vinfo.yres, BB.TYPE_BB4, self.data, finfo.line_length)
    else
        error("unknown bpp value for the eink driver")
    end

    if ffi.string(finfo.id, 7) == "eink_fb" then
        -- classic eink framebuffer driver has grayscale values inverted (i.e. 0xF = black, 0 = white)
        self.bb:invert()
    end

    self.bb:fill(BB.COLOR_WHITE)

    framebuffer.parent.init(self)
end

function framebuffer:close()
    if self.bb ~= nil then
        self.bb:free()
        self.bb = nil
    end
    if self.data then
        C.munmap(self.data, self.fb_size)
        self.data = nil
    end
    if self.fd ~= -1 then
        C.close(self.fd)
        self.fd = -1
    end
end

return require("ffi/framebuffer"):extend(framebuffer)
