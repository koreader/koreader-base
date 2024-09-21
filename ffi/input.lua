local util = require("ffi/util")

if util.haveSDL2() then
    return require("ffi/input_SDL2_0")
elseif util.isAndroid() then
    return require("ffi/input_android")
elseif util.isPocketbook() then
    return require("ffi/input_pocketbook")
else
    return require("libs/libkoreader-input")
end
