local util = require("ffi/util")

if util.isSDL() then
    if util.haveSDL2() then
        return require("ffi/input_SDL2_0")
    end
elseif util.isAndroid() then
    return require("ffi/input_android")
    -- FIXME: Currently we support both ffi poll mode, and InkViewMain thread wrapper.
    -- Nuke this global check once we switch the client to poll mode exclusively.
elseif util.isPocketbook() and _G.POCKETBOOK_FFI then
    return require("ffi/input_pocketbook")
else
    return require("libs/libkoreader-input")
end
