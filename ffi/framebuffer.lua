local util = require("ffi/util")

if util.isEmulated() then
	return require("ffi/framebuffer_SDL1_2")
else
	return require("ffi/framebuffer_linux")
end

