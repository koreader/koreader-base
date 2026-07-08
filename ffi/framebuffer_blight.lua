local ffi = require("ffi")
local BB = require("ffi/blitbuffer")
local C = ffi.C
local blight = require("ffi/blight")

require("ffi/posix_h")

-- Load the client/protocol library
local libblight = ffi.loadlib("blight_protocol", "3", "blight_protocol")

local contenttype = (blight.is_rmpp or blight.is_rmppm) and C.Color or C.Monochrome

local framebuffer = {
    bus = nil,
    fd = -1,
    thread = nil,
    buf = nil,
    surface_id = 0,
    cur_refresh_mode = -1,
}

function framebuffer:init()
    local width = 1404
    local height = 1872

    if blight.is_rmpp then
        width = 1620
        height = 2160
    elseif blight.is_rmppm then
        width = 954
        height = 1696
    end

    -- Connect to DBus
    local bus_ptr = ffi.new("blight_bus*[1]")
    local res = libblight.blight_bus_connect_system(bus_ptr)
    if res < 0 then
        res = libblight.blight_bus_connect_user(bus_ptr)
    end
    assert(res >= 0 and bus_ptr[0] ~= nil, "Failed to connect to Blight DBus")
    self.bus = bus_ptr[0]
    framebuffer.bus = self.bus

    -- Open service socket
    local fd = libblight.blight_service_open(self.bus)
    assert(fd >= 0, "Failed to open Blight service socket")
    self.fd = fd
    framebuffer.fd = self.fd

    -- Start background connection thread
    self.thread = libblight.blight_start_connection_thread(self.fd)
    assert(self.thread ~= nil, "Failed to start Blight connection thread")

    -- Determine appropriate buffer format (reMarkable 1 expects RGB16, others expect RGBA8888)
    local bpp = blight.is_rm1 and 2 or 4
    local format = blight.is_rm1 and C.Format_RGB16 or C.Format_RGBA8888
    local bb_type = blight.is_rm1 and BB.TYPE_BBRGB16 or BB.TYPE_BBRGB32

    -- Create image buffer
    local stride = width * bpp
    local scale = 1.0
    self.buf = libblight.blight_create_buffer(0, 0, width, height, stride, format, scale)
    assert(self.buf ~= nil, "Failed to create Blight image buffer")

    -- Add surface
    self.surface_id = libblight.blight_add_surface(self.bus, self.buf)
    assert(self.surface_id > 0, "Failed to add Blight surface")
    framebuffer.surface_id = self.surface_id

    -- Focus and Raise surface
    libblight.blight_focus(self.fd)
    libblight.blight_raise(self.fd, self.surface_id)

    -- Initialize blitbuffer
    local stride_pixels = width
    self.bb = BB.new(width, height, bb_type, self.buf.data, stride, stride_pixels)
    self.bb:fill(BB.COLOR_WHITE)

    -- Set up waveforms
    self.wf_level_max = 3
    self.waveform_full = C.Content
    self.waveform_ui = C.UI
    self.waveform_a2 = C.Animate

    local level = self:getWaveformLevel()
    if level == 0 then
        self.waveform_fast = C.Content
        self.waveform_partial = C.Content
    elseif level == 1 then
        self.waveform_fast = C.UI
        self.waveform_partial = C.Content
    elseif level == 2 then
        self.waveform_fast = C.Fast
        self.waveform_partial = C.UI
    elseif level == 3 then
        self.waveform_fast = C.Fast
        self.waveform_partial = C.Fast
    end

    -- Call parent init method
    framebuffer.parent.init(self)

    -- Force full update on startup
    self:refreshFull(0, 0, width, height)
end

local function blight_update(fb, x, y, w, h, waveform, update_mode)
    x, y, w, h = fb.bb:getBoundedRect(x, y, w, h)
    x, y, w, h = fb.bb:getPhysicalRect(x, y, w, h)

    libblight.blight_surface_repaint(fb.fd, fb.surface_id, x, y, w, h, waveform, contenttype, update_mode)
end

function framebuffer:refreshFullImp(x, y, w, h)
    blight_update(self, x, y, w, h, self.waveform_full, C.FullUpdate)
end

function framebuffer:refreshPartialImp(x, y, w, h)
    blight_update(self, x, y, w, h, self.waveform_partial, C.PartialUpdate)
end

function framebuffer:refreshUIImp(x, y, w, h)
    blight_update(self, x, y, w, h, self.waveform_ui, C.UIUpdate)
end

function framebuffer:refreshFastImp(x, y, w, h)
    blight_update(self, x, y, w, h, self.waveform_fast, C.PartialUpdate)
end

function framebuffer:refreshA2Imp(x, y, w, h)
    blight_update(self, x, y, w, h, self.waveform_a2, C.AnimationUpdate)
end

function framebuffer:close()
    if self.bb then
        self.bb:free()
        self.bb = nil
    end
    if self.fd and self.fd >= 0 then
        if self.surface_id > 0 then
            libblight.blight_remove_surface(self.fd, self.surface_id)
            self.surface_id = 0
        end
        if self.thread ~= nil then
            libblight.blight_connection_thread_deref(self.thread)
            self.thread = nil
        end
        C.close(self.fd)
        self.fd = -1
    end
    if self.buf ~= nil then
        libblight.blight_buffer_deref(self.buf)
        self.buf = nil
    end
    if self.bus ~= nil then
        libblight.blight_bus_deref(self.bus)
        self.bus = nil
    end
end

return require("ffi/framebuffer"):extend(framebuffer)
