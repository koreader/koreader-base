local ffi = require("ffi")
local C = ffi.C
local inkview = ffi.load("inkview")
local util = require("ffi/util")

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
local eventq
local ts
local function genEmuEvent(t,c,v)
    table.insert(eventq, {
        type = tonumber(t),
        code = tonumber(c),
        value = tonumber(v) or v,
        time = ts,
    })
end

local nTouch = 0
local function translateEvent(t, par1, par2)
    if eventq == nil then
        return 0
    end
    local sec, usec = util.gettime()
    ts = { sec = sec, usec = usec }
    if t == C.EVT_INIT then
        inkview.SetPanelType(C.PANEL_DISABLED);
    elseif t == C.EVT_POINTERDOWN then
        nTouch = 1
        genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, 0)
        genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, par1)
        genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, par2)
    elseif t == C.EVT_MTSYNC then
        if nTouch > 0 and par2 == 2 then
            nTouch = 2
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
        if nTouch == 1 then
            genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, par1)
            genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, par2)
        end
    elseif t == C.EVT_POINTERUP then
        if nTouch == 1 then
            genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, -1)
        end
        nTouch = 0
    else
        genEmuEvent(t, par1, par2)
    end
    return 0
end

function input.open()
    eventq = {}
    -- Initialize inkview and connect event queue to monitor.
    compat.PrepareForLoop(translateEvent)
end

local function now()
    local s, u = util.gettime()
    return tonumber(s) * 1000000.0 + u
end

function input.waitForEvent(t)
    t = t or 2000000
    assert(eventq, "waitForEvent() invoked after device shutdown")
    if #eventq > 0 then return table.remove(eventq, 1) end
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
    compat.ClearOnExit()
end

return input
