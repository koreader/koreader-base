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

local dummy = require("ffi/SDL2_0_h")
local dummy = require("ffi/linux_input_h")

-----------------------------------------------------------------

local SDL = util.ffiLoadCandidates{
    "SDL2",
    -- this unfortunately needs to be written in full due to the . in the name
    "libSDL2-2.0.so",
    "libSDL2-2.0.so.0",
}

-- Some features (like SDL_GameControllerRumble) may require a minimum version
-- of SDL. These helper functions allow us to prevent any issues with calling
-- undefined symbols.
local sdl_linked_ver = ffi.new("struct SDL_version[0]")
SDL.SDL_GetVersion(sdl_linked_ver)

-- Just a copy of a C macro that unfortunately can't be used through FFI.
-- This assumes that there will never be more than 100 patchlevels.
local function SDL_VersionNum(x, y, z)
    return x*1000 + y*100 + z
end

local function SDL_Linked_Version_AtLeast(x, y, z)
    return SDL_VersionNum(sdl_linked_ver[0].major, sdl_linked_ver[0].minor, sdl_linked_ver[0].patch) >= SDL_VersionNum(x, y, z)
end

-- for frontend SDL event handling
local EV_SDL = 53 -- ASCII code for S

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
function S.open()
    if SDL.SDL_WasInit(SDL.SDL_INIT_VIDEO) ~= 0 then
        -- already initialized
        return true
    end

    SDL.SDL_SetMainReady()

    if SDL.SDL_Init(bit.bor(SDL.SDL_INIT_VIDEO,
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
        S.w = tonumber(os.getenv("EMULATE_READER_W")) or 600
        S.h = tonumber(os.getenv("EMULATE_READER_H")) or 800
    end

    -- set up screen (window)
    if SDL_Linked_Version_AtLeast(2, 0, 1) then
        screen_flags = bit.bor(full_screen and 1 or 0,
                               SDL.SDL_WINDOW_RESIZABLE,
                               SDL.SDL_WINDOW_ALLOW_HIGHDPI)
    else
        screen_flags = bit.bor(full_screen and 1 or 0,
                               SDL.SDL_WINDOW_RESIZABLE)
    end
    S.screen = SDL.SDL_CreateWindow("KOReader",
        tonumber(os.getenv("KOREADER_WINDOW_POS_X")) or SDL.SDL_WINDOWPOS_UNDEFINED,
        tonumber(os.getenv("KOREADER_WINDOW_POS_Y")) or SDL.SDL_WINDOWPOS_UNDEFINED,
        S.w, S.h,
        screen_flags
    )

    S.renderer = SDL.SDL_CreateRenderer(S.screen, -1, 0)
    S.texture = S.createTexture()

    openGameController()
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
    local secs, usecs = util.gettime()

    local ev = {
        type = tonumber(evtype),
        code = tonumber(code),
        value = tonumber(value) or value,
        time = { sec = secs, usec = usecs },
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
             or event_window.event == SDL.SDL_WINDOWEVENT_SIZE_CHANGED) then
        genEmuEvent(EV_SDL, event_window.event, event_window)
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

    if not ( since_last_ev > min_time_since_last_ev ) then return end

    -- left stick 0/1
    if axis == 0 then
        if value < -neutral_max_val then
            -- send left
            genEmuEvent(C.EV_KEY, 80, 1)
        else
            -- send right
            genEmuEvent(C.EV_KEY, 79, 1)
        end
    elseif axis == 1 then
        if value < -neutral_max_val then
            -- send up
            genEmuEvent(C.EV_KEY, 82, 1)
        else
            -- send down
            genEmuEvent(C.EV_KEY, 81, 1)
        end
    -- right stick 3/4
    elseif axis == 4 then
        if value < -neutral_max_val then
            -- send page up
            genEmuEvent(C.EV_KEY, 75, 1)
        else
            -- send page down
            genEmuEvent(C.EV_KEY, 78, 1)
        end
    -- left trigger 2
    -- right trigger 5
    end

    last_joystick_event_secs, last_joystick_event_usecs = util.gettime()
end

local SDL_BUTTON_LEFT = 1

local is_in_touch = false

function S.waitForEvent(usecs)
    usecs = usecs or -1
    local event = ffi.new("union SDL_Event")
    local countdown = usecs
    while true do
        -- check for queued events
        if #inputQueue > 0 then
            -- return oldest FIFO element
            return table.remove(inputQueue, 1)
        end

        -- otherwise, wait for event
        local got_event = 0
        if usecs < 0 then
            got_event = SDL.SDL_WaitEvent(event);
        else
            -- timeout mode - use polling
            while countdown > 0 and got_event == 0 do
                got_event = SDL.SDL_PollEvent(event)
                if got_event == 0 then
                    -- no event, wait 10 msecs before polling again
                    SDL.SDL_Delay(10)
                    countdown = countdown - 10000
                end
            end
        end
        if got_event == 0 then
            error("Waiting for input failed: timeout\n")
        end

        -- if we got an event, examine it here and generate
        -- events for koreader
        if ffi.os == "OSX" and (event.type == SDL.SDL_FINGERMOTION or
            event.type == SDL.SDL_FINGERDOWN or
            event.type == SDL.SDL_FINGERUP) then
            -- noop for trackpad finger inputs which interfere with emulated mouse inputs
            do end -- luacheck: ignore 541
        elseif event.type == SDL.SDL_KEYDOWN then
            genEmuEvent(C.EV_KEY, event.key.keysym.scancode, 1)
        elseif event.type == SDL.SDL_KEYUP then
            genEmuEvent(C.EV_KEY, event.key.keysym.scancode, 0)
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
                            event.button.x)
                    end
                    if event.motion.yrel ~= 0 then
                        genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y,
                            event.button.y)
                    end
                end
                genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
            end
        elseif event.type == SDL.SDL_MOUSEBUTTONUP
            or event.type == SDL.SDL_FINGERUP then
            is_in_touch = false;
            genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, -1)
            genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
        elseif event.type == SDL.SDL_MOUSEBUTTONDOWN
            or event.type == SDL.SDL_FINGERDOWN then
            local is_finger = event.type == SDL.SDL_FINGERDOWN
            if not is_finger and event.button.button ~= SDL_BUTTON_LEFT then
                return
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
            genEmuEvent(EV_SDL, SDL.SDL_MULTIGESTURE, event.mgesture)
        elseif event.type == SDL.SDL_MOUSEWHEEL then
            genEmuEvent(EV_SDL, SDL.SDL_MOUSEWHEEL, event.wheel)
        elseif event.type == SDL.SDL_DROPFILE then
            local dropped_file_path = ffi.string(event.drop.file)
            genEmuEvent(EV_SDL, SDL.SDL_DROPFILE, dropped_file_path)
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
                genEmuEvent(C.EV_KEY, 40, 1)
                -- send end (bound to press)
                genEmuEvent(C.EV_KEY, 77, 1)
            elseif button == SDL.SDL_CONTROLLER_BUTTON_B then
                -- send escape
                genEmuEvent(C.EV_KEY, 41, 1)
            -- left bumper
            elseif button == SDL.SDL_CONTROLLER_BUTTON_BACK then
                -- send page up
                genEmuEvent(C.EV_KEY, 75, 1)
            -- right bumper
            elseif button == SDL.SDL_CONTROLLER_BUTTON_GUIDE then
                -- send page down
                genEmuEvent(C.EV_KEY, 78, 1)
            -- On the Xbox One controller, start = start but leftstick = menu button
            elseif button == SDL.SDL_CONTROLLER_BUTTON_START or button == SDL.SDL_CONTROLLER_BUTTON_LEFTSTICK then
                -- send F1 (bound to menu in front at the time of writing)
                genEmuEvent(C.EV_KEY, 58, 1)
            end
        --- D-pad ---
        elseif event.type == SDL.SDL_JOYHATMOTION then
            local hat_position = event.jhat.value

            if hat_position == SDL.SDL_HAT_UP then
                -- send up
                genEmuEvent(C.EV_KEY, 82, 1)
            elseif hat_position == SDL.SDL_HAT_DOWN then
                -- send down
                genEmuEvent(C.EV_KEY, 81, 1)
            elseif hat_position == SDL.SDL_HAT_LEFT then
                -- send left
                genEmuEvent(C.EV_KEY, 80, 1)
            elseif hat_position == SDL.SDL_HAT_RIGHT then
                -- send right
                genEmuEvent(C.EV_KEY, 79, 1)
            end
        elseif event.type == SDL.SDL_QUIT then
            -- send Alt + F4
            genEmuEvent(C.EV_KEY, 226, 1)
            genEmuEvent(C.EV_KEY, 61, 1)
        end
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
                                                           icon_bit_depth, icon_bb.pitch,
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

return S
