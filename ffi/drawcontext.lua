--[[
Drawcontext structure

FFI frontend
]]

local ffi = require "ffi"

ffi.cdef[[
typedef struct DrawContext {
	int rotate;
	double zoom;
	double gamma;
	double saturation;
	int offset_x;
	int offset_y;
	bool background_cleanup;
} DrawContext;
]]

local DC = {}
local DC_mt = {__index={}}

function DC_mt.__index:setRotate(rotate) self.rotate = rotate end
function DC_mt.__index:getRotate() return self.rotate end
function DC_mt.__index:setZoom(zoom) self.zoom = zoom end
function DC_mt.__index:getZoom() return self.zoom end
function DC_mt.__index:setOffset(x, y)
	self.offset_x = x or 0
	self.offset_y = y or 0
end
function DC_mt.__index:getOffset() return self.offset_x, self.offset_y end
function DC_mt.__index:setGamma(gamma) self.gamma = gamma end
function DC_mt.__index:getGamma() return self.gamma end
function DC_mt.__index:setBackgroundCleanup(background_cleanup) self.background_cleanup = background_cleanup end
function DC_mt.__index:getBackgroundCleanup() return self.background_cleanup end
function DC_mt.__index:setSaturation(saturation) self.saturation = saturation end
function DC_mt.__index:getSaturation() return self.saturation end

local dctype = ffi.metatype("DrawContext", DC_mt)

function DC.new(rotate, zoom, x, y, gamma, background_cleanup, saturation)
	return dctype(rotate or 0, zoom or 1.0, gamma or -1.0, saturation or 1.0, x or 0, y or 0, background_cleanup or false)
end

return DC
