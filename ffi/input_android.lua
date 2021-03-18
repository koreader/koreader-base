local ffi = require("ffi")
local bit = require("bit")
local C = ffi.C

local android = require("android")
local dummy = require("ffi/linux_input_h")

local input = {
-- to trigger refreshes for certain Android framework events:
    device = nil,
}

function input.open()
end

local inputQueue = {}

local ev_time = ffi.new("struct timeval")
local function genEmuEvent(evtype, code, value)
    C.gettimeofday(ev_time, nil)
    local ev = {
        type = tonumber(evtype),
        code = tonumber(code),
        value = tonumber(value),
        time = { sec = tonumber(ev_time.tv_sec), usec = tonumber(ev_time.tv_usec) }
    }
    table.insert(inputQueue, ev)
end

local function genTouchDownEvent(event, id)
    local x = android.lib.AMotionEvent_getX(event, id)
    local y = android.lib.AMotionEvent_getY(event, id)
    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, id)
    genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, id)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, x)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, y)
    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
end

local function genTouchUpEvent(event, id)
    local x = android.lib.AMotionEvent_getX(event, id)
    local y = android.lib.AMotionEvent_getY(event, id)
    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, id)
    genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, -1)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, x)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, y)
    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
end

local function genTouchMoveEvent(event, id, index)
    local x = android.lib.AMotionEvent_getX(event, index)
    local y = android.lib.AMotionEvent_getY(event, index)
    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, id)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, x)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, y)
    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
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
        genEmuEvent(C.EV_KEY, code, 1)
    elseif action == C.AKEY_EVENT_ACTION_UP then
        genEmuEvent(C.EV_KEY, code, 0)
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
        local events = ffi.new("int[1]")
        local source = ffi.new("struct android_poll_source*[1]")
        local poll_state = android.lib.ALooper_pollAll(timeout, nil, events, ffi.cast("void**", source))
        if poll_state >= 0 then
            if source[0] ~= nil then
                --source[0].process(android.app, source[0])
                if source[0].id == C.LOOPER_ID_MAIN then
                    local cmd = android.glue.android_app_read_cmd(android.app)
                    android.glue.android_app_pre_exec_cmd(android.app, cmd)
                    commandHandler(cmd, 1)
                    android.glue.android_app_post_exec_cmd(android.app, cmd)
                elseif source[0].id == C.LOOPER_ID_INPUT then
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
            end
            if android.app.destroyRequested ~= 0 then
                android.LOGI("Engine thread destroy requested!")
                -- That'll be handled as a catastrophic failure in the frontend, but the ultimate goal of killing the app will be achieved ;p.
                return
            end
        elseif poll_state == C.ALOOPER_POLL_TIMEOUT then
            -- ETIME
            return false, 62
        elseif poll_state == C.ALOOPER_POLL_ERROR then
            android.LOGE("Encountered a polling error!")
            return
        end
    end
end

function input.fakeTapInput() end
function input.closeAll() end

return input
