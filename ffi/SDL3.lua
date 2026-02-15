--[[--
Module for interfacing SDL 2.0 video/input facilities

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

    if SDL.SDL_Init(bit.bor(SDL.SDL_INIT_VIDEO,
                            SDL.SDL_INIT_EVENTS,
                            SDL.SDL_INIT_GAMEPAD)) == 0 then
        error("Cannot initialize SDL: " .. ffi.string(SDL.SDL_GetError()))
    end

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
    if SDL.SDL_GetCurrentRenderOutputSize(S.renderer, output_w, output_h) == 0 and tonumber(output_w[0]) ~= w then
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

-- Keep track of active pointers so we can feed ABS_MT_SLOT 0 and 1 to the frontend for multitouch to work.
-- down, a boolean denoting whether the pointer is currently down for tracking mouse button status.
local pointers = {}
local function setPointerDownState(slot, down)
    if not pointers[slot] then
        pointers[slot] = { down = down }
    else
        pointers[slot].down = down
    end
end

-- For the moment we pretend there can only be one touchscreen/trackpad/whatever at a time.
-- It's probably close enough to the truth unless you run into a tester.
local function getFingerSlot(event)
    if not pointers[tonumber(event.tfinger.fingerID)] then
        local num_touch_fingers = ffi.new("int[1]")
        local fingers = SDL.SDL_GetTouchFingers(event.tfinger.touchID, num_touch_fingers)
        if fingers ~= nil then
            fingers = ffi.gc(fingers, SDL.SDL_free)
            for i=0,num_touch_fingers[0]-1 do
                if fingers[i].id == event.tfinger.fingerID then
                    pointers[tonumber(event.tfinger.fingerID)] = { slot = i }
                end
            end
        else
            pointers[tonumber(event.tfinger.fingerID)] = { slot = 0 }
        end
    end
    return pointers[tonumber(event.tfinger.fingerID)].slot
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
    elseif event.type == SDL.SDL_EVENT_MOUSE_MOTION and event.motion.which ~= SDL.SDL_TOUCH_MOUSEID
        or event.type == SDL.SDL_EVENT_FINGER_MOTION then
        local is_finger = event.type == SDL.SDL_EVENT_FINGER_MOTION
        local slot

        if is_finger then
            slot = getFingerSlot(event)
            genTouchMoveEvent(event, slot, event.tfinger.x * S.w, event.tfinger.y * S.h)
        else
            if pointers[0] and pointers[0].down then
                slot = 0 -- left mouse button down
                genTouchMoveEvent(event, slot, event.motion.x * scale_x, event.motion.y * scale_y)
            end
            if pointers[1] and pointers[1].down then
                slot = 1 -- right mouse button down
                genTouchMoveEvent(event, slot, event.motion.x * scale_x, event.motion.y * scale_y)
            end
        end
    elseif event.type == SDL.SDL_EVENT_MOUSE_BUTTON_UP and event.button.which ~= SDL.SDL_TOUCH_MOUSEID
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

        local x = is_finger and event.tfinger.x * S.w or event.button.x * scale_x
        local y = is_finger and event.tfinger.y * S.h or event.button.y * scale_y
        genTouchUpEvent(event, slot, x, y)
        if is_finger then
            pointers[tonumber(event.tfinger.fingerID)] = nil
        else
            pointers[slot] = nil
        end
    elseif event.type == SDL.SDL_EVENT_MOUSE_BUTTON_DOWN and event.button.which ~= SDL.SDL_TOUCH_MOUSEID
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
        setPointerDownState(slot, true)
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

function S.getBasePath()
    return ffi.string(SDL.SDL_GetBasePath())
end

function S.getPrefPath(organization, appname)
    if not organization then organization = "dummy" end
    if not appname then appname = "application" end
    return toluastring(SDL.SDL_GetPrefPath(organization, appname))
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

return S
