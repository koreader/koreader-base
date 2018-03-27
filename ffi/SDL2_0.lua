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

local dummy = require("ffi/SDL2_0_h")
local dummy = require("ffi/linux_input_h")

-----------------------------------------------------------------

local SDL = ffi.load("SDL2")

local S = {
    w = 0, h = 0,
    screen = nil,
    renderer = nil,
    texture = nil,
    SDL = SDL,
}

-- initialization for both input and eink output
function S.open()
    if SDL.SDL_WasInit(SDL.SDL_INIT_VIDEO) ~= 0 then
        -- already initialized
        return true
    end

    SDL.SDL_SetMainReady()

    if SDL.SDL_Init(SDL.SDL_INIT_VIDEO) ~= 0 then
        error("Cannot initialize SDL.")
    end

    local full_screen = os.getenv("SDL_FULLSCREEN")
    if full_screen then
        local mode = ffi.new("struct SDL_DisplayMode")
        if SDL.SDL_GetCurrentDisplayMode(0, mode) ~= 0 then
            error("SDL cannot get current display mode.")
        end
        S.w, S.h = mode.w, mode.h
    else
        S.w = tonumber(os.getenv("EMULATE_READER_W")) or 600
        S.h = tonumber(os.getenv("EMULATE_READER_H")) or 800
    end

    -- set up screen (window)
    S.screen = SDL.SDL_CreateWindow("KOReader",
        tonumber(os.getenv("KOREADER_WINDOW_POS_X")) or SDL.SDL_WINDOWPOS_UNDEFINED,
        tonumber(os.getenv("KOREADER_WINDOW_POS_Y")) or SDL.SDL_WINDOWPOS_UNDEFINED,
        S.w, S.h,
        bit.bor(full_screen and 1 or 0, SDL.SDL_WINDOW_RESIZABLE)
    )

    S.renderer = SDL.SDL_CreateRenderer(S.screen, -1, 0)
    S.texture = S.createTexture()
end

function S.createTexture(w, h)
    w = w or S.w
    h = h or S.h

    return SDL.SDL_CreateTexture(
        S.renderer,
        SDL.SDL_PIXELFORMAT_ABGR8888,
        SDL.SDL_TEXTUREACCESS_TARGET,
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
        value = tonumber(value),
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
        local w = 0
        local h = 1
        local new_size_w = event_window.data1
        local new_size_h = event_window.data2

        if new_size_w and new_size_h then
            genEmuEvent(ffi.C.EV_MSC, w, new_size_w)
            genEmuEvent(ffi.C.EV_MSC, h, new_size_h)
            genEmuEvent(ffi.C.EV_MSC, SDL.SDL_WINDOWEVENT_RESIZED, 0)
        end
    end
end

local is_in_touch = false
local dropped_file_path

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
            genEmuEvent(ffi.C.EV_KEY, event.key.keysym.scancode, 1)
        elseif event.type == SDL.SDL_KEYUP then
            genEmuEvent(ffi.C.EV_KEY, event.key.keysym.scancode, 0)
        elseif event.type == SDL.SDL_MOUSEMOTION
            or event.type == SDL.SDL_FINGERMOTION then
            local is_finger = event.type == SDL.SDL_FINGERMOTION
            if is_in_touch then
                if is_finger then
                    if event.tfinger.dx ~= 0 then
                        genEmuEvent(ffi.C.EV_ABS, ffi.C.ABS_MT_POSITION_X,
                            event.tfinger.x * S.w)
                    end
                    if event.tfinger.dy ~= 0 then
                        genEmuEvent(ffi.C.EV_ABS, ffi.C.ABS_MT_POSITION_Y,
                            event.tfinger.y * S.h)
                    end
                else
                    if event.motion.xrel ~= 0 then
                        genEmuEvent(ffi.C.EV_ABS, ffi.C.ABS_MT_POSITION_X,
                            event.button.x)
                    end
                    if event.motion.yrel ~= 0 then
                        genEmuEvent(ffi.C.EV_ABS, ffi.C.ABS_MT_POSITION_Y,
                            event.button.y)
                    end
                end
                genEmuEvent(ffi.C.EV_SYN, ffi.C.SYN_REPORT, 0)
            end
        elseif event.type == SDL.SDL_MOUSEBUTTONUP
            or event.type == SDL.SDL_FINGERUP then
            is_in_touch = false;
            genEmuEvent(ffi.C.EV_ABS, ffi.C.ABS_MT_TRACKING_ID, -1)
            genEmuEvent(ffi.C.EV_SYN, ffi.C.SYN_REPORT, 0)
        elseif event.type == SDL.SDL_MOUSEBUTTONDOWN
            or event.type == SDL.SDL_FINGERDOWN then
            local is_finger = event.type == SDL.SDL_FINGERDOWN
            -- use mouse click to simulate single tap
            is_in_touch = true
            genEmuEvent(ffi.C.EV_ABS, ffi.C.ABS_MT_TRACKING_ID, 0)
            genEmuEvent(ffi.C.EV_ABS, ffi.C.ABS_MT_POSITION_X,
                is_finger and event.tfinger.x * S.w or event.button.x)
            genEmuEvent(ffi.C.EV_ABS, ffi.C.ABS_MT_POSITION_Y,
                is_finger and event.tfinger.y * S.h or event.button.y)
            genEmuEvent(ffi.C.EV_SYN, ffi.C.SYN_REPORT, 0)
        elseif event.type == SDL.SDL_MULTIGESTURE then -- luacheck: ignore 542
            -- TODO: multi-touch support
        elseif event.type == SDL.SDL_DROPFILE then
            dropped_file_path = ffi.string(event.drop.file)
            genEmuEvent(ffi.C.EV_MSC, SDL.SDL_DROPFILE, 0)
        elseif event.type == SDL.SDL_WINDOWEVENT then
            handleWindowEvent(event.window)
        elseif event.type == SDL.SDL_QUIT then
            -- send Alt + F4
            genEmuEvent(ffi.C.EV_KEY, 226, 1)
            genEmuEvent(ffi.C.EV_KEY, 61, 1)
        end
    end
end

function S.getDroppedFilePath()
    return dropped_file_path
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

return S
