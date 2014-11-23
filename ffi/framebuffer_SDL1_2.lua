-- load common SDL input/video library
local SDL = require("ffi/SDL1_2")
local BB = require("ffi/blitbuffer")

local framebuffer = {}

function framebuffer:init()
	if not self.dummy then
		SDL.open()
		-- we present this buffer to the outside
		self.bb = BB.new(SDL.screen.w, SDL.screen.h, BB.TYPE_BBRGB32,
			SDL.screen.pixels, SDL.screen.pitch)
	else
		self.bb = BB.new(600, 800)
	end

    self.bb:fill(BB.COLOR_WHITE)
	self:refreshFull()

    framebuffer.parent.init(self)
end

function framebuffer:refreshFullImp()
	if self.dummy then return end

	-- adapt to possible rotation changes
	self.bb:setRotation(self.bb:getRotation())

	if SDL.SDL.SDL_LockSurface(SDL.screen) < 0 then
		error("Locking screen surface")
	end

	SDL.SDL.SDL_UnlockSurface(SDL.screen)
	SDL.SDL.SDL_Flip(SDL.screen)
end

function framebuffer:close()
    SDL.SDL.SDL_Quit()
end

return require("ffi/framebuffer"):extend(framebuffer)
