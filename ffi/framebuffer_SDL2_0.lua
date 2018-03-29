-- load common SDL input/video library
local SDL = require("ffi/SDL2_0")
local BB = require("ffi/blitbuffer")
local util = require("ffi/util")

local framebuffer = {
    -- this blitbuffer will be used when we use refresh emulation
    sdl_bb = nil,
}

function framebuffer:init()
    if not self.dummy then
        SDL.open()
        self:_newBB()
    else
        self.bb = BB.new(600, 800)
    end

    self.bb:fill(BB.COLOR_WHITE)
    self:refreshFull()

    framebuffer.parent.init(self)
end

function framebuffer:resize(w, h)
    w = w or SDL.w
    h = h or SDL.h

    if not self.dummy then
        self:_newBB(w, h)
    else
        self.bb:free()
        self.bb = BB.new(600, 800)
    end

    if SDL.texture then SDL.destroyTexture(SDL.texture) end
    SDL.texture = SDL.createTexture(w, h)

    self.bb:fill(BB.COLOR_WHITE)
    self:refreshFull()
end

function framebuffer:_newBB(w, h)
    w = w or SDL.w
    h = h or SDL.h

    local inverse

    if self.sdl_bb then self.sdl_bb:free() end
    if self.bb then
        inverse = self.bb:getInverse() == 1
        self.bb:free()
    end
    if self.invert_bb then self.invert_bb:free() end

    -- we present this buffer to the outside
    local bb = BB.new(w, h, BB.TYPE_BBRGB32)
    local flash = os.getenv("EMULATE_READER_FLASH")
    if flash then
        -- in refresh emulation mode, we use a shadow blitbuffer
        -- and blit refresh areas from it.
        self.sdl_bb = bb
        self.bb = BB.new(w, h, BB.TYPE_BBRGB32)
    else
        self.bb = bb
    end
    self.invert_bb = BB.new(w, h, BB.TYPE_BBRGB32)

    -- reinit inverse mode on resize
    if inverse then
        self.bb:invert()
    end
end

function framebuffer:_render(bb)
    if bb:getInverse() == 1 then
        self.invert_bb:invertblitFrom(bb)
        SDL.SDL.SDL_UpdateTexture(SDL.texture, nil, self.invert_bb.data, self.invert_bb.pitch)
    else
        SDL.SDL.SDL_UpdateTexture(SDL.texture, nil, bb.data, bb.pitch)
    end
    SDL.SDL.SDL_RenderClear(SDL.renderer)
    SDL.SDL.SDL_RenderCopy(SDL.renderer, SDL.texture, nil, nil)
    SDL.SDL.SDL_RenderPresent(SDL.renderer)
end

function framebuffer:refreshFullImp(x, y, w, h)
    if self.dummy then return end

    local bb = self.full_bb or self.bb

    if not (x and y and w and h) then
        x = 0
        y = 0
        w = bb:getWidth()
        h = bb:getHeight()
    end

    self.debug("refresh on physical rectangle", x, y, w, h)

    local flash = os.getenv("EMULATE_READER_FLASH")
    if flash then
        self.sdl_bb:invertRect(x, y, w, h)
        self:_render(bb)
        util.usleep(tonumber(flash)*1000)
        self.sdl_bb:setRotation(bb:getRotation())
        self.sdl_bb:setInverse(bb:getInverse())
        self.sdl_bb:blitFrom(bb, x, y, x, y, w, h)
    end
    self:_render(bb)
end

function framebuffer:setWindowTitle(new_title)
    framebuffer.parent.setWindowTitle(self, new_title)
    SDL.SDL.SDL_SetWindowTitle(SDL.screen, self.window_title)
end

function framebuffer:close()
    SDL.SDL.SDL_Quit()
end

return require("ffi/framebuffer"):extend(framebuffer)
