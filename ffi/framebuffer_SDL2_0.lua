local ffi = require("ffi")
-- load common SDL input/video library
local SDL = require("ffi/SDL2_0")
local BB = require("ffi/blitbuffer")
local util = require("ffi/util")

local uint8pt = ffi.typeof("uint8_t*")

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
        SDL.w = w
        SDL.h = h
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

    if self.sdl_bb then self.sdl_bb:free() end
    if self.bb then self.bb:free() end
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
end

function framebuffer:_render(bb, x, y, w, h)
    local bb_width = bb:getWidth()
    w, x = BB.checkBounds(w or bb_width, x or 0, 0, bb_width, 0xFFFF)
    h, y = BB.checkBounds(h or bb:getHeight(), y or 0, 0, bb:getHeight(), 0xFFFF)
    x, y, w, h = bb:getPhysicalRect(x, y, w, h)

    local cdata, mem
    -- width is variable, so not the same as bb.pitch
    -- this should be the same as 4*w
    local pitch = bb.pitch/bb_width * w
    local rect = SDL.rect(x, y, w, h)

    if bb:getInverse() == 1 then
        self.invert_bb:invertblitFrom(bb)
        bb = self.invert_bb
    end

    -- Optimize drawing from left at full width.
    -- SDL ignores superfluous data thanks to our rectangle
    -- in SDL_UpdateTexture
    if x == 0 and w == bb_width then
        mem = ffi.cast(bb.data, ffi.cast(uint8pt, bb.data) + bb.pitch*y)
    -- copy the relevant rectangular section of the BB
    else
        -- @TODO also use this on Android?
        cdata = ffi.C.malloc(w * h * 4)
        mem = ffi.cast("char*", cdata)
        local offset_counter = 0
        for from_top = y, y+h-1 do
            local offset = 4 * w * offset_counter
            offset_counter = offset_counter + 1
            for from_left = x, x+w-1 do
                local c = bb:getPixel(from_left, from_top):getColorRGB32()
                mem[offset] = c.r
                mem[offset + 1] = c.g
                mem[offset + 2] = c.b
                mem[offset + 3] = 0xFF
                offset = offset + 4
            end
        end
    end

    SDL.SDL.SDL_UpdateTexture(SDL.texture, rect, mem, pitch)

    SDL.SDL.SDL_RenderClear(SDL.renderer)
    SDL.SDL.SDL_RenderCopy(SDL.renderer, SDL.texture, nil, nil)
    SDL.SDL.SDL_RenderPresent(SDL.renderer)

    ffi.C.free(cdata)
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
        self:_render(self.sdl_bb, x, y, w, h)
        util.usleep(tonumber(flash)*1000)
        self.sdl_bb:setRotation(bb:getRotation())
        self.sdl_bb:setInverse(bb:getInverse())
        self.sdl_bb:blitFrom(bb, x, y, x, y, w, h)
    end
    self:_render(bb, x, y, w, h)
end

function framebuffer:setWindowTitle(new_title)
    framebuffer.parent.setWindowTitle(self, new_title)
    SDL.SDL.SDL_SetWindowTitle(SDL.screen, self.window_title)
end

function framebuffer:close()
    SDL.SDL.SDL_Quit()
end

return require("ffi/framebuffer"):extend(framebuffer)
