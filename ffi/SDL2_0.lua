--[[--
Module for interfacing SDL 2.0 video/input facilities

This module is intended to provide input/output facilities on a
typical desktop (rather than a dedicated e-ink reader, for which
there would probably be raw framebuffer/input device access
instead).

@module ffi.sdl2_0
]]

local bit = require("bit")
local ffi = require("ffi")
local util = require("ffi/util")
local C = ffi.C

require("ffi/posix_h")
require("ffi/SDL2_0_h")
require("ffi/linux_input_h")

-----------------------------------------------------------------

local SDL = util.ffiLoadCandidates{
    "SDL2",
    -- this unfortunately needs to be written in full due to the . in the name
    "libSDL2-2.0.so",
    "libSDL2-2.0.so.0",
    "/usr/local/opt/lib/libSDL2.dylib",
    "/opt/homebrew/lib/libSDL2.dylib",
}

-- Some features (like SDL_GameControllerRumble) may require a minimum version
-- of SDL. These helper functions allow us to prevent any issues with calling
-- undefined symbols.
local sdl_linked_ver = ffi.new("struct SDL_version[0]")
SDL.SDL_GetVersion(sdl_linked_ver)

local function getSDLVersion()
    return sdl_linked_ver[0].major, sdl_linked_ver[0].minor, sdl_linked_ver[0].patch
end

-- Just a copy of a C macro that unfortunately can't be used through FFI.
-- This assumes that there will never be more than 100 patchlevels.
local function SDL_VersionNum(x, y, z)
    return x*1000 + y*100 + z
end

local function SDL_Linked_Version_AtLeast(x, y, z)
    return SDL_VersionNum(getSDLVersion()) >= SDL_VersionNum(x, y, z)
end

local S = {
    w = 0, h = 0,
    screen = nil,
    renderer = nil,
    texture = nil,
    SDL = SDL,
}

local function openGameController()
    local num_joysticks = SDL.SDL_NumJoysticks()

    if num_joysticks < 1 then
        S.controller = nil
        io.write("SDL: no gamecontrollers connected", "\n")
        return
    end

    for joystick_counter = 0, num_joysticks-1 do
        if SDL.SDL_IsGameController(joystick_counter) ~= 0 then
            S.controller = SDL.SDL_GameControllerOpen(joystick_counter);
            if S.controller ~= nil then
                io.write("SDL: opened gamecontroller ",joystick_counter, ": ",
                         ffi.string(SDL.SDL_GameControllerNameForIndex(joystick_counter)), "\n");
                break
            else
                io.write("SDL: could not open gamecontroller ",joystick_counter, ": ",
                         ffi.string(SDL.SDL_GameControllerNameForIndex(joystick_counter)), "\n");
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
                            SDL.SDL_INIT_JOYSTICK,
                            SDL.SDL_INIT_GAMECONTROLLER)) ~= 0 then
        error("Cannot initialize SDL: " .. ffi.string(SDL.SDL_GetError()))
    end

    local full_screen = os.getenv("SDL_FULLSCREEN")
    if full_screen then
        local mode = ffi.new("SDL_DisplayMode")
        if SDL.SDL_GetCurrentDisplayMode(0, mode) ~= 0 then
            error("SDL cannot get current display mode.")
        end
        S.w, S.h = mode.w, mode.h
    else
        S.w = tonumber(os.getenv("EMULATE_READER_W")) or w or 600
        S.h = tonumber(os.getenv("EMULATE_READER_H")) or h or 800
    end

    -- Disable to work around an SDL issue in 2.0.22.
    -- See <https://github.com/libsdl-org/SDL/issues/5652> and <https://github.com/koreader/koreader/issues/9091>.
    SDL.SDL_SetHint("SDL_HINT_TOUCH_MOUSE_EVENTS", "0")

    -- Enable screensaver and X11 composition.
    SDL.SDL_EnableScreenSaver()
    if SDL_Linked_Version_AtLeast(2, 0, 8) then
        SDL.SDL_SetHint("SDL_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR", "0")
    end

    -- set up screen (window)
    S.screen = SDL.SDL_CreateWindow("KOReader",
        tonumber(os.getenv("KOREADER_WINDOW_POS_X")) or x or SDL.SDL_WINDOWPOS_UNDEFINED,
        tonumber(os.getenv("KOREADER_WINDOW_POS_Y")) or y or SDL.SDL_WINDOWPOS_UNDEFINED,
        S.w, S.h,
        bit.bor(full_screen and 1 or 0, SDL.SDL_WINDOW_RESIZABLE, SDL.SDL_WINDOW_ALLOW_HIGHDPI)
    )

    S.renderer = SDL.SDL_CreateRenderer(S.screen, -1, 0)
    S.texture = S.createTexture()

    openGameController()
end

function S:startTextInput()
    -- Start delivering Unicode text as well as keypresses - this will
    -- handle things like Shift-numbers and letters according to the layout
    -- and will deliver SDL_TEXTINPUT with that text.
    SDL.SDL_StartTextInput()
end

function S:stopTextInput()
    SDL.SDL_StopTextInput()
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
    local flags = full_screen and SDL.SDL_WINDOW_FULLSCREEN_DESKTOP or 0
    if SDL.SDL_SetWindowFullscreen(S.screen, flags) ~= 0 then
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

local function handleWindowEvent(event_window)
    -- The next buffer might always contain garbage, and on X11 without
    -- compositing the buffers will be damaged just by moving the window
    -- partly offscreen, minimizing it, or putting another window
    -- (partially) on top of it.
    -- Handling `SDL_WINDOWEVENT_EXPOSED` is the only way to deal with
    -- this without sending regular updates.
    if event_window.event == SDL.SDL_WINDOWEVENT_EXPOSED then
        SDL.SDL_RenderCopy(S.renderer, S.texture, nil, nil)
        SDL.SDL_RenderPresent(S.renderer)
    elseif (event_window.event == SDL.SDL_WINDOWEVENT_RESIZED
             or event_window.event == SDL.SDL_WINDOWEVENT_SIZE_CHANGED
             or event_window.event == SDL.SDL_WINDOWEVENT_MOVED) then
        genEmuEvent(C.EV_SDL, event_window.event, event_window)
    end
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

local SDL_BUTTON_LEFT = 1

local is_in_touch = false

function S.waitForEvent(sec, usec)
    local event = ffi.new("union SDL_Event")
    -- TimeVal to ms if we were passed one to begin with, otherwise, -1 => block.
    -- NOTE: Since we have *less* precision than a timeval, we round *up*, to avoid passing zero for < 1ms timevals.
    local timeout = sec and math.ceil((sec * 1000000 + usec) * (1/1000)) or -1

    -- Reset the queue
    inputQueue = {}

    -- Wait for event
    local got_event = SDL.SDL_WaitEventTimeout(event, timeout)
    if got_event == 0 then
        -- ETIME
        return false, C.ETIME
    end

    -- if we got an event, examine it here and generate events for koreader
    if ffi.os == "OSX" and (event.type == SDL.SDL_FINGERMOTION or
        event.type == SDL.SDL_FINGERDOWN or
        event.type == SDL.SDL_FINGERUP) then
        -- noop for trackpad finger inputs which interfere with emulated mouse inputs
        do end -- luacheck: ignore 541
    elseif event.type == SDL.SDL_KEYDOWN then
        genEmuEvent(C.EV_KEY, event.key.keysym.sym, 1)
    elseif event.type == SDL.SDL_KEYUP then
        genEmuEvent(C.EV_KEY, event.key.keysym.sym, 0)
    elseif event.type == SDL.SDL_TEXTINPUT then
        genEmuEvent(C.EV_SDL, SDL.SDL_TEXTINPUT, ffi.string(event.text.text))
    elseif event.type == SDL.SDL_MOUSEMOTION
        or event.type == SDL.SDL_FINGERMOTION then
        local is_finger = event.type == SDL.SDL_FINGERMOTION
        if is_in_touch then
            if is_finger then
                if event.tfinger.dx ~= 0 then
                    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X,
                        event.tfinger.x * S.w)
                end
                if event.tfinger.dy ~= 0 then
                    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y,
                        event.tfinger.y * S.h)
                end
            else
                if event.motion.xrel ~= 0 then
                    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X,
                        event.motion.x)
                end
                if event.motion.yrel ~= 0 then
                    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y,
                        event.motion.y)
                end
            end
            genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
        end
    elseif event.type == SDL.SDL_MOUSEBUTTONUP
        or event.type == SDL.SDL_FINGERUP then
        is_in_touch = false
        genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, -1)
        genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
    elseif event.type == SDL.SDL_MOUSEBUTTONDOWN
        or event.type == SDL.SDL_FINGERDOWN then
        local is_finger = event.type == SDL.SDL_FINGERDOWN
        if not is_finger and event.button.button ~= SDL_BUTTON_LEFT then
            -- Not a left-click?
            return false, C.ENOSYS
        end
        -- use mouse click to simulate single tap
        is_in_touch = true
        genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, 0)
        genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X,
            is_finger and event.tfinger.x * S.w or event.button.x)
        genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y,
            is_finger and event.tfinger.y * S.h or event.button.y)
        genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
    elseif event.type == SDL.SDL_MULTIGESTURE then
        genEmuEvent(C.EV_SDL, SDL.SDL_MULTIGESTURE, event.mgesture)
    elseif event.type == SDL.SDL_MOUSEWHEEL then
        genEmuEvent(C.EV_SDL, SDL.SDL_MOUSEWHEEL, event.wheel)
    elseif event.type == SDL.SDL_DROPFILE then
        local dropped_file_path = ffi.string(event.drop.file)
        genEmuEvent(C.EV_SDL, SDL.SDL_DROPFILE, dropped_file_path)
    elseif event.type == SDL.SDL_DROPTEXT then
        local dropped_text = ffi.string(event.drop.file)
        genEmuEvent(C.EV_SDL, SDL.SDL_DROPTEXT, dropped_text)
    elseif event.type == SDL.SDL_WINDOWEVENT then
        handleWindowEvent(event.window)
    --- Gamepad support ---
    -- For debugging it can be helpful to use:
    -- print(ffi.string(SDL.SDL_GameControllerGetStringForButton(button)))
    -- @TODO Proper support instead of faux keyboard presses
    --
    --- Controllers ---
    elseif event.type == SDL.SDL_CONTROLLERDEVICEADDED
            or event.type == SDL.SDL_CONTROLLERDEVICEREMOVED
            or event.type == SDL.SDL_CONTROLLERDEVICEREMAPPED then
        openGameController()
    --- Sticks & triggers ---
    elseif event.type == SDL.SDL_JOYAXISMOTION then
        handleJoyAxisMotionEvent(event)
    --- Buttons (such as A, B, X, Y) ---
    elseif event.type == SDL.SDL_JOYBUTTONDOWN then
        local button = event.cbutton.button

        if button == SDL.SDL_CONTROLLER_BUTTON_A then
            -- send enter
            genEmuEvent(C.EV_KEY, 13, 1)
            -- send end (bound to press)
            genEmuEvent(C.EV_KEY, 1073741901, 1)
        elseif button == SDL.SDL_CONTROLLER_BUTTON_B then
            -- send escape
            genEmuEvent(C.EV_KEY, 27, 1)
        -- left bumper
        elseif button == SDL.SDL_CONTROLLER_BUTTON_BACK then
            -- send page up
            genEmuEvent(C.EV_KEY, 1073741899, 1)
        -- right bumper
        elseif button == SDL.SDL_CONTROLLER_BUTTON_GUIDE then
            -- send page down
            genEmuEvent(C.EV_KEY, 1073741902, 1)
        -- On the Xbox One controller, start = start but leftstick = menu button
        elseif button == SDL.SDL_CONTROLLER_BUTTON_START or button == SDL.SDL_CONTROLLER_BUTTON_LEFTSTICK then
            -- send F1 (bound to menu in front at the time of writing)
            genEmuEvent(C.EV_KEY, 1073741882, 1)
        end
    --- D-pad ---
    elseif event.type == SDL.SDL_JOYHATMOTION then
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
    elseif event.type == SDL.SDL_QUIT then
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
    return ffi.string(SDL.SDL_GetClipboardText())
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
    local icon_bit_depth = 32
    local surface = SDL.SDL_CreateRGBSurfaceWithFormatFrom(icon_bb.data,
                                                           icon_bb:getWidth(), icon_bb:getHeight(),
                                                           icon_bit_depth, icon_bb.stride,
                                                           SDL.SDL_PIXELFORMAT_RGBA32)
    SDL.SDL_SetWindowIcon(S.screen, surface)
    SDL.SDL_FreeSurface(surface)
    icon_bb:free()
end

function S.gameControllerRumble(left_intensity, right_intensity, duration)
    if S.controller == nil
       or not SDL_Linked_Version_AtLeast(2, 0, 9)
    then
        return
    end

    left_intensity = left_intensity or 20000
    right_intensity = right_intensity or 20000
    duration = duration or 200

    return SDL.SDL_GameControllerRumble(S.controller, left_intensity, right_intensity, duration)
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
    return ffi.string(SDL.SDL_GetPrefPath(organization, appname))
end

function S.getPowerInfo()
    local batt, plugged, charging
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
