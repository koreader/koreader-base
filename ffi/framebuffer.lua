local util = require("ffi/util")

if util.isEmulated() then
	return require("ffi/framebuffer_SDL2_0")
else
	return require("ffi/framebuffer_linux")
end

