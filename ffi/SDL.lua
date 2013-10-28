--[[
Module for interfacing SDL video/input facilities

This module is intended to provide input/output facilities on a
typical desktop (rather than a dedicated e-ink reader, for which
there would probably be raw framebuffer/input device access
instead).
]]

local ffi = require("ffi")

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
		os.getenv("EMULATE_READER_W") or 600,
		os.getenv("EMULATE_READER_H") or 800,
		32, SDL.SDL_HWSURFACE)

	-- init keyboard delay/repeat rate
	SDL.SDL_EnableKeyRepeat(500, 10)
end

return S
