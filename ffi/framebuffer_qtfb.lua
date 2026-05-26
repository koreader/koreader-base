local ffi = require("ffi")
local BB = require("ffi/blitbuffer")
local C = ffi.C
local qtfb = require("ffi/qtfb")

require("ffi/posix_h")

-- Fallback/explicit loading of librt for shm_open
local rt
local ok = pcall(function() rt = ffi.load("rt") end)
if not ok or not rt then
    rt = C
end

local framebuffer = {
    sock = -1,
    data = nil,
    fb_size = 0,
    cur_refresh_mode = -1,
}

function framebuffer:init()
    local key_str = os.getenv("QTFB_KEY")
    local key = key_str and tonumber(key_str) or 245209899 -- QTFB_DEFAULT_FRAMEBUFFER

    local shmType = 0 -- FBFMT_RM2FB as default
    local width = 1404
    local height = 1872

    if qtfb.is_rmpp then
        shmType = 3 -- FBFMT_RMPP_RGB565
        width = 1620
        height = 2160
    elseif qtfb.is_rmppm then
        shmType = 6 -- FBFMT_RMPPM_RGB565
        width = 954
        height = 1696
    end

    -- Create and connect UNIX domain socket
    local sock = C.socket(C.AF_UNIX, C.SOCK_SEQPACKET, 0)
    assert(sock >= 0, "Failed to create UNIX socket")

    local addr = ffi.new("struct sockaddr_un", C.AF_UNIX, "/tmp/qtfb.sock")

    local res = C.connect(sock, ffi.cast("const struct sockaddr *", addr), ffi.sizeof(addr))
    if res ~= 0 then
        C.close(sock)
        error("Failed to connect to QTFB socket at /tmp/qtfb.sock (errno: " .. ffi.errno() .. ")")
    end

    self.sock = sock

    -- Send MESSAGE_INITIALIZE (0)
    local initMsg = ffi.new("struct ClientMessage")
    initMsg.type = qtfb.MESSAGE_INITIALIZE
    initMsg.init.framebufferKey = key
    initMsg.init.framebufferType = shmType

    local bytes_sent = C.send(self.sock, initMsg, ffi.sizeof(initMsg), 0)
    if bytes_sent < 0 then
        C.close(self.sock)
        self.sock = -1
        error("Failed to send init message to QTFB server")
    end

    -- Recv server confirmation response
    local respMsg = ffi.new("struct ServerMessage")
    local bytes_recvd = C.recv(self.sock, respMsg, ffi.sizeof(respMsg), 0)
    if bytes_recvd < ffi.sizeof(respMsg) then
        C.close(self.sock)
        self.sock = -1
        error("Failed to receive init message response from QTFB server")
    end

    local shmKey = respMsg.init.shmKeyDefined
    local shmSize = respMsg.init.shmSize

    -- Open and map shared memory
    local shmName = string.format("/qtfb_%d", shmKey)
    local shmFD = rt.shm_open(shmName, 2, 0) -- O_RDWR = 2
    if shmFD < 0 then
        C.close(self.sock)
        self.sock = -1
        error("Failed to shm_open shared memory: " .. shmName .. " (errno: " .. ffi.errno() .. ")")
    end

    local memory = C.mmap(nil, shmSize, bit.bor(C.PROT_READ, C.PROT_WRITE), C.MAP_SHARED, shmFD, 0)
    C.close(shmFD) -- Safe to close fd after mapping

    if ffi.cast('intptr_t', memory) == C.MAP_FAILED then
        C.close(self.sock)
        self.sock = -1
        error("Failed to mmap() shared memory (errno: " .. ffi.errno() .. ")")
    end

    self.data = memory
    self.fb_size = shmSize

    -- Initialize blitbuffer (forcing 16-bit RGB565)
    local stride = width * 2 -- 2 bytes per pixel for RGB565
    local stride_pixels = width
    self.bb = BB.new(width, height, BB.TYPE_BBRGB16, self.data, stride, stride_pixels)
    self.bb:fill(BB.COLOR_WHITE)

    self.wf_level_max = 3
    self.waveform_full = qtfb.REFRESH_MODE_CONTENT
    self.waveform_ui = qtfb.REFRESH_MODE_UI
    self.waveform_a2 = qtfb.REFRESH_MODE_ANIMATE

    local level = self:getWaveformLevel()
    -- Best quality but much slower refresh.
    if level == 0 then
        self.waveform_fast = qtfb.REFRESH_MODE_CONTENT
        self.waveform_partial = qtfb.REFRESH_MODE_CONTENT
    -- Good quality for contents while still having decently fast "fast" refresh mode without losing any color.
    elseif level == 1 then
        self.waveform_fast = qtfb.REFRESH_MODE_UI
        self.waveform_partial = qtfb.REFRESH_MODE_CONTENT
    -- Level 2: fast refresh mode loses color on color-enabled devices.
    elseif level == 2 then
        self.waveform_fast = qtfb.REFRESH_MODE_FAST
        self.waveform_partial = qtfb.REFRESH_MODE_UI
    -- Fastest refresh, but more ghosting and artifacts, and color is lost on color-enabled devices.
    elseif level == 3 then
        self.waveform_fast = qtfb.REFRESH_MODE_FAST
        self.waveform_partial = qtfb.REFRESH_MODE_FAST
    end

    -- Call parent init method
    framebuffer.parent.init(self)

    -- Force full update on startup
    self:refreshFull(0, 0, width, height)
end

local function qtfb_update(fb, x, y, w, h)
    x, y, w, h = fb.bb:getBoundedRect(x, y, w, h)
    x, y, w, h = fb.bb:getPhysicalRect(x, y, w, h)

    local msg = ffi.new("struct ClientMessage")
    msg.type = qtfb.MESSAGE_UPDATE
    msg.update.type = 1 -- UPDATE_PARTIAL
    msg.update.x = x or 0
    msg.update.y = y or 0
    msg.update.w = w or 0
    msg.update.h = h or 0

    C.send(fb.sock, msg, ffi.sizeof(msg), 0)
end

function framebuffer:setRefreshMode(mode)
    if self.cur_refresh_mode == mode then return end
    self.cur_refresh_mode = mode

    local msg = ffi.new("struct ClientMessage")
    msg.type = qtfb.MESSAGE_SET_REFRESH_MODE
    msg.refreshMode = mode

    C.send(self.sock, msg, ffi.sizeof(msg), 0)
end

function framebuffer:refreshFullImp(x, y, w, h)
    self:setRefreshMode(self.waveform_full)
    qtfb_update(self, x, y, w, h)

    -- Request a full hardware refresh to clear e-ink ghosting
    local msg = ffi.new("struct ClientMessage")
    msg.type = qtfb.MESSAGE_REQUEST_FULL_REFRESH
    C.send(self.sock, msg, ffi.sizeof(msg), 0)
end

function framebuffer:refreshPartialImp(x, y, w, h)
    self:setRefreshMode(self.waveform_partial)
    qtfb_update(self, x, y, w, h)
end

function framebuffer:refreshUIImp(x, y, w, h)
    self:setRefreshMode(self.waveform_ui)
    qtfb_update(self, x, y, w, h)
end

function framebuffer:refreshFastImp(x, y, w, h)
    self:setRefreshMode(self.waveform_fast)
    qtfb_update(self, x, y, w, h)
end

function framebuffer:refreshA2Imp(x, y, w, h)
    self:setRefreshMode(self.waveform_a2)
    qtfb_update(self, x, y, w, h)
end

function framebuffer:close()
    if self.bb then
        self.bb:free()
        self.bb = nil
    end
    if self.data then
        C.munmap(self.data, self.fb_size)
        self.data = nil
    end
    if self.sock and self.sock ~= -1 then
        -- Send MESSAGE_TERMINATE (3)
        local terminateMsg = ffi.new("struct ClientMessage")
        terminateMsg.type = qtfb.MESSAGE_TERMINATE
        C.send(self.sock, terminateMsg, ffi.sizeof(terminateMsg), 0)
        C.close(self.sock)
        self.sock = -1
    end
end

return require("ffi/framebuffer"):extend(framebuffer)
