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

-- InkView 4.x doesn't have the polling APIs, so inkview-compat.c
-- emulates those in a semaphore step-locked thread.
local compat, compat2 = inkview, inkview
if not pcall(function() local _ = inkview.PrepareForLoop end) then
    compat = ffi.load("inkview-compat")
    compat2 = compat
elseif not pcall(function() local _ = inkview.GetTouchInfoI end) then
    compat2 = ffi.load("inkview-compat")
end

local input = {}

local ts
-- Create new 'ts' with current timestamp.
-- The value is then shared by all events received/emulated at the same point in time.
local function updateTimestamp()
    local sec, usec = util.gettime()
    ts = { sec = sec, usec = usec }
    return ts
end

local eventq
-- Make emulated event and add it to the queue (ts presumed updated beforehand)
local function genEmuEvent(t, c, v)
    table.insert(eventq, {
        type = tonumber(t),
        code = tonumber(c),
        value = tonumber(v) or v,
        time = ts,
    })
end

local num_touch = 0
-- Translate event from inkview EVT_* into emulated linuxev EV_
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
    elseif t == C.EVT_KEYDOWN then
        genEmuEvent(C.EV_KEY, par1, 1)
    elseif t == C.EVT_KEYREPEAT then
        genEmuEvent(C.EV_KEY, par1, 2)
    elseif t == C.EVT_KEYUP then
        genEmuEvent(C.EV_KEY, par1, 0)
    elseif t == C.EVT_BACKGROUND or t == C.EVT_FOREGROUND
        or t == C.EVT_SHOW or t == C.EVT_HIDE
        or t == C.EVT_EXIT then
        -- Handle those as MiscEvent as this makes it easy to return a string directly,
        -- which can be used in uimanager.lua as an event_handler index.
        genEmuEvent(C.EV_MSC, t, 0)
    elseif t == C.EVT_ORIENTATION then
        -- Translate those to our own EV_MSC:MSC_GYRO proto
        if par1 == 0 then
            -- i.e., UR
            genEmuEvent(C.EV_MSC, C.MSC_GYRO, C.DEVICE_ORIENTATION_UPRIGHT)
        elseif par1 == 1 then
            -- i.e., CCW
            genEmuEvent(C.EV_MSC, C.MSC_GYRO, C.DEVICE_ORIENTATION_COUNTER_CLOCKWISE)
        elseif par1 == 2 then
            -- i.e., CW
            genEmuEvent(C.EV_MSC, C.MSC_GYRO, C.DEVICE_ORIENTATION_CLOCKWISE)
        elseif par1 == 3 then
            -- i.e., UD
            genEmuEvent(C.EV_MSC, C.MSC_GYRO, C.DEVICE_ORIENTATION_UPSIDE_DOWN)
        end
    else
        genEmuEvent(t, par1, par2)
    end
    return 0
end

local raw_keymap -- [EV_KEY] = "Action" supplied by frontend
local poll_fds, poll_fds_count = nil, 0
function input:open()
    eventq = {}
    -- Have all the necessary bits to run in raw mode without inkview interfering
    poll_fds = nil
    if self.raw_input then
        local max_fds = 20
        raw_keymap = self.raw_input.keymap
        poll_fds = ffi.new("struct pollfd[?]", max_fds)

        -- Open the monitor queue. We could technically live without it on older firmwares
        -- that don't have it, but I'm not sure how events are meant to be consumed on there
        -- to prevent stall, so for the time being we bail when we don't see it.
        local hwinput = rt.mq_open("/hwevent", C.O_RDONLY+C.O_NONBLOCK)
        assert(hwinput >= 0, "No /hwevent, probably too old firmware")
        poll_fds[0].fd = hwinput
        poll_fds[0].events = C.POLLIN
        poll_fds_count = 1

        -- Open the raw input devices.
        -- You must chmod those to be readable by non-root somehow (or run as root)
        for i=1, max_fds-1 do
            local input_dev = "/dev/input/event"..tostring(i)
            local fd = C.open(input_dev, bit.bor(C.O_RDONLY, C.O_NONBLOCK, C.O_CLOEXEC))
            if fd >= 0 then
                poll_fds[poll_fds_count].fd = fd
                poll_fds[poll_fds_count].events = C.POLLIN
                poll_fds_count = poll_fds_count + 1
            end
        end
        assert(poll_fds_count > 1, "Need access to /dev/input devices")

        -- This is only small part of what OpenScreen() does, namely map the shared state
        -- memory segment, and setup some touch/g info. Most of inkview API can run with just this
        -- in spite of us never setting up the event loop or screen canvas.
        inkview.hw_init()
        inkview.iv_update_orientation(0)
        inkview.iv_setup_touchpanel()
        inkview.iv_setup_gsensor()
        return
    end
    -- Initialize inkview ordinarily.
    compat.PrepareForLoop(translateEvent)
end

-- CLOCK_REALTIME value, in µs
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
local function waitForEventRaw(timeout)
    local expire = now() + timeout
    while true do
        -- Reset event queue
        eventq = {}

        local active = inkview.IsTaskActive() ~= 0
        -- Focus in/out transition, emit a synthetic event.
        if active ~= is_active then
            -- Avoid going to sleep during state transitions,
            -- so as to not accidentaly go sleeping mid fb refresh.
            next_sleep = now() + 10 * 1000 * 1000
            is_active = active
            return true, {
                type = C.EV_MSC,
                code = active and C.EVT_SHOW or C.EVT_HIDE,
                value = 0,
                time = updateTimestamp(),
            }
        end
        -- We have got sleepmode ("autostandby") requested by frontend.
        -- We must be a "properly" foregroun running to do this - no keylock (zzzz), and IsTaskActive must be true.
        -- In any other case, the monitor has the hot potato to manage sleep states
        if active and inkview.hw_get_keylock() == 0 and inkview.GetSleepmode() > 0 and now() > next_sleep then
            local before = now()
            -- This function may, or may not suspend the device until RTC in specified time,
            -- or GPIO (touch/button/Gsensor) fires. We make RTC wake up every 3 minutes to give
            -- autosuspend.koplugin timers a chance to kick in.
            inkview.GoSleep(180 * 1000, 0)
            -- If the system got suspended (T delta > 100ms), avoid sleeping for a bit again.
            -- We need to give chance a to monitor to flip our active / keylock flags if those have have changed.
            -- Without this, GoSleep could step on monitor while its doing the in/out sleep blur animation.
            if (now() - before) > 100 * 1000 then
                next_sleep = now() + 100 * 1000
            end
        end

        local remain = expire - now()
        if remain < 0 then
            -- Timed out
            return false, C.ETIME
        end

        local ms = math.max(math.min(remain / 1000, 1000), 20)
        poll_fds[0].events = is_active and C.POLLIN or 0
        for i=0, poll_fds_count-1 do
            poll_fds[i].revents = 0
        end
        local res = C.poll(poll_fds, poll_fds_count, ms)
        if res < 0 then
            return false, ffi.errno()
        end

        --- @note: No poll timeout handling?
        --         e.g., if res == 0 then return false, C.ETIME end

        -- Message from monitor. This sendss us both touch and key events, but not in a format
        -- thats particularly useful. Keys are nice as they have symbolic names already, but
        -- touch events are utter mess. In any case, this queue *must* be consumed, lest otherwise
        -- monitor would spam queued events to whaetever else gets focus after us.
        if band(poll_fds[0].revents, C.POLLIN) ~= 0 then
            updateTimestamp() -- single 'ts' copy for genEmuEvent inside the loop
            while rt.mq_receive(poll_fds[0].fd, ffi.cast("char*", hwmsg), hwmsg_len, nil) > 0 do
                local m = hwmsg[0]
                -- If there's no raw keymapping, emit this one instead
                if (m.type == C.EVT_KEYDOWN or m.type == C.EVT_KEYUP or m.type == C.EVT_KEYREPEAT) and not raw_keymap then
                    genEmuEvent(m.type, m.common.par1, m.common.par2)
                end
            end
        end

        -- Read all /dev/input pipes. We don't care which is which (for instance PB740 has 2
        -- input keyboards for measly 4 buttons!). So we simply discern by event code some of which is
        -- EV_KEY/EV_ABS/EV_SYN. One of the pipes is even BT/OTG keyboard, so typing on it works too.
        for i=1, poll_fds_count-1 do
            if band(poll_fds[i].revents, C.POLLIN) ~= 0 then
                while C.read(poll_fds[i].fd, evmsg, evmsg_len) == evmsg_len do
                    if is_active then
                        table.insert(eventq, convertEvent(evmsg))
                    end
                end
            end
        end
        if #eventq > 0 then
            return true, eventq
        end
    end
end

function input.waitForEvent(sec, usec)
    -- TimeVal's :tousecs if we were passed one to begin with, otherwise => 2s
    --- @note: This is unlike every other platform, where the fallback is an infinite timeout!
    local timeout = sec and math.floor(sec * 1000000 + usec + 0.5) or 2000000
    assert(eventq, "waitForEvent() invoked after device shutdown")
    if poll_fds then
        -- This variant uses low-level input I/O bypassing inkview for that entirely
        return waitForEventRaw(timeout)
    end
    local expire = now() + timeout
    while expire > now() do
        -- Reset event queue
        eventq = {}
        -- About ProcessEventLoop():
        -- When events are pending, translateEvent() cb is called for each here (it remembers what we've announced in PrepareForLoop).
        -- Our callback then queues whatever events it collects, translating to linux evinput while doing so.
        -- The call holds for 20ms and returns control once no further input is seen during that time. If iv_sleepmode is 1 however, and
        -- no input is seen for >2 seconds (it keeps track across invocations), the call will perform full OS suspend ("autostandby").
        compat.ProcessEventLoop()
        if #eventq > 0 then
            return true, eventq
        end
    end
    -- Timed out
    return false, C.ETIME
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
