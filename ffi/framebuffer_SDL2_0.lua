local ffi = require("ffi")
local bit = require("bit")
-- load common SDL input/video library
local SDL = require("ffi/SDL2_0")

local BB = require("ffi/blitbuffer")

local fb = {}

function fb.open()
    if not fb.dummy then
		SDL.open()
		-- we present this buffer to the outside
		fb.bb = BB.new(SDL.w, SDL.h, BB.TYPE_BBRGB32)
	else
		fb.bb = BB.new(600, 800)
    end

    fb.bb:fill(BB.COLOR_WHITE)
	fb:refresh()

	return fb
end

function fb:getSize()
	return self.bb.w, self.bb.h
end

function fb:getPitch()
	return self.bb.pitch
end

function fb:setOrientation(mode)
	if mode == 1 or mode == 3 then
		-- TODO: landscape setting
	else
		-- TODO: flip back to portrait
	end
end

function fb:getOrientation()
	if SDL.w > SDL.h then
		return 1
	else
		return 0
	end
end

function fb:refresh(refreshtype, waveform_mode, x1, y1, w, h)
	if self.dummy then return end

	SDL.SDL.SDL_UpdateTexture(SDL.texture, nil, self.bb.data, self.bb.pitch)
	SDL.SDL.SDL_RenderClear(SDL.renderer)
	SDL.SDL.SDL_RenderCopy(SDL.renderer, SDL.texture, nil, nil)
	SDL.SDL.SDL_RenderPresent(SDL.renderer)
end

function fb:close()
    SDL.SDL.SDL_Quit()
end

return fb
