local util = require("ffi/util")

if util.isEmulated() then
	if util.haveSDL2() then
		return require("ffi/framebuffer_SDL2_0")
	else
		return require("ffi/framebuffer_SDL1_2")
	end
elseif util.isAndroid() then
	return require("ffi/framebuffer_android")
else
	return require("ffi/framebuffer_linux")
end

