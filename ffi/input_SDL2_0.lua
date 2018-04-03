local FileChooser = require("ffi/filechooser")
-- load common SDL input/video library
local SDL = require("ffi/SDL2_0")

return {
    open = SDL.open,
    waitForEvent = SDL.waitForEvent,
    -- NOP:
    fakeTapInput = function() end,
    -- NOP:
    closeAll = function() end,
    hasClipboardText = SDL.hasClipboardText,
    getClipboardText = SDL.getClipboardText,
    setClipboardText = SDL.setClipboardText,
    file_chooser = FileChooser,
}
