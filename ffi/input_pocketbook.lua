local ffi = require("ffi")
local C = ffi.C
local rt = ffi.load("librt.so")
local inkview = ffi.load("inkview")
local util = require("ffi/util")

local bit = require("bit")
local band = bit.band

require("ffi/posix_h")
require("ffi/linux_input_h")
require("ffi/inkview_h")

local compat, compat2 = inkview, inkview
if not pcall(function() local _ = inkview.PrepareForLoop end) then
    compat = ffi.load("inkview-compat")
    compat2 = compat
elseif not pcall(function() local _ = inkview.GetTouchInfoI end) then
    compat2 = ffi.load("inkview-compat")
end

local input = {}

local ts
local function updateTimestamp()
    local sec, usec = util.gettime()
    ts = { sec = sec, usec = usec }
    return ts
end

local eventq
local function genEmuEvent(t,c,v)
    table.insert(eventq, {
        type = tonumber(t),
        code = tonumber(c),
        value = tonumber(v) or v,
        time = ts,
    })
end

local num_touch = 0
local function translateEvent(t, par1, par2)
    if eventq == nil then
        return 0
    end
    updateTimestamp()
    if t == C.EVT_INIT then
        inkview.SetPanelType(C.PANEL_DISABLED);
    elseif t == C.EVT_POINTERDOWN then
        num_touch = 1
        genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, 0)
        genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, par1)
        genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, par2)
    elseif t == C.EVT_MTSYNC then
        if num_touch > 0 and par2 == 2 then
            num_touch = 2
            for i = 0, 1 do
                genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, i);
                genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, i);
                local mt = compat2.GetTouchInfoI(i)
                genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, mt.x)
                genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, mt.y)
                genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
            end
        elseif par2 == 0 then
            for i = 0, 1 do
                genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, i);
                genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, -1);
                genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
            end
        else
            genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
        end
    elseif t == C.EVT_POINTERMOVE then
        if num_touch == 1 then
            genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, par1)
            genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, par2)
        end
    elseif t == C.EVT_POINTERUP then
        if num_touch == 1 then
            genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, -1)
        end
        num_touch = 0
    else
        genEmuEvent(t, par1, par2)
    end
    return 0
end

-- EV_KEY
local raw_keymap
local poll_fds, poll_fds_count = nil, 0
function input:open()
    eventq = {}
    -- Have all the necessary bits to run in raw mode without inkview interfering
    poll_fds = nil
    if self.raw_input then
        local max_fds = 20
        raw_keymap = self.raw_input.keymap
        poll_fds = ffi.new("struct pollfd[?]", max_fds)

        -- open the monitor queue
        local hwinput = rt.mq_open("/hwevent", C.O_RDONLY+C.O_NONBLOCK)
        assert(hwinput >= 0, "No /hwevent, probably too old firmware")
        poll_fds[0].fd = hwinput
        poll_fds[0].events = C.POLLIN
        poll_fds_count = 1

        -- open the raw input devices
        for i=1, max_fds-1 do
            local input_dev = "/dev/input/event"..tostring(i)
            local fd = C.open(input_dev, C.O_RDONLY+C.O_NONBLOCK)
            if fd >= 0 then
                poll_fds[poll_fds_count].fd = fd
                poll_fds[poll_fds_count].events = C.POLLIN
                poll_fds_count = poll_fds_count + 1
            end
        end
        assert(poll_fds_count > 1, "Need access to /dev/input devices")

        -- manually connect to the monitor, so basic process state sharing still works
        -- but avoid the messy inkview input handling
        inkview.hw_init()
        inkview.iv_update_orientation(0)
        inkview.iv_setup_touchpanel()
        inkview.iv_setup_gsensor()
        return
    end
    -- Initialize inkview ordinarily.
    compat.PrepareForLoop(translateEvent)
end

local function now()
    local s, u = util.gettime()
    return tonumber(s) * 1000000.0 + u
end

local evmsg = ffi.new("struct input_event[1]")
local evmsg_len = ffi.sizeof(evmsg)
local hwmsg = ffi.new("struct hw_event_s[1]")
local hwmsg_len = ffi.sizeof(hwmsg)

local function convertEvent(msg)
    return {
        -- Hmm, this is a little bit silly. The types are *almost* identical, except this.
        time = { sec = msg[0].time.tv_sec, usec = msg[0].time.tv_usec },
        type = msg[0].type,
        code = msg[0].code,
        value = msg[0].value,
    }
end

local is_active = false
local next_sleep = 0
local function waitForEventRaw(t)
    local expire = now() + t
    while true do
        local active = inkview.IsTaskActive() ~= 0
        -- focus transition, emit a synthetic event
        if active ~= is_active then
            -- avoid going to sleep during state transitions
            next_sleep = now() + 10 * 1000 * 1000
            is_active = active
            return {
                type = C.EV_MSC,
                code = active and C.EVT_SHOW or C.EVT_HIDE,
                value = 0,
                time = updateTimestamp(),
            }
        end
        -- sleepmode requested by frontend
        if active and inkview.hw_get_keylock() == 0 and inkview.GetSleepmode() > 0 and now() > next_sleep then
            -- RTC wake up every 3 minutes to give autoshutdown timer a chance to kick in
            local before = now()
            inkview.GoSleep(240 * 1000, 0)
            -- if we were sleeping, avoid sleeping for a bit then, for potential keylock to manifest
            if (now() - before) > 100 * 1000 then
                next_sleep = now() + 100 * 1000
            end
        end

        local remain = expire - now()
        if remain < 0 then
            error("Waiting for input failed: timeout\n")
        end

        local ms = math.max(math.min(remain / 1000, 1000), 20)
        poll_fds[0].events = is_active and C.POLLIN or 0
        for i=0, poll_fds_count-1 do
            poll_fds[i].revents = 0
        end
        local res = C.poll(poll_fds, poll_fds_count, ms)
        if res < 0 then
            error("poll(): " .. ffi.string(C.strerror(ffi.errno())))
        end

        -- mq from monitor
        if band(poll_fds[0].revents, C.POLLIN) ~= 0 then
            updateTimestamp() -- single 'ts' copy for genEmuEvent inside the loop
            while rt.mq_receive(poll_fds[0].fd, ffi.cast("char*", hwmsg), hwmsg_len, nil) > 0 do
                local m = hwmsg[0]
                -- If there's no raw keymapping, emit this one instead
                if (m.type == C.EVT_KEYDOWN or m.type == C.EVT_KEYUP) and not raw_keymap then
                    genEmuEvent(m.type, m.common.par1, m.common.par2)
                end
            end
        end

        -- direct linux evinput (lower latency)
        for i=1, poll_fds_count-1 do
            if band(poll_fds[i].revents, C.POLLIN) ~= 0 then
                while C.read(poll_fds[i].fd, evmsg, evmsg_len) == evmsg_len do
                    if is_active then
                        table.insert(eventq, convertEvent(evmsg))
                    end
                end
            end
        end
        if #eventq > 0 then return table.remove(eventq, 1) end

    end
end


function input.waitForEvent(t)
    t = t or 2000000
    assert(eventq, "waitForEvent() invoked after device shutdown")
    if #eventq > 0 then return table.remove(eventq, 1) end
    if poll_fds then
        -- This variant uses low-level input I/O bypassing inkview for that entirely
        return waitForEventRaw(t)
    end
    local expire = now() + t
    while expire > now() do
        -- About ProcessEventLoop():
        -- When events are pending, translateEvent() cb is called for each here (it remembers what we've announced in PrepareForLoop).
        -- Our callback then queues whatever events it collects, translating to linux evinput while doing so.
        -- The call holds for 20ms and returns control once no further input is seen during that time. If iv_sleepmode is 1 however, and
        -- no input is seen for >2 seconds (it keeps track across invocations), the call will perform full OS suspend ("autostandby").
        compat.ProcessEventLoop()
        if #eventq > 0 then return table.remove(eventq, 1) end
    end
    error("Waiting for input failed: timeout\n")
end

function input.fakeTapInput() end

function input.closeAll()
    eventq = nil
    if poll_fds ~= nil then
        rt.mq_close(poll_fds[0].fd)
        for i=1, poll_fds_count-1 do
            C.close(poll_fds[i].fd)
        end
        poll_fds = nil
        inkview.hw_close()
    else
        compat.ClearOnExit()
    end
end

return input
