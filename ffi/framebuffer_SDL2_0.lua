-- load common SDL input/video library
local SDL = require("ffi/SDL2_0")
local BB = require("ffi/blitbuffer")

local framebuffer = {}

function framebuffer:init()
    if not self.dummy then
		SDL.open()
		-- we present this buffer to the outside
		self.bb = BB.new(SDL.w, SDL.h, BB.TYPE_BBRGB32)
	else
		self.bb = BB.new(600, 800)
    end

    self.bb:fill(BB.COLOR_WHITE)
	self:refreshFull()

    framebuffer.parent.init(self)
end

function framebuffer:refreshFullImp()
	if self.dummy then return end

	SDL.SDL.SDL_UpdateTexture(SDL.texture, nil, self.bb.data, self.bb.pitch)
	SDL.SDL.SDL_RenderClear(SDL.renderer)
	SDL.SDL.SDL_RenderCopy(SDL.renderer, SDL.texture, nil, nil)
	SDL.SDL.SDL_RenderPresent(SDL.renderer)
end

function framebuffer:close()
    SDL.SDL.SDL_Quit()
end

return require("ffi/framebuffer"):extend(framebuffer)
