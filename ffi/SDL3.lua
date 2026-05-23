--[[--
Module for interfacing SDL 3.0 video/input facilities

This module is intended to provide input/output facilities on a
typical desktop (rather than a dedicated e-ink reader, for which
there would probably be raw framebuffer/input device access
instead).

@module ffi.sdl3
]]

local bit = require("bit")
local ffi = require("ffi")
local util = require("ffi/util")
local C = ffi.C

require("ffi/posix_h")
require("ffi/SDL3_h")
require("ffi/linux_input_h")

-----------------------------------------------------------------

local SDL = util.loadSDL3()

-- Some features (like SDL_RumbleGamepad) may require a minimum version
-- of SDL. These helper functions allow us to prevent any issues with calling
-- undefined symbols.
local sdl_linked_ver = SDL.SDL_GetVersion()

local function toluastring(cstr)
    local lstr = ffi.string(cstr)
    SDL.SDL_free(cstr)
    return lstr
end

local function getSDLVersion()
    local major = math.floor(sdl_linked_ver / 1000000)
    local minor = math.floor(sdl_linked_ver / 1000) % 1000
    local patch = sdl_linked_ver % 1000
    return major, minor, patch
end

local S = {
    w = 0, h = 0,
    win_w = 0, win_h = 0,
    screen = nil,
    renderer = nil,
    texture = nil,
    SDL = SDL,
}

local function openGameController()
    local num_joysticks = ffi.new("int[1]")
    local joystick_ids = SDL.SDL_GetJoysticks(num_joysticks)

    if joystick_ids == nil then
        S.controller = nil
        io.write("SDL: no gamecontrollers connected", "\n")
        return
    end

    joystick_ids = ffi.gc(joystick_ids, SDL.SDL_free)

    for joystick_counter = 0, num_joysticks[0]-1 do
        local joystick = joystick_ids[joystick_counter]
        if SDL.SDL_IsGamepad(joystick) then
            S.controller = SDL.SDL_OpenGamepad(joystick);
            if S.controller ~= nil then
                S.controller = ffi.gc(S.controller, SDL.SDL_CloseGamepad)
                io.write("SDL: opened gamecontroller ", joystick, ": ",
                         ffi.string(SDL.SDL_GetGamepadNameForID(joystick)), "\n");
                break
            else
                io.write("SDL: could not open gamecontroller ",joystick_counter, ": ",
                         ffi.string(SDL.SDL_GetGamepadNameForID(joystick)), "\n");
            end
        end
    end
end

-- initialization for both input and eink output
function S.open(w, h, x, y)
    if SDL.SDL_WasInit(SDL.SDL_INIT_VIDEO) ~= 0 then
        -- already initialized
        return true
    end

    SDL.SDL_SetMainReady()

    if os.getenv("XDG_CURRENT_DESKTOP") == "Lomiri" then
        -- Prefer X11 over Wayland on Ubuntu Touch.
        -- Cf. https://github.com/koreader/koreader/issues/4960#issuecomment-4519022077
        SDL.SDL_SetHint("SDL_VIDEO_DRIVER", "x11")
    end

    if SDL.SDL_Init(bit.bor(SDL.SDL_INIT_VIDEO,
                            SDL.SDL_INIT_EVENTS,
                            SDL.SDL_INIT_GAMEPAD)) == 0 then
        error("Cannot initialize SDL: " .. ffi.string(SDL.SDL_GetError()))
    end

    print(string.format("Started SDL in %s using %s video driver", ffi.string(SDL.SDL_GetBasePath()), ffi.string(SDL.SDL_GetCurrentVideoDriver())))

    local full_screen = os.getenv("SDL_FULLSCREEN")
    if full_screen then
        local mode = SDL.SDL_GetCurrentDisplayMode(SDL.SDL_GetPrimaryDisplay())
        if mode == nil then
            error("SDL cannot get current display mode: " .. ffi.string(SDL.SDL_GetError()))
        end
        S.win_w, S.win_h = mode.w, mode.h
    else
        S.win_w = tonumber(os.getenv("EMULATE_READER_W")) or w or 600
        S.win_h = tonumber(os.getenv("EMULATE_READER_H")) or h or 800
    end

    -- Allow clicks that focus the window to pass through as input events (macOS).
    SDL.SDL_SetHint("SDL_MOUSE_FOCUS_CLICKTHROUGH", "1")

    -- Enable VSYNC.
    SDL.SDL_SetHint("SDL_RENDER_VSYNC", "1")

    -- Enable screensaver and X11 composition.
    SDL.SDL_EnableScreenSaver()
    SDL.SDL_SetHint("SDL_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR", "0")

    -- set up screen (window)
    local pos_x = tonumber(os.getenv("KOREADER_WINDOW_POS_X")) or x or SDL.SDL_WINDOWPOS_UNDEFINED
    local pos_y = tonumber(os.getenv("KOREADER_WINDOW_POS_Y")) or y or SDL.SDL_WINDOWPOS_UNDEFINED
    S.screen = SDL.SDL_CreateWindow("KOReader",
        S.win_w, S.win_h,
        bit.bor(full_screen and SDL.SDL_WINDOW_FULLSCREEN or 0, SDL.SDL_WINDOW_RESIZABLE, SDL.SDL_WINDOW_HIGH_PIXEL_DENSITY)
    )
    -- For some mysterious reason, CreateWindow doesn't give a damn about the initial position, and will enforce top-left (we get an SDL_EVENT_WINDOW_MOVED), so, force its hand...
    -- What's even more curious is that we still only get a single SDL_EVENT_WINDOW_MOVED on startup, except that way it's at the requested coordinates...
    SDL.SDL_SetWindowPosition(S.screen, pos_x, pos_y)

    SDL.SDL_SyncWindow(S.screen)

    -- Disable TextInput until we enable it.
    -- Also see <https://github.com/slouken/SDL/commit/c0f9a3d814a815ec6e2822d7fd2e8648df79f7b9>.
    S:stopTextInput()

    S.renderer = SDL.SDL_CreateRenderer(S.screen, nil)
    local output_w = ffi.new("int[1]", 0)
    local output_h = ffi.new("int[1]", 0)
    if SDL.SDL_GetCurrentRenderOutputSize(S.renderer, output_w, output_h) and tonumber(output_w[0]) ~= w then
        -- This is a workaround to obtain a simulacrum of real pixels in scenarios that marketing likes to refer to as "HiDPI".
        -- The utterly deranged idea is to render things at 2x or 3x, so it can subsequently be scaled down in order to assure everything will always be at least a little bit blurry unless you happen to use exactly 2x or 3x, instead of the traditional methods of just rendering at the desired DPI that have worked perfectly fine in Windows and X11 for decades.
        -- Contrary to claims by the blind that macOS is sharp, it's not.
        -- Wayland is a bad derivative of macOS. Everything macOS does wrong it does worse.
        -- tl;dr Use Windows or X11 if you value your eyes and sanity. Or *gulp* Android. And Sailfish of course.
        S.w = tonumber(output_w[0])
        S.h = tonumber(output_h[0])
    else
        S.w = S.win_w
        S.h = S.win_h
    end
    S.texture = S.createTexture()
end

function S.startTextInput()
    -- Start delivering Unicode text as well as keypresses - this will
    -- handle things like Shift-numbers and letters according to the layout
    -- and will deliver SDL_EVENT_TEXT_INPUT with that text.
    SDL.SDL_StartTextInput(S.screen)
end

function S.stopTextInput()
    SDL.SDL_StopTextInput(S.screen)
end

function S.createTexture(w, h)
    w = w or S.w
    h = h or S.h

    return SDL.SDL_CreateTexture(
        S.renderer,
        SDL.SDL_PIXELFORMAT_RGBA32,
        SDL.SDL_TEXTUREACCESS_STREAMING,
        w, h)
end

function S.setWindowFullscreen(full_screen)
    if not SDL.SDL_SetWindowFullscreen(S.screen, full_screen) or not SDL.SDL_SyncWindow(S.screen) then
        return nil, ffi.string(SDL.SDL_GetError())
    end
    return true
end

function S.destroyTexture(texture)
    SDL.SDL_DestroyTexture(texture)
end

local rect = ffi.metatype("SDL_Rect", {})
function S.rect(x, y, w, h)
    return rect(x, y, w, h)
end

-- one SDL event can generate more than one event for koreader,
-- so this represents a FIFO queue
local inputQueue = {}

local function genEmuEvent(evtype, code, value)
    -- NOTE: SDL timestamps are in ms since application startup, which doesn't tell us anything useful,
    --       so, use synthetic ones in the same timescale as the UI.
    local timespec = ffi.new("struct timespec")
    C.clock_gettime(C.CLOCK_MONOTONIC_COARSE, timespec)
    local timev = {
        sec = tonumber(timespec.tv_sec),
        -- ns to µs
        usec = math.floor(tonumber(timespec.tv_nsec / 1000)),
    }

    local ev = {
        type = tonumber(evtype),
        code = tonumber(code),
        value = tonumber(value) or value,
        time = timev,
    }
    table.insert(inputQueue, ev)
end

-- Keep track of mouse buttons and touch contacts separately, so we can feed ABS_MT_SLOT 0 and 1 to the frontend for multitouch to work.
-- Mouse buttons are keyed by slot, while touch contacts are keyed by fingerID.
local pointers = {}
local finger_pointers = {}
local pen_pointers = {}
local suppress_mouse_until_sec = 0
local suppress_mouse_until_usec = 0
local pen_button_state = {
    [C.BTN_STYLUS] = false,
    [C.BTN_STYLUS2] = false,
}
local pen_tool_state = {
    [C.BTN_TOOL_PEN] = false,
    [C.BTN_TOOL_RUBBER] = false,
}

local SDL_TOUCH_MOUSEID = 0xFFFFFFFF -- ((SDL_MouseID)-1), generated as signed -1 in our cdefs.
local SDL_PEN_MOUSEID = 0xFFFFFFFE -- ((SDL_MouseID)-2), not generated in our cdefs.
local SDL_PEN_SLOT = 4
local TOOL_TYPE_FINGER = 0
local TOOL_TYPE_PEN = 1
local TOOL_TYPE_ERASER = 2
local SDL_PEN_INPUT_DOWN = bit.lshift(1, 0)
local SDL_PEN_INPUT_BUTTON_1 = bit.lshift(1, 1)
local SDL_PEN_INPUT_BUTTON_2 = bit.lshift(1, 2)
local SDL_PEN_INPUT_ERASER_TIP = bit.lshift(1, 30)

local function isMousePointer(which)
    local pointer_id = tonumber(which)
    return pointer_id ~= SDL_TOUCH_MOUSEID and pointer_id ~= SDL_PEN_MOUSEID
end

local function shouldHandleMousePointer(which)
    if not isMousePointer(which) then
        return false
    end
    local now_sec, now_usec = util.gettime()
    return now_sec > suppress_mouse_until_sec
        or (now_sec == suppress_mouse_until_sec and now_usec >= suppress_mouse_until_usec)
end

local function hasPenFlag(pen_state, flag)
    return bit.band(tonumber(pen_state) or 0, flag) ~= 0
end

local function getPenTool(eraser, pen_state)
    if eraser or hasPenFlag(pen_state, SDL_PEN_INPUT_ERASER_TIP) then
        return TOOL_TYPE_ERASER
    end
    return TOOL_TYPE_PEN
end

local function setPenButtonState(code, down)
    if not code or pen_button_state[code] == down then
        return
    end
    pen_button_state[code] = down
    genEmuEvent(C.EV_KEY, code, down and 1 or 0)
end

local function syncPenButtons(pen_state)
    setPenButtonState(C.BTN_STYLUS, hasPenFlag(pen_state, SDL_PEN_INPUT_BUTTON_1))
    setPenButtonState(C.BTN_STYLUS2, hasPenFlag(pen_state, SDL_PEN_INPUT_BUTTON_2))
end

local function getPenToolKey(tool)
    return tool == TOOL_TYPE_ERASER and C.BTN_TOOL_RUBBER or C.BTN_TOOL_PEN
end

local function setPenToolState(tool, down)
    local code = getPenToolKey(tool)
    if down then
        for active_code, active in pairs(pen_tool_state) do
            if active_code ~= code and active then
                pen_tool_state[active_code] = false
                genEmuEvent(C.EV_KEY, active_code, 0)
            end
        end
    end
    if pen_tool_state[code] == down then
        return
    end
    pen_tool_state[code] = down
    genEmuEvent(C.EV_KEY, code, down and 1 or 0)
end

local function clearPenToolState()
    for code, active in pairs(pen_tool_state) do
        if active then
            pen_tool_state[code] = false
            genEmuEvent(C.EV_KEY, code, 0)
        end
    end
end

local function genPenDownEvent(slot, tracking_id, tool, x, y)
    setPenToolState(tool, true)
    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, slot)
    genEmuEvent(C.EV_ABS, C.ABS_MT_TOOL_TYPE, tool)
    genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, tracking_id)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, x)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, y)
    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
end

local function genPenUpEvent(slot, tool, x, y)
    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, slot)
    genEmuEvent(C.EV_ABS, C.ABS_MT_TOOL_TYPE, tool)
    genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, -1)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, x)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, y)
    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
end

local function genPenMoveEvent(slot, tool, x, y)
    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, slot)
    genEmuEvent(C.EV_ABS, C.ABS_MT_TOOL_TYPE, tool)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, x)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, y)
    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
end

local function genPenHoverEvent(slot, tool, x, y)
    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, slot)
    genEmuEvent(C.EV_ABS, C.ABS_MT_TOOL_TYPE, tool)
    genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, -1)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, x)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, y)
    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
end

local function getPenTrackingID(pen_id)
    return pen_id ~= 0 and pen_id or SDL_PEN_SLOT
end

local function getPenPointer(pen_id)
    if not pen_pointers[pen_id] then
        pen_pointers[pen_id] = {
            down = false,
            tracking_id = getPenTrackingID(pen_id),
            tool = TOOL_TYPE_PEN,
        }
    end
    return pen_pointers[pen_id]
end

local function beginPenProximity(pen_id, tool, explicit)
    local pointer = getPenPointer(pen_id)
    pointer.in_proximity = true
    pointer.explicit_proximity = pointer.explicit_proximity or explicit
    pointer.tool = tool or pointer.tool or TOOL_TYPE_PEN
    setPenToolState(pointer.tool, true)
    return pointer
end

local function endImplicitPenProximity(pen_id)
    local pointer = pen_pointers[pen_id]
    if pointer and not pointer.down and not pointer.explicit_proximity then
        pen_pointers[pen_id] = nil
        clearPenToolState()
    end
end

local function endPenProximity(pen_id)
    local pointer = pen_pointers[pen_id]
    if pointer and pointer.down then
        genPenUpEvent(SDL_PEN_SLOT, pointer.tool or TOOL_TYPE_PEN, pointer.x or 0, pointer.y or 0)
    end
    if pointer and pointer.x and pointer.y then
        genPenHoverEvent(SDL_PEN_SLOT, TOOL_TYPE_FINGER, pointer.x, pointer.y)
    end
    pen_pointers[pen_id] = nil
    clearPenToolState()
end

local function updatePenHover(pen_id, tool, x, y)
    local pointer = beginPenProximity(pen_id, tool, false)
    pointer.tool = tool
    pointer.x = x
    pointer.y = y
    genPenHoverEvent(SDL_PEN_SLOT, tool, x, y)
end

local function updatePenContact(pen_id, pen_state, tool, x, y)
    local pointer = pen_pointers[pen_id]
    local is_down = hasPenFlag(pen_state, SDL_PEN_INPUT_DOWN) or (pointer and pointer.down)
    if not is_down then
        updatePenHover(pen_id, tool, x, y)
        return
    end

    pointer = beginPenProximity(pen_id, tool, false)

    if pointer.down then
        genPenMoveEvent(SDL_PEN_SLOT, tool, x, y)
    else
        genPenDownEvent(SDL_PEN_SLOT, pointer.tracking_id, tool, x, y)
    end

    pointer.down = true
    pointer.tool = tool
    pointer.x = x
    pointer.y = y
end

local function endPenContact(pen_id, tool, x, y)
    local pointer = pen_pointers[pen_id]
    if not pointer or not pointer.down then
        return
    end

    genPenUpEvent(SDL_PEN_SLOT, tool or pointer.tool or TOOL_TYPE_PEN, x or pointer.x or 0, y or pointer.y or 0)
    pointer.down = false
    pointer.tool = tool or pointer.tool
    pointer.x = x or pointer.x
    pointer.y = y or pointer.y
end

local function setPointerDownState(slot, down, x, y)
    if not pointers[slot] then
        pointers[slot] = { down = down, x = x, y = y }
    else
        pointers[slot].down = down
        pointers[slot].x = x or pointers[slot].x
        pointers[slot].y = y or pointers[slot].y
    end
end

local function getFingerSlot(event)
    local finger_id = tonumber(event.tfinger.fingerID)
    if not finger_pointers[finger_id] then
        local used_slots = {}
        for _, pointer in pairs(finger_pointers) do
            used_slots[pointer.slot] = true
        end
        local slot = 0
        while used_slots[slot] do
            slot = slot + 1
        end
        finger_pointers[finger_id] = { slot = slot }
    end
    return finger_pointers[finger_id].slot
end

local function genTouchDownEvent(event, slot, x, y)
    local is_finger = event.type == SDL.SDL_EVENT_FINGER_DOWN
    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, slot)
    genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, is_finger and tonumber(event.tfinger.fingerID) or slot)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, x)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, y)
    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
end

local function genTouchUpEvent(event, slot, x, y)
    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, slot)
    genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, -1)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, x)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, y)
    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
end

local function releaseMousePointers()
    for slot, pointer in pairs(pointers) do
        if pointer.down then
            genTouchUpEvent(nil, slot, pointer.x or 0, pointer.y or 0)
        end
    end
    pointers = {}
end

local function suppressMousePointersAfterPenEvent()
    local sec, usec = util.gettime()
    usec = usec + 350000
    if usec >= 1000000 then
        sec = sec + 1
        usec = usec - 1000000
    end
    suppress_mouse_until_sec = sec
    suppress_mouse_until_usec = usec
    releaseMousePointers()
end

local function genTouchMoveEvent(event, slot, x, y)
    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, slot)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, x)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, y)
    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
end

local last_joystick_event_secs = 0
local last_joystick_event_usecs = 0

local function handleJoyAxisMotionEvent(event)
    local axis_ev = event.jaxis
    local value = axis_ev.value

    local neutral_max_val = 5000
    local min_time_since_last_ev = 0.3

    -- ignore random neutral fluctuations
    if (value > -neutral_max_val) and (value < neutral_max_val) then return end

    local current_ev_s, current_ev_us = util.gettime()

    local since_last_ev = current_ev_s-last_joystick_event_secs + (current_ev_us-last_joystick_event_usecs)/1000000

    local axis = axis_ev.axis

    if since_last_ev <= min_time_since_last_ev then return end

    -- left stick 0/1
    if axis == 0 then
        if value < -neutral_max_val then
            -- send left
            genEmuEvent(C.EV_KEY, 1073741904, 1)
        else
            -- send right
            genEmuEvent(C.EV_KEY, 1073741903, 1)
        end
    elseif axis == 1 then
        if value < -neutral_max_val then
            -- send up
            genEmuEvent(C.EV_KEY, 1073741906, 1)
        else
            -- send down
            genEmuEvent(C.EV_KEY, 1073741905, 1)
        end
    -- right stick 3/4
    elseif axis == 4 then
        if value < -neutral_max_val then
            -- send page up
            genEmuEvent(C.EV_KEY, 1073741899, 1)
        else
            -- send page down
            genEmuEvent(C.EV_KEY, 1073741902, 1)
        end
    -- left trigger 2
    -- right trigger 5
    end

    last_joystick_event_secs, last_joystick_event_usecs = util.gettime()
end

function S.waitForEvent(sec, usec)
    local event = ffi.new("union SDL_Event")
    -- TimeVal to ms if we were passed one to begin with, otherwise, -1 => block.
    -- NOTE: Since we have *less* precision than a timeval, we round *up*, to avoid passing zero for < 1ms timevals.
    local timeout = sec and math.ceil((sec * 1000000 + usec) * (1/1000)) or -1

    -- Reset the queue
    inputQueue = {}

    -- Wait for event
    if not SDL.SDL_WaitEventTimeout(event, timeout) then
        -- ETIME
        return false, C.ETIME
    end

    -- Used to scale coordinates of pointer events if ouput scaling is used
    local scale_x = S.w / S.win_w
    local scale_y = S.h / S.win_h

    -- if we got an event, examine it here and generate events for koreader
    if event.type == SDL.SDL_EVENT_KEY_DOWN then
        genEmuEvent(C.EV_KEY, event.key.key, 1)
    elseif event.type == SDL.SDL_EVENT_KEY_UP then
        genEmuEvent(C.EV_KEY, event.key.key, 0)
    elseif event.type == SDL.SDL_EVENT_TEXT_INPUT then
        genEmuEvent(C.EV_SDL, SDL.SDL_EVENT_TEXT_INPUT, ffi.string(event.text.text))
    elseif event.type == SDL.SDL_EVENT_PEN_PROXIMITY_IN then
        local pen_id = tonumber(event.pproximity.which)
        suppressMousePointersAfterPenEvent()
        beginPenProximity(pen_id, TOOL_TYPE_PEN, true)
    elseif event.type == SDL.SDL_EVENT_PEN_DOWN then
        local pen_id = tonumber(event.ptouch.which)
        local pen_state = bit.bor(tonumber(event.ptouch.pen_state) or 0, event.ptouch.down and SDL_PEN_INPUT_DOWN or 0)
        local tool = getPenTool(event.ptouch.eraser, pen_state)
        local x = event.ptouch.x * scale_x
        local y = event.ptouch.y * scale_y
        suppressMousePointersAfterPenEvent()
        syncPenButtons(pen_state)
        updatePenContact(pen_id, pen_state, tool, x, y)
    elseif event.type == SDL.SDL_EVENT_PEN_UP then
        local pen_id = tonumber(event.ptouch.which)
        local pen_state = tonumber(event.ptouch.pen_state) or 0
        local tool = getPenTool(event.ptouch.eraser, pen_state)
        local x = event.ptouch.x * scale_x
        local y = event.ptouch.y * scale_y
        suppressMousePointersAfterPenEvent()
        syncPenButtons(pen_state)
        endPenContact(pen_id, tool, x, y)
        endImplicitPenProximity(pen_id)
    elseif event.type == SDL.SDL_EVENT_PEN_MOTION then
        local pen_id = tonumber(event.pmotion.which)
        local pen_state = tonumber(event.pmotion.pen_state) or 0
        local tool = getPenTool(false, pen_state)
        suppressMousePointersAfterPenEvent()
        syncPenButtons(pen_state)
        updatePenContact(pen_id, pen_state, tool, event.pmotion.x * scale_x, event.pmotion.y * scale_y)
    elseif event.type == SDL.SDL_EVENT_PEN_AXIS then
        local pen_id = tonumber(event.paxis.which)
        local pen_state = tonumber(event.paxis.pen_state) or 0
        local tool = getPenTool(false, pen_state)
        suppressMousePointersAfterPenEvent()
        syncPenButtons(pen_state)
        updatePenContact(pen_id, pen_state, tool, event.paxis.x * scale_x, event.paxis.y * scale_y)
    elseif event.type == SDL.SDL_EVENT_PEN_BUTTON_DOWN
        or event.type == SDL.SDL_EVENT_PEN_BUTTON_UP then
        local pen_id = tonumber(event.pbutton.which)
        local pen_state = tonumber(event.pbutton.pen_state) or 0
        local tool = getPenTool(false, pen_state)
        local x = event.pbutton.x * scale_x
        local y = event.pbutton.y * scale_y
        local button_code
        suppressMousePointersAfterPenEvent()
        if event.pbutton.button == 1 then
            button_code = C.BTN_STYLUS
        elseif event.pbutton.button == 2 then
            button_code = C.BTN_STYLUS2
        end
        setPenButtonState(button_code, event.type == SDL.SDL_EVENT_PEN_BUTTON_DOWN)
        updatePenContact(pen_id, pen_state, tool, x, y)
    elseif event.type == SDL.SDL_EVENT_PEN_PROXIMITY_OUT then
        local pen_id = tonumber(event.pproximity.which)
        suppressMousePointersAfterPenEvent()
        endPenProximity(pen_id)
        syncPenButtons(0)
    elseif event.type == SDL.SDL_EVENT_MOUSE_MOTION and shouldHandleMousePointer(event.motion.which)
        or event.type == SDL.SDL_EVENT_FINGER_MOTION then
        local is_finger = event.type == SDL.SDL_EVENT_FINGER_MOTION
        local slot

        if is_finger then
            slot = getFingerSlot(event)
            genTouchMoveEvent(event, slot, event.tfinger.x * S.w, event.tfinger.y * S.h)
        else
            if pointers[0] and pointers[0].down then
                slot = 0 -- left mouse button down
                local x = event.motion.x * scale_x
                local y = event.motion.y * scale_y
                setPointerDownState(slot, true, x, y)
                genTouchMoveEvent(event, slot, x, y)
            end
            if pointers[1] and pointers[1].down then
                slot = 1 -- right mouse button down
                local x = event.motion.x * scale_x
                local y = event.motion.y * scale_y
                setPointerDownState(slot, true, x, y)
                genTouchMoveEvent(event, slot, x, y)
            end
        end
    elseif event.type == SDL.SDL_EVENT_MOUSE_BUTTON_UP and shouldHandleMousePointer(event.button.which)
        or event.type == SDL.SDL_EVENT_FINGER_UP then
        local is_finger = event.type == SDL.SDL_EVENT_FINGER_UP
        local slot
        if is_finger then
            slot = getFingerSlot(event)
        elseif event.button.button == SDL.SDL_BUTTON_RIGHT then
            slot = 1
        else -- SDL_BUTTON_LEFT
            slot = 0
        end
        if not is_finger and not (pointers[slot] and pointers[slot].down) then
            return false, C.EINTR
        end

        local x = is_finger and event.tfinger.x * S.w or event.button.x * scale_x
        local y = is_finger and event.tfinger.y * S.h or event.button.y * scale_y
        genTouchUpEvent(event, slot, x, y)
        if is_finger then
            finger_pointers[tonumber(event.tfinger.fingerID)] = nil
        else
            pointers[slot] = nil
        end
    elseif event.type == SDL.SDL_EVENT_MOUSE_BUTTON_DOWN and shouldHandleMousePointer(event.button.which)
        or event.type == SDL.SDL_EVENT_FINGER_DOWN then
        local is_finger = event.type == SDL.SDL_EVENT_FINGER_DOWN
        if not is_finger and not (event.button.button == SDL.SDL_BUTTON_LEFT or event.button.button == SDL.SDL_BUTTON_RIGHT) then
            -- We don't do anything with extra buttons for now.
            return false, C.ENOSYS
        end

        -- use mouse click to simulate single tap
        local slot
        if is_finger then
            slot = getFingerSlot(event)
        elseif event.button.button == SDL.SDL_BUTTON_RIGHT then
            slot = 1
        else -- SDL_BUTTON_LEFT
            slot = 0
        end
        local x = is_finger and event.tfinger.x * S.w or event.button.x * scale_x
        local y = is_finger and event.tfinger.y * S.h or event.button.y * scale_y
        if not is_finger then
            setPointerDownState(slot, true, x, y)
        end
        genTouchDownEvent(event, slot, x, y)
    elseif event.type == SDL.SDL_EVENT_MOUSE_WHEEL then
        genEmuEvent(C.EV_SDL, SDL.SDL_EVENT_MOUSE_WHEEL, event.wheel)
    elseif event.type == SDL.SDL_EVENT_DROP_FILE then
        local dropped_file_path = ffi.string(event.drop.data)
        genEmuEvent(C.EV_SDL, SDL.SDL_EVENT_DROP_FILE, dropped_file_path)
    elseif event.type == SDL.SDL_EVENT_DROP_TEXT then
        local dropped_text = ffi.string(event.drop.data)
        genEmuEvent(C.EV_SDL, SDL.SDL_EVENT_DROP_TEXT, dropped_text)
    elseif event.type == SDL.SDL_EVENT_WINDOW_EXPOSED then
        -- The next buffer might always contain garbage, and on X11 without
        -- compositing the buffers will be damaged just by moving the window
        -- partly offscreen, minimizing it, or putting another window
        -- (partially) on top of it.
        -- Handling `SDL_EVENT_WINDOW_EXPOSED` is the only way to deal with
        -- this without sending regular updates.
        SDL.SDL_RenderTexture(S.renderer, S.texture, nil, nil)
        SDL.SDL_RenderPresent(S.renderer)
    elseif (event.type == SDL.SDL_EVENT_WINDOW_RESIZED
             or event.type == SDL.SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED
             or event.type == SDL.SDL_EVENT_WINDOW_MOVED) then
        genEmuEvent(C.EV_SDL, event.type, event.window)

    --- Gamepad support ---
    -- For debugging it can be helpful to use:
    -- print(ffi.string(SDL.SDL_GetGamepadStringForButton(button)))
    -- @TODO Proper support instead of faux keyboard presses
    --
    --- Controllers ---
    elseif event.type == SDL.SDL_EVENT_GAMEPAD_ADDED
            or event.type == SDL.SDL_EVENT_GAMEPAD_REMOVED
            or event.type == SDL.SDL_EVENT_GAMEPAD_REMAPPED then
        openGameController()
    --- Sticks & triggers ---
    elseif event.type == SDL.SDL_EVENT_JOYSTICK_AXIS_MOTION then
        handleJoyAxisMotionEvent(event)
    --- Buttons (such as A, B, X, Y) ---
    elseif event.type == SDL.SDL_EVENT_JOYSTICK_BUTTON_DOWN then
        local button = event.gbutton.button

        if button == SDL.SDL_GAMEPAD_BUTTON_SOUTH then
            -- send enter
            genEmuEvent(C.EV_KEY, 13, 1)
            -- send end (bound to press)
            genEmuEvent(C.EV_KEY, 1073741901, 1)
        elseif button == SDL.SDL_GAMEPAD_BUTTON_EAST then
            -- send escape
            genEmuEvent(C.EV_KEY, 27, 1)
        elseif button == SDL.SDL_GAMEPAD_BUTTON_NORTH then
            -- send ContextMenu
            genEmuEvent(C.EV_KEY, 1073741925, 1)
        -- left bumper
        elseif button == SDL.SDL_GAMEPAD_BUTTON_BACK then
            -- send page up
            genEmuEvent(C.EV_KEY, 1073741899, 1)
        -- right bumper
        elseif button == SDL.SDL_GAMEPAD_BUTTON_GUIDE then
            -- send page down
            genEmuEvent(C.EV_KEY, 1073741902, 1)
        -- On the Xbox One controller, start = start but leftstick = menu button
        elseif button == SDL.SDL_GAMEPAD_BUTTON_START or button == SDL.SDL_GAMEPAD_BUTTON_LEFT_STICK then
            -- send F1 (bound to menu in front at the time of writing)
            genEmuEvent(C.EV_KEY, 1073741882, 1)
        elseif button == SDL.SDL_GAMEPAD_BUTTON_DPAD_UP then
            -- send up
            genEmuEvent(C.EV_KEY, 1073741906, 1)
        elseif button == SDL.SDL_GAMEPAD_BUTTON_DPAD_DOWN then
            -- send down
            genEmuEvent(C.EV_KEY, 1073741905, 1)
        elseif button == SDL.SDL_GAMEPAD_BUTTON_DPAD_LEFT then
            -- send left
            genEmuEvent(C.EV_KEY, 1073741904, 1)
        elseif button == SDL.SDL_GAMEPAD_BUTTON_DPAD_RIGHT then
            -- send right
            genEmuEvent(C.EV_KEY, 1073741903, 1)
        end
    --- D-pad ---
    elseif event.type == SDL.SDL_EVENT_JOYSTICK_HAT_MOTION then
        local hat_position = event.jhat.value

        if hat_position == SDL.SDL_HAT_UP then
            -- send up
            genEmuEvent(C.EV_KEY, 1073741906, 1)
        elseif hat_position == SDL.SDL_HAT_DOWN then
            -- send down
            genEmuEvent(C.EV_KEY, 1073741905, 1)
        elseif hat_position == SDL.SDL_HAT_LEFT then
            -- send left
            genEmuEvent(C.EV_KEY, 1073741904, 1)
        elseif hat_position == SDL.SDL_HAT_RIGHT then
            -- send right
            genEmuEvent(C.EV_KEY, 1073741903, 1)
        end
    elseif event.type == SDL.SDL_EVENT_QUIT then
        -- NOTE: Generated on SIGTERM, among other things. (Not SIGINT, because LuaJIT already installs a handler for that).
        -- send Alt + F4
        genEmuEvent(C.EV_KEY, 1073742050, 1)
        genEmuEvent(C.EV_KEY, 1073741885, 1)
    end

    if #inputQueue > 0 then
        -- We generated some actionable events
        return true, inputQueue
    else
        -- SDL returned early, but without an event we actually use.
        -- Back to Input:waitEvent to recompute the timeout
        return false, C.EINTR
    end
end

function S.hasClipboardText()
    return SDL.SDL_HasClipboardText()
end

function S.getClipboardText()
    return toluastring(SDL.SDL_GetClipboardText())
end

function S.setClipboardText(text)
    return SDL.SDL_SetClipboardText(text)
end

function S.setWindowIcon(icon)
    if not icon then error("setWindowIcon: no icon path given") end

    local Png = require("ffi/png")
    local ok, re = Png.decodeFromFile(icon, 4)
    if not ok then
        error(re.." ("..icon..")")
    end

    local BB = require("ffi/blitbuffer")
    local icon_bb = BB.new(re.width, re.height, BB.TYPE_BBRGB32, re.data)
    icon_bb:setAllocated(1) -- free re.data when bb is freed
    local surface = SDL.SDL_CreateSurfaceFrom(
        icon_bb:getWidth(), icon_bb:getHeight(),
        SDL.SDL_PIXELFORMAT_RGBA32,
        icon_bb.data, icon_bb.stride
    )
    SDL.SDL_SetWindowIcon(S.screen, surface)
    SDL.SDL_DestroySurface(surface)
    icon_bb:free()
end

function S.gameControllerRumble(left_intensity, right_intensity, duration)
    if S.controller == nil then
        return
    end

    left_intensity = left_intensity or 20000
    right_intensity = right_intensity or 20000
    duration = duration or 200

    return SDL.SDL_RumbleGamepad(S.controller, left_intensity, right_intensity, duration)
end

function S.getPlatform()
    return ffi.string(SDL.SDL_GetPlatform())
end

function S.getPowerInfo()
    local batt = false
    local plugged = false
    local charging = false
    local ptr = ffi.new("int[1]", {0})
    local battery_info = SDL.SDL_GetPowerInfo(nil, ptr)
    if battery_info == SDL.SDL_POWERSTATE_UNKNOWN
        or battery_info == SDL.SDL_POWERSTATE_NO_BATTERY
    then
        plugged = true
    elseif battery_info == SDL.SDL_POWERSTATE_ON_BATTERY then
        batt = true
    elseif battery_info == SDL.SDL_POWERSTATE_CHARGING then
        batt = true
        charging = true
        plugged = true
    elseif battery_info == SDL.SDL_POWERSTATE_CHARGED then
        batt = true
        plugged = true
    end
    local percent = ptr[0]
    return batt, charging, plugged, percent
end

function S.getVersion()
    return string.format("%d.%d.%d", getSDLVersion())
end

-- On Linux, fork() can hang if SDL3's gamepad/joystick subsystem background
-- thread is mid-malloc when fork() is called: glibc's atfork prepare handler
-- blocks waiting for all malloc arenas, and on schedulers like CachyOS's
-- BORE/LAVD the SDL thread may not release the arena for seconds, making the
-- KOReader window appear completely unresponsive (GNOME "Not Responding").
-- Fix: stop the gamepad subsystem (and its thread) just before fork(), then
-- restart it in the parent once fork() has returned.
if ffi.os == "Linux" then
    local gamepad_was_init = false
    util.addRunBeforeForkFunc("sdl_gamepad_quiesce", function()
        gamepad_was_init = SDL.SDL_WasInit(SDL.SDL_INIT_GAMEPAD) ~= 0
        if gamepad_was_init then
            -- Explicitly close the open gamepad handle before shutting down the
            -- subsystem, so the ffi.gc finalizer doesn't later call SDL_CloseGamepad
            -- on a stale pointer (after the subsystem restarts in the parent).
            if S.controller ~= nil then
                local ctrl = ffi.gc(S.controller, nil)  -- disarm GC finalizer
                SDL.SDL_CloseGamepad(ctrl)
                S.controller = nil
            end
            SDL.SDL_QuitSubSystem(SDL.SDL_INIT_GAMEPAD)
        end
    end)
    util.addRunAfterForkParentFunc("sdl_gamepad_restore", function()
        if gamepad_was_init then
            gamepad_was_init = false
            SDL.SDL_InitSubSystem(SDL.SDL_INIT_GAMEPAD)
            openGameController()
        end
    end)
end

return S
