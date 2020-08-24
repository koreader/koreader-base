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
    fb_bpp = nil,
    fb_rota = nil,
    data = nil,
}

-- A couple helper functions to compute/check aligned values...
-- c.f., <linux/kernel.h>
local function ALIGN(x, a)
    -- (x + (a-1)) & ~(a-1)
    local mask = a - 1
    return bit.band(x + mask, bit.bnot(mask))
end

local function IS_ALIGNED(x, a)
    -- (x & (a-1)) == 0
    if bit.band(x, a - 1) == 0 then
        return true
    else
        return false
    end
end

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

There's a reason for that: there used to be enough space for a shadow buffer on 16bpp modesets,
and that's no longer the case on 32bpp, since the active buffer now takes twice as much space.
What *is* definitely wrong in this log is yres_virtual in the 32bpp case, it should be much smaller,
so that line_length * yres_virtual == smem_len
AFAICT, this has since been fixed.

--]]
function framebuffer:init()
    local finfo = ffi.new("struct fb_fix_screeninfo")
    local vinfo = ffi.new("struct fb_var_screeninfo")

    self.fd = C.open(self.device_node, bit.bor(C.O_RDWR, C.O_CLOEXEC))
    assert(self.fd ~= -1, "cannot open framebuffer")

    -- Get fixed screen information
    assert(C.ioctl(self.fd, C.FBIOGET_FSCREENINFO, finfo) == 0, "cannot get screen info")
    assert(C.ioctl(self.fd, C.FBIOGET_VSCREENINFO, vinfo) == 0,
           "cannot get variable screen info")

    assert(finfo.type == C.FB_TYPE_PACKED_PIXELS, "video type not supported")
    assert(vinfo.xres_virtual > 0 and vinfo.yres_virtual > 0, "invalid framebuffer resolution")

    -- Classic eink framebuffer (Kindle 2, 3, DXG, 4)
    if ffi.string(finfo.id, 7) == "eink_fb" then
        self.fb_size = vinfo.xres_virtual * vinfo.yres_virtual * (vinfo.bits_per_pixel / 8)
    -- Newer eink framebuffer (Kindle Touch, Paperwhite, Kobo)
    elseif ffi.string(finfo.id, 11) == "mxc_epdc_fb" then
        -- Figure out the size of the active screen buffer in bytes
        self.fb_size = vinfo.xres_virtual * vinfo.yres_virtual * (vinfo.bits_per_pixel / 8)
        -- There's no longer space for a shadow buffer on 32bpp modesets, and yres_virtual may be bogus, so, use smem_len as-is
        if vinfo.bits_per_pixel == 32 then
            self.fb_size = finfo.smem_len
        end
    -- PocketBook eink framebuffer seems to have no finfo.id
    elseif string.byte(ffi.string(finfo.id, 16), 1, 1) == 0 then
        -- Dump FB information to the log on PB to make bug reports about these kinds of issues useful straight away...
        io.write("PB FB: smem_len    : ", finfo.smem_len, "\n")
        io.write("PB FB: line_length : ", finfo.line_length, "\n")
        io.write("PB FB: xres        : ", vinfo.xres, "\n")
        io.write("PB FB: xres_virtual: ", vinfo.xres_virtual, "\n")
        io.write("PB FB: yres        : ", vinfo.yres, "\n")
        io.write("PB FB: yres_virtual: ", vinfo.yres_virtual, "\n")
        io.write("PB FB: bpp         : ", vinfo.bits_per_pixel, "\n")
        -- We may need to make sure finfo.line_length is properly aligned ourselves...
        -- NOTE: The technical reason being that, on mxcfb (as opposed to the legacy einkfb),
        --       the PxP *may* require a scratch space of *at least* 8 extra *pixels* in a line.
        --       On Kobo & Kindle, the kernel takes care of ensuring the sanity of the fixed & variable fbinfo,
        --       (c.f., mxc_epdc_fb_check_var @ drivers/video/mxc/mxc_epdc_fb.c OR drivers/video/fbdev/mxc/mxc_epdc_v2_fb.c).
        --       On PB, not so much (possibly because they expect you to use InkView).
        --       So, do it ourselves, if need be...
        local xres_virtual = vinfo.xres_virtual
        if not IS_ALIGNED(vinfo.xres_virtual, 32) then
            -- NOTE: As per Kindle/Kobo kernels, xres_virtual = ALIGN(xres, 32);
            vinfo.xres_virtual = ALIGN(vinfo.xres, 32)
            io.write("PB FB: xres_virtual -> ", vinfo.xres_virtual, "\n")
        end
        local yres_virtual = vinfo.yres_virtual
        if not IS_ALIGNED(vinfo.yres_virtual, 128) then
            -- NOTE: As per Kindle/Kobo kernels, yres_virtual = ALIGN(yres, 128) * num_screens;
            --       We don't do hardware panning/flip buffers, so, we only care about a single screen.
            vinfo.yres_virtual = ALIGN(vinfo.yres, 128)
            io.write("PB FB: yres_virtual -> ", vinfo.yres_virtual, "\n")
        end
        -- Now that we know xres_virtual is sane, we can compute the proper line_length
        local line_length = finfo.line_length
        finfo.line_length = vinfo.xres_virtual * (vinfo.bits_per_pixel / 8)
        io.write("PB FB: line_length -> ", finfo.line_length, "\n")

        -- NOTE: Ideally, if there's no shadow buffer, we should end up with line_length == smem_len / yres_virtual...
        -- So we should now be able to make an accurate computation of the active buffer size... Whew!
        self.fb_size = finfo.line_length * vinfo.yres_virtual
        -- NOTE: If our manually computed value is larger than the reported smem_len, honor smem_len instead (c.f., #4416)
        --       Because despite PB's shenanigans, I'm assuming smem_len matches the actual HW bounds,
        --       and as such matches the extent of memory we can safely mmap.
        --       TL;DR: We can safely mmap a *smaller* memory region than smem_len,
        --              (which is usually what all of the fb_size computations that don't use smem_len do here),
        --              but we certainly CANNOT mmap a *larger* one!
        if self.fb_size > finfo.smem_len then
            -- NOTE: But first, we'll try to align *both* dimensions to 32...
            --       This appears to be needed for legacy 600*800 devices, c.f. #4476.
            if not IS_ALIGNED(yres_virtual, 32) then
                vinfo.yres_virtual = ALIGN(vinfo.yres, 32)
                io.write("PB FB: yres_virtual => ", vinfo.yres_virtual, "\n")
            else
                vinfo.yres_virtual = yres_virtual
                io.write("PB FB: yres_virtual <- ", vinfo.yres_virtual, "\n")
            end
            self.fb_size = finfo.line_length * vinfo.yres_virtual

            -- If that still didn't cut it, final fallback...
            if self.fb_size > finfo.smem_len then
                self.fb_size = finfo.smem_len
                -- And that means the original line_length should *probably* be honored, too...
                finfo.line_length = line_length
                io.write("PB FB: line_length <- ", finfo.line_length, "\n")
                -- As well as both _virtual dimensions (c.f., #4851)...
                vinfo.xres_virtual = xres_virtual
                io.write("PB FB: xres_virtual <- ", vinfo.xres_virtual, "\n")
                -- We probably don't care about yres as much ax xres, but, eh.
                vinfo.yres_virtual = yres_virtual
                io.write("PB FB: yres_virtual <- ", vinfo.yres_virtual, "\n")
            end
        end
    else
        error("framebuffer model not supported");
    end

    -- Pocketbook Color Lux reports bits_per_pixel = 8, but actually uses an RGB24 framebuffer
    if self.device:has3BytesWideFrameBuffer() then
        vinfo.bits_per_pixel = 24
        vinfo.xres = vinfo.xres / 3
    end

    -- Recap final, potentially tweaked FB setup...
    io.write("FB: computed size: ", self.fb_size, "\n")
    io.write("FB: id           : ", ffi.string(finfo.id), "\n")
    io.write("FB: smem_len     : ", finfo.smem_len, "\n")
    io.write("FB: line_length  : ", finfo.line_length, "\n")
    io.write("FB: xres         : ", vinfo.xres, "\n")
    io.write("FB: xres_virtual : ", vinfo.xres_virtual, "\n")
    io.write("FB: yres         : ", vinfo.yres, "\n")
    io.write("FB: yres_virtual : ", vinfo.yres_virtual, "\n")
    io.write("FB: bpp          : ", vinfo.bits_per_pixel, "\n")
    io.flush()

    -- Make sure we never try to map a larger memory region than the fb reports
    assert(self.fb_size <= finfo.smem_len, "computed fb memory region too large")

    self.data = C.mmap(nil,
                           self.fb_size,
                           bit.bor(C.PROT_READ, C.PROT_WRITE),
                           C.MAP_SHARED,
                           self.fd,
                           0)
    assert(tonumber(ffi.cast("intptr_t", self.data)) ~= C.MAP_FAILED,
           "can not mmap() framebuffer")
    if vinfo.bits_per_pixel == 32 then
        self.bb = BB.new(vinfo.xres, vinfo.yres, BB.TYPE_BBRGB32, self.data, finfo.line_length, vinfo.xres_virtual, vinfo.yres_virtual)
    elseif vinfo.bits_per_pixel == 24 then
        self.bb = BB.new(vinfo.xres, vinfo.yres, BB.TYPE_BBRGB24, self.data, finfo.line_length, vinfo.xres_virtual, vinfo.yres_virtual)
    elseif vinfo.bits_per_pixel == 16 then
        self.bb = BB.new(vinfo.xres, vinfo.yres, BB.TYPE_BBRGB16, self.data, finfo.line_length, vinfo.xres_virtual, vinfo.yres_virtual)
    elseif vinfo.bits_per_pixel == 8 then
        self.bb = BB.new(vinfo.xres, vinfo.yres, BB.TYPE_BB8, self.data, finfo.line_length, vinfo.xres_virtual, vinfo.yres_virtual)
    elseif vinfo.bits_per_pixel == 4 then
        self.bb = BB.new(vinfo.xres, vinfo.yres, BB.TYPE_BB4, self.data, finfo.line_length, vinfo.xres_virtual, vinfo.yres_virtual)
    else
        error("unknown bpp value for the eink driver")
    end

    -- Make accessing the bitdepth easier, because we might want to know we're running on Kobo's quirky 16bpp mode later...
    self.fb_bpp = vinfo.bits_per_pixel

    -- Same for the current hardware rotation, it's potentially useful info on the Kobo Forma
    self.fb_rota = vinfo.rotate

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
