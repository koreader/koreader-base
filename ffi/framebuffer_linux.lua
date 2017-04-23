local ffi = require("ffi")
local bit = require("bit")
local BB = require("ffi/blitbuffer")

local dummy = require("ffi/linux_fb_h")
local dummy = require("ffi/posix_h")

local framebuffer = {
    device_node = "/dev/fb0",
    fd = -1,
    fb_size = nil,
    data = nil,
}

function framebuffer:init()
    local finfo = ffi.new("struct fb_fix_screeninfo")
    local vinfo = ffi.new("struct fb_var_screeninfo")

    self.fd = ffi.C.open(self.device_node, ffi.C.O_RDWR)
    assert(self.fd ~= -1, "cannot open framebuffer")

    -- Get fixed screen information
    assert(ffi.C.ioctl(self.fd, ffi.C.FBIOGET_FSCREENINFO, finfo) == 0,
        "cannot get screen info")

    assert(ffi.C.ioctl(self.fd, ffi.C.FBIOGET_VSCREENINFO, vinfo) == 0,
        "cannot get variable screen info")

    assert(finfo.type == ffi.C.FB_TYPE_PACKED_PIXELS,
        "video type not supported")

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

    self.data = ffi.C.mmap(nil, self.fb_size, bit.bor(ffi.C.PROT_READ, ffi.C.PROT_WRITE), ffi.C.MAP_SHARED, self.fd, 0)
    assert(self.data ~= ffi.C.MAP_FAILED, "can not mmap() framebuffer")
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
        ffi.C.munmap(self.data, self.fb_size)
        self.data = nil
    end
    if self.fd ~= -1 then
        ffi.C.close(self.fd)
        self.fd = -1
    end
end

return require("ffi/framebuffer"):extend(framebuffer)
