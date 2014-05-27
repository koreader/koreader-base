local ffi = require("ffi")
local bit = require("bit")

local BB = require("ffi/blitbuffer")
local android = require("android")

local fb = {}

local function waitForInitWindowCMD()
    while true do
        local events = ffi.new("int[1]")
        local source = ffi.new("struct android_poll_source*[1]")
        if ffi.C.ALooper_pollAll(1000, nil, events, ffi.cast("void**", source)) >= 0 then
            if source[0] ~= nil and source[0].id == ffi.C.LOOPER_ID_MAIN then
                local cmd = ffi.C.android_app_read_cmd(android.app)
                ffi.C.android_app_pre_exec_cmd(android.app, cmd)
                ffi.C.android_app_post_exec_cmd(android.app, cmd)
                if cmd == ffi.C.APP_CMD_INIT_WINDOW then return end
            end
        end
    end
end

function fb.open()
    if not fb.bb then
        waitForInitWindowCMD()
        local window = android.app.window
        if window ~= nil then
            local width = ffi.C.ANativeWindow_getWidth(window)
            local height = ffi.C.ANativeWindow_getHeight(window)
            -- we present this buffer to the outside
            fb.bb = BB.new(width, height)
            fb:refresh()
        end
    end
    return fb
end

function fb:getSize()
    local window = android.app.window
    if window ~= nil then
        local width = ffi.C.ANativeWindow_getWidth(window)
        local height = ffi.C.ANativeWindow_getHeight(window)
        return tonumber(width), tonumber(height)
    end
end

function fb:getPitch()
    error("not implemented")
end

function fb:setOrientation(mode)
    if mode == 1 or mode == 3 then
        -- TODO: landscape setting
    else
        -- TODO: flip back to portrait
    end
end

function fb:getOrientation()
    local w, h = self:getSize()
    if w > h then
        return 1
    else
        return 0
    end
end

function fb:refresh(refreshtype, waveform_mode, x1, y1, w, h)
    if x1 == nil then x1 = 0 end
    if y1 == nil then y1 = 0 end


    if android.app.window == nil then
        android.LOGW("cannot blit: no window")
        return
    end

    local buffer = ffi.new("ANativeWindow_Buffer[1]")
    if ffi.C.ANativeWindow_lock(android.app.window, buffer, nil) < 0 then
        android.LOGW("Unable to lock window buffer")
        return
    end

    local bb = nil
    if buffer[0].format == ffi.C.WINDOW_FORMAT_RGBA_8888
    or buffer[0].format == ffi.C.WINDOW_FORMAT_RGBX_8888
    then
        bb = Blitbuffer.new(buffer[0].width, buffer[0].height, Blitbuffer.TYPE_BBRGB32, buffer[0].bits, buffer[0].stride*4)
    elseif buffer[0].format == ffi.C.WINDOW_FORMAT_RGB_565 then
        bb = Blitbuffer.new(buffer[0].width, buffer[0].height, Blitbuffer.TYPE_BBRGB16, buffer[0].bits, buffer[0].stride*2)
    else
        android.LOGE("unsupported window format!")
    end

    if bb then
        bb:invert()
        -- adapt to possible rotation changes
        bb:setRotation(self.bb:getRotation())

        bb:blitFrom(self.bb, x1, y1, x1, y1, w, h)
    end

    ffi.C.ANativeWindow_unlockAndPost(android.app.window);
end

function fb:close()
    -- for now, we do nothing when in emulator mode
end

return fb
