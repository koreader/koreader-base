local ffi = require("ffi")
local bit = require("bit")
local BB = require("ffi/blitbuffer")
local C = ffi.C

require("ffi/linux_fb_h")
require("ffi/ion_kobo_h")
require("ffi/posix_h")

local framebuffer = {
    fb_node = "/dev/fb0",
    ion_node = "/dev/ion",
    disp_node = "/dev/disp"
    ion_fd = -1,
    fd = -1,

    fb_size = nil,
    fb_bpp = 8,
    fb_rota = 0,

    data = nil,

    alloc_size = nil,
    ion = nil,
    layer = nil,

    _finfo = nil,
    _vinfo = nil,
}

--[[
This is roughly based on framebuffer_linux, and shares some of the logic with it.
--]]

-- Frontend driver should override this if they need to apply kludges on vinfo/finfo
function framebuffer:fbinfoOverride(finfo, vinfo)
end

-- We request PAGE-aligned addresses from ION, *and* PAGE-aligned allocation sizes.
local function PAGE_ALIGN(size)
    return bit.band(size + 4095, -4096)
end

function framebuffer:init()
    -- We'll start by the usual poking at fb0, as it's the only way to get accurate screen dimension information...
    self._finfo = ffi.new("struct fb_fix_screeninfo")
    self._vinfo = ffi.new("struct fb_var_screeninfo")

    local fbfd = C.open(self.fb_node, bit.bor(C.O_RDONLY, C.O_NONBLOCK, C.O_CLOEXEC))
    assert(fbfd ~= -1, "cannot open framebuffer")

    -- Get screen information
    assert(C.ioctl(fbfd, C.FBIOGET_FSCREENINFO, self._finfo) == 0, "cannot get fixed screen info")
    assert(C.ioctl(fbfd, C.FBIOGET_VSCREENINFO, self._vinfo) == 0, "cannot get variable screen info")

    -- ... and we're actually done with the framebuffer device ;).
    C.close(fbfd)

    -- Apply frontend kludges
    self:fbinfoOverride(self._finfo, self._vinfo)

    assert(self._finfo.type == C.FB_TYPE_PACKED_PIXELS, "video type not supported")
    assert(self._vinfo.xres > 0 and self._vinfo.yres > 0, "invalid framebuffer resolution")

    -- We'll map a screen's worth of memory
    self.fb_size = self._finfo.line_length * self._vinfo.yres_virtual

    local bpp = self._vinfo.bits_per_pixel
    local stride_pixels = self._finfo.line_length * 8
    assert(stride_pixels % bpp == 0, "line_length doesn't end at pixel boundary")
    stride_pixels = stride_pixels / bpp

    self.debug("FB info (post fixup)", {
          fb_size = self.fb_size,
          xres = self._vinfo.xres,
          yres = self._vinfo.yres,
          bpp = bpp,
          xres_virtual = self._vinfo.xres,
          yres_virtual = self._vinfo.yres,
          line_length = self._finfo.line_length,
          stride_pixels = stride_pixels,
          smem_len = self._finfo.smem_len,
          type = self._finfo.type,
          rotate = self._vinfo.rotate,
          width_mm = self._vinfo.width,
          height_mm = self._vinfo.height,
    })

    -- Make sure we never try to map a larger memory region than the fb reports
    assert(self.fb_size <= self._finfo.smem_len or self._finfo.smem <= 0x1000, "computed fb memory region too large")

    -- And now we can start dealing with ION proper...
    self.ion = ffi.new("struct ion_fd_data")

    -- Start by registering as an ION client
    self.ion_fd = C.open(self.ion_node, bit.bor(C.O_RDONLY, C.O_NONBLOCK, C.O_CLOEXEC))
    assert(self.ion_fd ~= -1, "cannot open ION handle")

    -- Then request a page-aligned carveout mapping large enough to fit our screen
    self.alloc_size = PAGE_ALIGN(self._finfo.smem_len)
    local alloc = ffi.new("struct ion_allocation_data")
    alloc.len = self.alloc_size
    alloc.align = 4096
    alloc.heap_id_mask = C.ION_HEAP_MASK_CARVEOUT
    assert(C.ioctl(self.ion_fd, C.ION_IOC_ALLOC, alloc) == 0, "cannot allocate ION buffer")

    -- Request a dmabuff handle that we can share & mmap for that alloc
    self.ion.handle = alloc.handle
    assert(C.ioctl(self.ion_fd, C.ION_IOC_MAP, self.ion) == 0, "cannot get dmabuff handle from ION")

    -- And we're back in familiar territory: mmap it!
    self.data = C.mmap(nil, self.alloc_size, bit.bor(C.PROT_READ, C.PROT_WRITE), C.MAP_SHARED, self.ion.fd, 0)
    assert(tonumber(ffi.cast("intptr_t", self.data)) ~= C.MAP_FAILED, "can not mmap() ION buffer")

    -- And point our screen BB at it
    self.bb = BB.new(self._vinfo.xres, self._vinfo.yres, BB["TYPE_BB"..bpp] or BB["TYPE_BBRGB"..bpp], self.data, self._finfo.line_length, stride_pixels)

    -- Make a few vInfo fields easier to access
    self.fb_bpp = bpp
    self.fb_rota = vinfo.rotate

    -- And finally, register as a DISP client, too
    self.fd = C.open(self.disp_node, bit.bor(C.O_RDONLY, C.O_NONBLOCK, C.O_CLOEXEC))
    assert(self.fd ~= -1, "cannot open ION handle")

    -- Setup the insanity that is the sunxi disp2 layer...
    self.layer = ffi.new("struct disp_layer_config2")
    self.layer.info.fb.fd    = 0
    self.layer.info.fb.y8_fd = sunxiCtx.ion.fd

    -- And we're cooking with gas!
    self.screen_size = self:getRawSize()
    self.bb:fill(BB.COLOR_WHITE)

    framebuffer.parent.init(self)
end

function framebuffer:close()
    if self.bb ~= nil then
        self.bb:free()
        self.bb = nil
    end
    if self.data then
        C.munmap(self.data, self.alloc_size)
        self.data = nil
        self.alloc_size = nil
    end
    if self.ion and self.ion.fd ~= -1 then
       C.close(self.ion.fd)
       self.ion.fd = -1
    end
    if self.ion and self.ion.handle ~= 0 then
        local handle = ffi.new("struct ion_handle_data")
        handle.handle = self.ion.handle
        assert(C.ioctl(self.ion_fd, C.ION_IOC_FREE, handle) == 0, "cannot release ION buffer")
        self.ion.handle = 0
    end
    if self.ion_fd ~= -1 then
        C.close(self.ion_fd)
        self.ion_fd = -1
    end
    if self.fd ~= -1 then
        C.close(self.fd)
        self.fd = -1
    end
end

return require("ffi/framebuffer"):extend(framebuffer)
