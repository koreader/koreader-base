local ffi = require("ffi")
local android = require("android")
local BB = require("ffi/blitbuffer")
local C = ffi.C

local framebuffer = {}

function framebuffer:init()
    -- we present this buffer to the outside
    self.bb = BB.new(android.screen.width, android.screen.height, BB.TYPE_BBRGB32)
    self.invert_bb = BB.new(android.screen.width, android.screen.height, BB.TYPE_BBRGB32)
    -- TODO: should we better use these?
    -- android.lib.ANativeWindow_getWidth(window)
    -- android.lib.ANativeWindow_getHeight(window)
    self.bb:fill(BB.COLOR_WHITE)
    self:refreshFull()

    framebuffer.parent.init(self)
end

function framebuffer:refreshFullImp()
    if android.app.window == nil then
        android.LOGW("cannot blit: no window")
        return
    end

    local buffer = ffi.new("ANativeWindow_Buffer[1]")
    if android.lib.ANativeWindow_lock(android.app.window, buffer, nil) < 0 then
        android.LOGW("Unable to lock window buffer")
        return
    end

    local bb = nil
    if buffer[0].format == C.WINDOW_FORMAT_RGBA_8888
    or buffer[0].format == C.WINDOW_FORMAT_RGBX_8888
    then
        bb = BB.new(buffer[0].width, buffer[0].height, BB.TYPE_BBRGB32, buffer[0].bits, buffer[0].stride*4)
    elseif buffer[0].format == C.WINDOW_FORMAT_RGB_565 then
        bb = BB.new(buffer[0].width, buffer[0].height, BB.TYPE_BBRGB16, buffer[0].bits, buffer[0].stride*2)
    else
        android.LOGE("unsupported window format!")
    end

    if bb then
        local ext_bb = self.full_bb or self.bb

        bb:setInverse(ext_bb:getInverse())
        -- adapt to possible rotation changes
        bb:setRotation(ext_bb:getRotation())

        if ext_bb:getInverse() == 1 then
            self.invert_bb:invertblitFrom(ext_bb)
            bb:blitFrom(self.invert_bb)
        else
            bb:blitFrom(ext_bb)
        end
    end

    android.lib.ANativeWindow_unlockAndPost(android.app.window);
end

return require("ffi/framebuffer"):extend(framebuffer)
