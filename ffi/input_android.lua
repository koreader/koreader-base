local ffi = require("ffi")
local bit = require("bit")
local C = ffi.C

local android = require("android")
require("ffi/posix_h")
require("ffi/linux_input_h")

local input = {
-- to trigger refreshes for certain Android framework events:
    device = nil,
}

function input.open()
end

local inputQueue = {}

local function genEmuEvent(evtype, code, value, ts)
    local timev = { sec = 0, usec = 0 }
    if ts then
        -- If we've got one, trust the native event's timestamp, they're guaranteed to be in the CLOCK_MONOTONIC timebase.
        -- ns to µs
        -- NOTE: The documentation is extremely confusing, but this is actually in nanoseconds,
        --       c.f., https://android.googlesource.com/platform/frameworks/base/+/b11499d2db0ba9782363ec6bf714b583e8585212%5E!/
        local us = math.floor(tonumber(ts) / 1000)
        -- TimeVal, how I miss thee...
        timev.sec = math.floor(us / 1000000)
        timev.usec = us % 1000000
    else
        -- Otherwise, synthetize one in the same time scale.
        -- TimeVal probably ought to be in base...
        local timespec = ffi.new("struct timespec")
        C.clock_gettime(C.CLOCK_MONOTONIC, timespec)
        timev.sec = tonumber(timespec.tv_sec)
        -- ns to µs
        timev.usec = math.floor(tonumber(timespec.tv_nsec / 1000))
    end
    local ev = {
        type = tonumber(evtype),
        code = tonumber(code),
        value = tonumber(value),
        time = timev,
    }
    table.insert(inputQueue, ev)
end

local function genTouchDownEvent(event, id)
    local x = android.lib.AMotionEvent_getX(event, id)
    local y = android.lib.AMotionEvent_getY(event, id)
    local ts = android.lib.AMotionEvent_getEventTime(event)
    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, id, ts)
    genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, id, ts)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, x, ts)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, y, ts)
    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0, ts)
end

local function genTouchUpEvent(event, id)
    local x = android.lib.AMotionEvent_getX(event, id)
    local y = android.lib.AMotionEvent_getY(event, id)
    local ts = android.lib.AMotionEvent_getEventTime(event)
    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, id, ts)
    genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, -1, ts)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, x, ts)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, y, ts)
    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0, ts)
end

local function genTouchMoveEvent(event, id, index)
    local x = android.lib.AMotionEvent_getX(event, index)
    local y = android.lib.AMotionEvent_getY(event, index)
    local ts = android.lib.AMotionEvent_getEventTime(event)
    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, id, ts)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, x, ts)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, y, ts)
    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0, ts)
end

local is_in_touch = false
local function motionEventHandler(motion_event)
    if android.isTouchscreenIgnored() then
        return
    end
    local action = android.lib.AMotionEvent_getAction(motion_event)
    local pointer_count = android.lib.AMotionEvent_getPointerCount(motion_event)
    local pointer_index = bit.rshift(
            bit.band(action, C.AMOTION_EVENT_ACTION_POINTER_INDEX_MASK),
            C.AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT)
    local id = android.lib.AMotionEvent_getPointerId(motion_event, pointer_index)
    local flags = bit.band(action, C.AMOTION_EVENT_ACTION_MASK)
    if flags == C.AMOTION_EVENT_ACTION_DOWN then
        is_in_touch = true
        genTouchDownEvent(motion_event, id)
    elseif flags == C.AMOTION_EVENT_ACTION_POINTER_DOWN then
        is_in_touch = true
        genTouchDownEvent(motion_event, id)
    elseif flags == C.AMOTION_EVENT_ACTION_UP then
        is_in_touch = false
        genTouchUpEvent(motion_event, id)
    elseif flags == C.AMOTION_EVENT_ACTION_POINTER_UP then
        is_in_touch = false
        genTouchUpEvent(motion_event, id)
    elseif flags == C.AMOTION_EVENT_ACTION_MOVE then
        if is_in_touch then
            for index = 0, pointer_count - 1 do
                id = android.lib.AMotionEvent_getPointerId(motion_event, index)
                genTouchMoveEvent(motion_event, id, index)
            end
        end
    end
end

local function keyEventHandler(key_event)
    local code = android.lib.AKeyEvent_getKeyCode(key_event)
    local action = android.lib.AKeyEvent_getAction(key_event)
    if code == C.AKEYCODE_VOLUME_UP
    or code == C.AKEYCODE_VOLUME_DOWN then
        if android.getVolumeKeysIgnored() then
            return 0 -- event not consumed
        end
    elseif code == C.AKEYCODE_MEDIA_PLAY_PAUSE
    or code == C.AKEYCODE_MEDIA_STOP
    or code == C.AKEYCODE_MEDIA_NEXT
    or code == C.AKEYCODE_MEDIA_PREVIOUS
    or code == C.AKEYCODE_MEDIA_REWIND
    or code == C.AKEYCODE_MEDIA_FAST_FORWARD then
        return 0 -- event not consumed
    elseif code == C.AKEYCODE_MUTE
    or code == C.AKEYCODE_VOLUME_MUTE then
        if android.getVolumeKeysIgnored() then
            return 0
        else
            return 1
        end
    end
    if code == C.AKEYCODE_BACK and android.isBackButtonIgnored() then
        return 1
    end
    if action == C.AKEY_EVENT_ACTION_DOWN then
        local ts = android.lib.AKeyEvent_getEventTime(key_event)
        genEmuEvent(C.EV_KEY, code, 1, ts)
    elseif action == C.AKEY_EVENT_ACTION_UP then
        local ts = android.lib.AKeyEvent_getEventTime(key_event)
        genEmuEvent(C.EV_KEY, code, 0, ts)
    end
    return 1 -- event consumed
end

local function commandHandler(code, value)
    genEmuEvent(C.EV_MSC, code, value)
end

function input.waitForEvent(sec, usec)
    -- TimeVal's :tomsecs if we were passed one to begin with, otherwise, -1 => block
    local timeout = sec and math.floor(sec * 1000000 + usec + 0.5) / 1000 or -1
    while true do
        -- check for queued events
        if #inputQueue > 0 then
            -- return oldest FIFO element
            return true, table.remove(inputQueue, 1)
        end
        -- Will contain the raw fd number
        local fd     = ffi.new("int[1]")
        -- Will contain the poll events
        local events = ffi.new("int[1]")
        -- Will point to the data pointer passed at addFd/attachLooper time, c.f., the struct definition.
        -- NOTE: Its id field is entirely redundant, as ALooper already returns the ident.
        --       And its process function can be used as a weird delayed callback mechanism, but ALooper already has native callback handling :?.
        --       TL;DR: We don't actually use it here.
        local source = ffi.new("struct android_poll_source*[1]")
        local poll_state = android.lib.ALooper_pollAll(timeout, fd, events, ffi.cast("void**", source))
        if poll_state >= 0 then
            -- NOTE: Since we actually want to process this in Lua-land (i.e., here), and not in C-land,
            --       we do *NOT* make use of the weird delayed-callback mechanism afforded by the android_poll_source struct
            --       we pass as the data pointer to ALooper in the glue code when registering a polling source.
            --       Instead, we do everything here, which is why this may look eerily like the C functions
            --       process_cmd & process_input in the glue code.
            --       Sidebar: if you *actually* need to process stuff in C-land ASAP, use ALooper's native callback system.
            if poll_state == C.LOOPER_ID_MAIN then
                -- e.g., source[0].process(android.app, source[0]) where process would point to process_cmd
                local cmd = android.glue.android_app_read_cmd(android.app)
                android.glue.android_app_pre_exec_cmd(android.app, cmd)
                commandHandler(cmd, 1)
                android.glue.android_app_post_exec_cmd(android.app, cmd)
            elseif poll_state == C.LOOPER_ID_INPUT then
                -- e.g., source[0].process(android.app, source[0]) where process would point to process_input
                local event = ffi.new("AInputEvent*[1]")
                while android.lib.AInputQueue_getEvent(android.app.inputQueue, event) >= 0 do
                    if android.lib.AInputQueue_preDispatchEvent(android.app.inputQueue, event[0]) == 0 then
                        local event_type = android.lib.AInputEvent_getType(event[0])
                        local handled = 1
                        if event_type == C.AINPUT_EVENT_TYPE_MOTION then
                            motionEventHandler(event[0])
                        elseif event_type == C.AINPUT_EVENT_TYPE_KEY then
                            handled = keyEventHandler(event[0])
                        end
                        android.lib.AInputQueue_finishEvent(android.app.inputQueue, event[0], handled)
                    end
                end
            end
            if android.app.destroyRequested ~= 0 then
                android.LOGI("Engine thread destroy requested!")
                -- Do nothing, if this is set, we've already pushed an APP_CMD_DESTROY event that'll get handled in front.
            end
        elseif poll_state == C.ALOOPER_POLL_TIMEOUT then
            return false, C.ETIME
        elseif poll_state == C.ALOOPER_POLL_ERROR then
            android.LOGE("Encountered a polling error!")
            return
        end
        -- NOTE: We never set callbacks, and we never call wake, so no need to check for ALOOPER_POLL_CALLBACK & ALOOPER_POLL_WAKE
    end
end

function input.fakeTapInput() end
function input.closeAll() end

return input
