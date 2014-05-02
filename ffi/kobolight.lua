local ffi = require("ffi")
-- for closing on garbage collection, we need a pointer or aggregate
-- cdata object (not a plain "int"). So we encapsulate in a struct.
ffi.cdef[[
typedef struct light_fd { int ld; } light_fd;
]]

-- for ioctl header definition:
local dummy = require("ffi/posix_h")

local kobolight = {}
local kobolight_mt = {__index={}}

function kobolight_mt.__index:close()
	-- this is redundant to garbage collection of the
	-- whole object and not strictly needed.
	-- it allows to force-close immediately, though.
	if self.light_fd and self.light_fd.ld ~= -1 then
		ffi.C.close(self.light_fd.ld)
		self.light_fd.ld = -1
	end
end

function kobolight_mt.__index:toggle()
	if self.isOn then
		self.savedBrightness = self.brightness
		self:setBrightness(0)
	else
		self:setBrightness(self.savedBrightness or 0)
	end
end

function kobolight_mt.__index:sleep()
	if self.isOn then
		self.sleepLight = true
		self:toggle()
	end
end

function kobolight_mt.__index:restore()
	if self.sleepLight then
		self:toggle()
	end
end

function kobolight_mt.__index:setBrightness(brightness)
	assert(brightness >= 0 and brightness <= 100,
		"Wrong brightness value given!")

	assert(ffi.C.ioctl(self.light_fd.ld, 241, ffi.cast("int", brightness)) == 0,
		"cannot change brightess value")

	self.brightness = brightness
	if brightness > 0 then
		self.isOn = true
	else
		self.isOn = false
	end
end

function kobolight_mt.__index:restoreBrightness(brightness)
	self.brightness = brightness
	self.savedBrightness = brightness
end

function kobolight.open(device)
	local light = {
		light_fd = nil,
		brightness = 0,
		isOn = false
	}

	local ld = ffi.C.open(device or "/dev/ntx_io", ffi.C.O_RDWR)
	assert(ld ~= -1, "cannot open light device")
	light.light_fd = ffi.gc(
		ffi.new("light_fd", ld),
		function (light_fd) ffi.C.close(light_fd.ld) end
	)

	setmetatable(light, kobolight_mt)
	return light
end

return kobolight
