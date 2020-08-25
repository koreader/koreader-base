local ffi = require("ffi")
local C = ffi.C
local inkview = ffi.load("inkview")
local util = require("ffi/util")
require("ffi/linux_input_h")

-- luacheck: push
-- luacheck: ignore
local EVT_INIT = 21
local EVT_EXIT = 22
local EVT_SHOW = 23
local EVT_REPAINT = 23
local EVT_HIDE = 24
local EVT_KEYDOWN = 25
local EVT_KEYPRESS = 25
local EVT_KEYUP = 26
local EVT_KEYRELEASE = 26
local EVT_KEYREPEAT = 28
local EVT_POINTERUP = 29
local EVT_POINTERDOWN = 30
local EVT_POINTERMOVE = 31
local EVT_ORIENTATION = 32
local EVT_MTSYNC = 39
local EVT_FOREGROUND = 151
local EVT_BACKGROUND = 152

local PANEL_DISABLED = 0
-- luacheck: pop

ffi.cdef [[
typedef int  (*iv_handler)(int type, int par1, int par2);
void PrepareForLoop(iv_handler handler);
void ProcessEventLoop();
void ClearOnExit();
void SetPanelType(int type);

typedef struct iv_mtinfo_s {
    int active;
    int x;
    int y;
    int pressure;
    int rsv[4];
} iv_mtinfo;
iv_mtinfo *GetTouchInfo();
iv_mtinfo *GetTouchInfoI(int i); // Newer inkview versions support only the I variant.
]]

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
    if t == EVT_INIT then
        inkview.SetPanelType(PANEL_DISABLED);
    elseif t == EVT_POINTERDOWN then
        nTouch = 1
        genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, 0)
        genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, par1)
        genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, par2)
    elseif t == EVT_MTSYNC then
        if nTouch > 0 and par2 == 2 then
            local ok, mt1 = pcall(inkview.GetTouchInfoI, 0)
            local mti
            if not ok then
                ok, mti = pcall(inkview, inkview.GetTouchInfo)
            else
                mti = { [0]=mt1, [1]=inkview.GetTouchInfoI(1) }
            end
            if ok then
                nTouch = 2
                for i = 0, 1 do
                    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, i);
                    genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, i);
                    local mt = mti[i]
                    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, mt.x)
                    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, mt.y)
                    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
                end
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
    elseif t == EVT_POINTERMOVE then
        if nTouch == 1 then
            genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, par1)
            genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, par2)
        end
    elseif t == EVT_POINTERUP then
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
    inkview.PrepareForLoop(translateEvent)
end

local function now()
    local s, u = util.gettime()
    return tonumber(s) * 1000000.0 + u
end

function input.waitForEvent(t)
    assert(eventq, "waitForEvent() invoked after device shutdown")
    if #eventq > 0 then return table.remove(eventq, 1) end
    local expire = now() + t
    while expire > now() do
        inkview.ProcessEventLoop()
        if #eventq > 0 then return table.remove(eventq, 1) end
    end
    error("Waiting for input failed: timeout\n")
end

function input.fakeTapInput() end

function input.closeAll()
    eventq = nil
    inkview.ClearOnExit()
end

return input
