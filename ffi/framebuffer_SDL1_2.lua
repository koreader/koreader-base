-- load common SDL input/video library
local SDL = require("ffi/SDL1_2")
local BB = require("ffi/blitbuffer")
local util = require("ffi/util")

local framebuffer = {
    -- this blitbuffer will be used when we use refresh emulation
    sdl_bb = nil,
    flash_duration = nil,
}

function framebuffer:init()
	if not self.dummy then
		SDL.open()
		local bb = BB.new(SDL.screen.w, SDL.screen.h, BB.TYPE_BBRGB32,
			SDL.screen.pixels, SDL.screen.pitch)
        self.flash_duration = tonumber(os.getenv("EMULATE_READER_FLASH"))
        if self.flash_duration then
            -- in refresh emulation mode, we use a shadow blitbuffer
            -- and blit refresh areas from it.
            self.sdl_bb = bb
            self.bb = BB.new(SDL.screen.w, SDL.screen.h, BB.TYPE_BBRGB32)
        else
            self.bb = bb
        end
	else
		self.bb = BB.new(600, 800)
	end

    self.bb:fill(BB.COLOR_WHITE)
	self:refreshFull()

    framebuffer.parent.init(self)
end

local function flip()
	if SDL.SDL.SDL_LockSurface(SDL.screen) < 0 then
		error("Locking screen surface")
	end

	SDL.SDL.SDL_UnlockSurface(SDL.screen)
	SDL.SDL.SDL_Flip(SDL.screen)
end

function framebuffer:_refresh(x, y, w, h, flash)
	if self.dummy then return end

    local bb = self.full_bb or self.bb

    if not (x and y and w and h) then
        x = 0
        y = 0
        w = bb:getWidth()
        h = bb:getHeight()
    end

    if flash then
        if flash > 0 then
            self.sdl_bb:invertRect(x, y, w, h)
            flip()
            util.usleep(flash*1000)
        end
        self.sdl_bb:setRotation(bb:getRotation())
        self.sdl_bb:setInverse(bb:getInverse())
        self.sdl_bb:blitFrom(bb, x, y, x, y, w, h)
    end

    flip()
end

function framebuffer:refreshFullImp(x, y, w, h)
    self.debug("full refresh on physical rectangle", x, y, w, h)
    self:_refresh(x, y, w, h, self.flash_duration)
end

function framebuffer:refreshPartialImp(x, y, w, h)
    self.debug("partial refresh on physical rectangle", x, y, w, h)
    -- make partial refresh duration 0.5 times of full refresh,
    -- and adapt speed to size of the area being updated
    self:_refresh(x, y, w, h,
        self.flash_duration and
        (self.flash_duration * 0.5 * w*h / (self.bb:getWidth()*self.bb:getHeight())))
end

function framebuffer:refreshFlashPartialImp(x, y, w, h)
    self.debug("Flashing partial refresh on physical rectangle", x, y, w, h)
    self:_refresh(x, y, w, h,
        self.flash_duration and
        (self.flash_duration * 0.75 * w*h / (self.bb:getWidth()*self.bb:getHeight())))
end

function framebuffer:refreshUIImp(x, y, w, h)
    self.debug("UI refresh on physical rectangle", x, y, w, h)
    self:_refresh(x, y, w, h,
        self.flash_duration and
        (self.flash_duration * 0.25 * w*h / (self.bb:getWidth()*self.bb:getHeight())))
end

function framebuffer:refreshFlashUIImp(x, y, w, h)
    self.debug("Flashing UI refresh on physical rectangle", x, y, w, h)
    self:_refresh(x, y, w, h,
        self.flash_duration and
        (self.flash_duration * 0.5 * w*h / (self.bb:getWidth()*self.bb:getHeight())))
end

function framebuffer:refreshFastImp(x, y, w, h)
    self.debug("fast refresh on physical rectangle", x, y, w, h)
    self:_refresh(x, y, w, h, self.flash_duration and 0)
end

function framebuffer:close()
    SDL.SDL.SDL_Quit()
end

return require("ffi/framebuffer"):extend(framebuffer)
