local ffi = require("ffi")
local C = ffi.C
local util = require("ffi/util")
local bit = require("bit")
local qtfb = require("ffi/qtfb")

require("ffi/posix_h")

local input = {
    is_ffi = true,
}

-- GestureDetector expects multitouch slots to be specifically 0 and 1.
-- Since the QTFB server propagates arbitrary Qt touch point IDs (devId) which can be
-- non-sequential or start at 1, we dynamically map incoming devIds to stable sequential
-- slot indices starting at 0 to ensure multitouch gestures (e.g. pinch-to-zoom) are correctly detected.
local slotMap = {}

local function get_assigned_slot(devId)
    if not slotMap[devId] then
        local used_slots = {}
        for _, pointer in pairs(slotMap) do
            used_slots[pointer.slot] = true
        end
        local slot = 0
        while used_slots[slot] do
            slot = slot + 1
        end
        slotMap[devId] = { slot = slot }
    end
    return slotMap[devId].slot
end

local function translate_input(msg)
    local Device = require("device")
    local inputType = msg.userInput.inputType
    local devId = msg.userInput.devId
    local x = msg.userInput.x
    local y = msg.userInput.y
    local d = msg.userInput.d

    local xTranslate = x
    local yTranslate = y
    local dTranslate = d

    -- Width/height from the connection
    local fb_w = Device.screen:getScreenWidth()
    local fb_h = Device.screen:getScreenHeight()

    -- Convert QTFB's already converted input back to raw form, since input handling code is shared with non-QTFB implmentation
    if qtfb.is_rmpp then
        if bit.band(inputType, 0xF0) == 0x10 then -- INPUT_TOUCH
            xTranslate = math.floor((x * 2064) / fb_w)
            yTranslate = math.floor((y * 2832) / fb_h)
        elseif bit.band(inputType, 0xF0) == 0x20 then -- INPUT_PEN
            xTranslate = math.floor((x * 11180) / fb_w)
            yTranslate = math.floor((y * 15340) / fb_h)
            dTranslate = math.floor((d * 255) / 100)
        end
    elseif qtfb.is_rmppm then
        if bit.band(inputType, 0xF0) == 0x10 then
            xTranslate = math.floor((x * 1248) / fb_w)
            yTranslate = math.floor((y * 2208) / fb_h)
        elseif bit.band(inputType, 0xF0) == 0x20 then
            xTranslate = math.floor((x * 6760) / fb_w)
            yTranslate = math.floor((y * 11960) / fb_h)
            dTranslate = math.floor((d * 255) / 100)
        end
    elseif qtfb.is_rmppure then
        if bit.band(inputType, 0xF0) == 0x10 then
            xTranslate = math.floor((x * 1776) / fb_w)
            yTranslate = math.floor((y * 2400) / fb_h)
        elseif bit.band(inputType, 0xF0) == 0x20 then
            xTranslate = math.floor((x * 9620) / fb_w)
            yTranslate = math.floor((y * 13000) / fb_h)
            dTranslate = math.floor((d * 255) / 100)
        end
    elseif qtfb.is_rm1 then
        if bit.band(inputType, 0xF0) == 0x10 then
            xTranslate = 767 - math.floor((x * 767) / fb_w)
            yTranslate = 1023 - math.floor((y * 1023) / fb_h)
        elseif bit.band(inputType, 0xF0) == 0x20 then
            xTranslate = 20967 - math.floor((y * 20967) / fb_h)
            yTranslate = math.floor((x * 15725) / fb_w)
            dTranslate = math.floor((d * 4096) / 100)
        end
    else -- RM2 or default
        if bit.band(inputType, 0xF0) == 0x10 then
            xTranslate = math.floor((x * 1403) / fb_w)
            yTranslate = 1871 - math.floor((y * 1871) / fb_h)
        elseif bit.band(inputType, 0xF0) == 0x20 then
            xTranslate = 20967 - math.floor((y * 20967) / fb_h)
            yTranslate = math.floor((x * 15725) / fb_w)
            dTranslate = math.floor((d * 4096) / 100)
        end
    end

    local events = {}
    local time = { sec = 0, usec = 0 }
    local sec, usec = util.gettime()
    time.sec = sec
    time.usec = usec

    local function emit(type, code, value)
        table.insert(events, {
            type = type,
            code = code,
            value = value,
            time = time
        })
    end

    if inputType == 0x10 then -- INPUT_TOUCH_PRESS
        local assignedSlot = get_assigned_slot(devId)
        emit(C.EV_ABS, C.ABS_MT_SLOT, assignedSlot)
        emit(C.EV_ABS, C.ABS_MT_TRACKING_ID, assignedSlot)
        emit(C.EV_ABS, C.ABS_MT_PRESSURE, 100)
        emit(C.EV_ABS, C.ABS_MT_POSITION_X, xTranslate)
        emit(C.EV_ABS, C.ABS_MT_POSITION_Y, yTranslate)
        emit(C.EV_KEY, C.BTN_TOUCH, 1)
        emit(C.EV_SYN, C.SYN_REPORT, 0)
    elseif inputType == 0x11 then -- INPUT_TOUCH_RELEASE
        local assignedSlot = slotMap[devId] and slotMap[devId].slot or 0
        slotMap[devId] = nil
        emit(C.EV_ABS, C.ABS_MT_SLOT, assignedSlot)
        emit(C.EV_ABS, C.ABS_MT_TRACKING_ID, -1)
        emit(C.EV_KEY, C.BTN_TOUCH, 0)
        emit(C.EV_SYN, C.SYN_REPORT, 0)
    elseif inputType == 0x12 then -- INPUT_TOUCH_UPDATE
        local assignedSlot = get_assigned_slot(devId)
        emit(C.EV_ABS, C.ABS_MT_SLOT, assignedSlot)
        emit(C.EV_ABS, C.ABS_MT_POSITION_X, xTranslate)
        emit(C.EV_ABS, C.ABS_MT_POSITION_Y, yTranslate)
        emit(C.EV_SYN, C.SYN_REPORT, 0)
    elseif inputType == 0x20 then -- INPUT_PEN_PRESS
        emit(C.EV_KEY, C.BTN_TOOL_PEN, 1)
        emit(C.EV_KEY, C.BTN_TOUCH, 1)
        emit(C.EV_ABS, C.ABS_X, xTranslate)
        emit(C.EV_ABS, C.ABS_Y, yTranslate)
        emit(C.EV_ABS, C.ABS_PRESSURE, dTranslate)
        emit(C.EV_SYN, C.SYN_REPORT, 0)
    elseif inputType == 0x21 then -- INPUT_PEN_RELEASE
        emit(C.EV_KEY, C.BTN_TOOL_PEN, 1)
        emit(C.EV_KEY, C.BTN_TOUCH, 0)
        emit(C.EV_ABS, C.ABS_X, xTranslate)
        emit(C.EV_ABS, C.ABS_Y, yTranslate)
        emit(C.EV_ABS, C.ABS_PRESSURE, dTranslate)
        emit(C.EV_SYN, C.SYN_REPORT, 0)
    elseif inputType == 0x22 then -- INPUT_PEN_UPDATE
        emit(C.EV_KEY, C.BTN_TOOL_PEN, 1)
        emit(C.EV_ABS, C.ABS_X, xTranslate)
        emit(C.EV_ABS, C.ABS_Y, yTranslate)
        emit(C.EV_ABS, C.ABS_PRESSURE, dTranslate)
        emit(C.EV_SYN, C.SYN_REPORT, 0)
    elseif inputType == 0x30 then -- INPUT_BTN_PRESS
        local key = 0
        if x == 0 then key = 105 -- KEY_LEFT
        elseif x == 1 then key = 102 -- KEY_HOME
        elseif x == 2 then key = 106 -- KEY_RIGHT
        end
        emit(C.EV_KEY, key, 1)
        emit(C.EV_SYN, C.SYN_REPORT, 0)
    elseif inputType == 0x31 then -- INPUT_BTN_RELEASE
        local key = 0
        if x == 0 then key = 105
        elseif x == 1 then key = 102
        elseif x == 2 then key = 106
        end
        emit(C.EV_KEY, key, 0)
        emit(C.EV_SYN, C.SYN_REPORT, 0)
    end

    return events
end

function input:open()
    return true
end

function input:close()
    return true
end

function input:closeAll()
    return true
end

function input.waitForEvent(sec, usec)
    local Device = require("device")
    local sock = Device.screen.sock
    if not sock or sock == -1 then
        return false, C.ETIME
    end

    local pollfd = ffi.new("struct pollfd[1]")
    pollfd[0].fd = sock
    pollfd[0].events = C.POLLIN

    local timeout_ms = sec and math.floor(sec * 1000 + usec / 1000) or -1
    local res = C.poll(pollfd, 1, timeout_ms)

    if res > 0 and bit.band(pollfd[0].revents, 1) ~= 0 then
        local msg = ffi.new("struct ServerMessage")
        local n = C.recv(sock, msg, ffi.sizeof(msg), 0)
        if n == ffi.sizeof(msg) and msg.type == qtfb.MESSAGE_USERINPUT then
            local evs = translate_input(msg)
            if #evs > 0 then
                return true, evs
            end
        end
    end

    return false, C.ETIME
end

return input
