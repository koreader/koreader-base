-- load common SDL input/video library
local SDL = require("ffi/SDL1_2")

return {
	open = SDL.open,
	waitForEvent = SDL.waitForEvent,
	-- NOP:
	fakeTapInput = function() end,
	-- NOP:
	closeAll = function() end
}
