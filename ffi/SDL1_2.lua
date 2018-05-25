--[[
Module for interfacing SDL video/input facilities

This module is intended to provide input/output facilities on a
typical desktop (rather than a dedicated e-ink reader, for which
there would probably be raw framebuffer/input device access
instead).
]]

local ffi = require("ffi")
local util = require("ffi/util")
local C = ffi.C

local dummy = require("ffi/SDL1_2_h")
local dummy = require("ffi/linux_input_h")

-----------------------------------------------------------------

local SDL = ffi.load("SDL")

local S = {
	screen = nil,
	SDL = SDL
}

-- initialization for both input and eink output
function S.open()
	if SDL.SDL_WasInit(SDL.SDL_INIT_VIDEO) ~= 0 then
		-- already initialized
		return true
	end
	if SDL.SDL_Init(SDL.SDL_INIT_VIDEO) ~= 0 then
		error("cannot initialize SDL")
	end

	-- set up screen (window)
	S.screen = SDL.SDL_SetVideoMode(
		tonumber(os.getenv("EMULATE_READER_W")) or 600,
		tonumber(os.getenv("EMULATE_READER_H")) or 800,
		32, SDL.SDL_HWSURFACE)

	-- init keyboard delay/repeat rate
	SDL.SDL_EnableKeyRepeat(500, 10)
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
		if event.type == SDL.SDL_KEYDOWN then
			genEmuEvent(C.EV_KEY, event.key.keysym.scancode, 1)
		elseif event.type == SDL.SDL_KEYUP then
			genEmuEvent(C.EV_KEY, event.key.keysym.scancode, 0)
		elseif event.type == SDL.SDL_MOUSEMOTION then
			if is_in_touch then
				if event.motion.xrel ~= 0 then
					genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, event.button.x)
				end
				if event.motion.yrel ~= 0 then
					genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, event.button.y)
				end
				genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
			end
		elseif event.type == SDL.SDL_MOUSEBUTTONUP then
			is_in_touch = false;
			genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, -1)
			genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
		elseif event.type == SDL.SDL_MOUSEBUTTONDOWN then
			-- use mouse click to simulate single tap
			is_in_touch = true
			genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, 0)
			genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, event.button.x)
			genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, event.button.y)
			genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0)
		elseif event.type == SDL.SDL_QUIT then
			error("application forced to quit")
		end
	end
end

return S
