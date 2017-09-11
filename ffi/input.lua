local util = require("ffi/util")

if util.isSDL() then
    if util.haveSDL2() then
        return require("ffi/input_SDL2_0")
    else
        return require("ffi/input_SDL1_2")
    end
elseif util.isAndroid() then
    return require("ffi/input_android")
else
    return require("libs/libkoreader-input")
end
