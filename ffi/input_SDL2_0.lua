-- load common SDL input/video library
local SDL = require("ffi/SDL2_0")

return {
    open = SDL.open,
    waitForEvent = SDL.waitForEvent,
    -- NOPs:
    fakeTapInput = function() end,
    close = function() end,
    -- Input & Output are handled as one, and we call SDL_Quit in fb:close already
    closeAll = function() end,
    -- Tell front that we're a custom imp with no concept of paths/fd
    is_ffi = true,
    hasClipboardText = SDL.hasClipboardText,
    getClipboardText = SDL.getClipboardText,
    setClipboardText = SDL.setClipboardText,
    gameControllerRumble = SDL.gameControllerRumble,
}
