local util = require("ffi/util")

if util.isEmulated() then
	return require("ffi/framebuffer_SDL")
else
	return require("ffi/framebuffer_linux")
end

