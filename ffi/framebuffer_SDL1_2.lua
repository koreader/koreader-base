local ffi = require("ffi")
local bit = require("bit")
-- load common SDL input/video library
local SDL = require("ffi/SDL1_2")

local BB = require("ffi/blitbuffer")

local fb = {}

function fb.open()
	if not fb.dummy then
		SDL.open()
		-- we present this buffer to the outside
		fb.bb = BB.new(SDL.screen.w, SDL.screen.h)
		fb.real_bb = BB.new(SDL.screen.w, SDL.screen.h, BB.TYPE_BBRGB32,
			SDL.screen.pixels, SDL.screen.pitch)
	else
		fb.bb = BB.new(600, 800)
		fb.real_bb = BB.new(600, 800)
	end

	fb.real_bb:invert()

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
	if SDL.screen.w > SDL.screen.h then
		return 1
	else
		return 0
	end
end

function fb:refresh(refreshtype, waveform_mode, x1, y1, w, h)
	if self.dummy then return end
	if x1 == nil then x1 = 0 end
	if y1 == nil then y1 = 0 end

	-- adapt to possible rotation changes
	self.real_bb:setRotation(self.bb:getRotation())

	if SDL.SDL.SDL_LockSurface(SDL.screen) < 0 then
		error("Locking screen surface")
	end
	self.real_bb:blitFrom(self.bb, x1, y1, x1, y1, w, h)

	SDL.SDL.SDL_UnlockSurface(SDL.screen)
	SDL.SDL.SDL_Flip(SDL.screen)
end

function fb:close()
	-- for now, we do nothing when in emulator mode
end

return fb
