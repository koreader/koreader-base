--[[
Generic blitbuffer/GFX stuff that works on memory buffers
--]]

local ffi = require("ffi")

-- we will use this extensively
local floor = math.floor
local rshift = bit.rshift
local lshift = bit.lshift
local band = bit.band
local bor = bit.bor
local int = ffi.typeof("int32_t")

ffi.cdef[[
typedef struct BlitBuffer {
        int w; 
        int h; 
        int pitch;
        uint8_t *data;
        uint8_t allocated;
} BlitBuffer;

void *malloc(int size);
void free(void *ptr);
void *memset(void *s, int c, int n);
]]

local BB = {}
local BBtype = ffi.typeof("BlitBuffer*")

-- metatable for BlitBuffer objects:
local BB_mt = {__index={}}

--[[
get width of BlitBuffer

@return width
--]]
function BB_mt.__index:getWidth()
	return self.w
end

--[[
get height of BlitBuffer

@return height
--]]
function BB_mt.__index:getHeight()
	return self.h
end

--[[
get a color value for a certain pixel

@param x X coordinate
@param y Y coordinate
--]]
function BB_mt.__index:getPixel(x, y)
	local value = self.data[y*self.pitch + rshift(x, 1)]
	if x % 2 == 1 then
		value = band(value, 0x0F)
	else
		value = rshift(value, 4)
	end
	return value
end

--[[
set a color value for a certain pixel

@param x X coordinate
@param y Y coordinate
@param value color value (currently 0-15 for 4bpp BlitBuffers)
--]]
function BB_mt.__index:setPixel(x, y, value)
	-- do nothing if not in our range:
	if x < 0 or x >= self.w or y < 0 or y >= self.h then return end
	local pos = y * self.pitch + rshift(x, 1)
	if x % 2 == 1 then
		self.data[pos] = bor(band(self.data[pos], 0xF0), value)
	else
		self.data[pos] = bit.bor(bit.band(self.data[pos], 0x0F), bit.lshift(value, 4))
	end
end

--[[
generic boundary check for copy operations

@param length length of copy operation
@param target_offset where to place part into target
@param source_offset where to take part from in source
@param target_size length of target buffer
@param source_size length of source buffer

@return adapted length that actually fits
@return adapted target offset, guaranteed within range 0..(target_size-1)
@return adapted source offset, guaranteed within range 0..(source_size-1)
--]]
function BB.checkBounds(length, target_offset, source_offset, target_size, source_size)
	if target_offset < 0 then
		length = length + target_offset
		source_offset = source_offset - target_offset
		target_offset = 0
	end
	if source_offset < 0 then
		length = length + source_offset
		target_offset = target_offset - source_offset
		source_offset = 0
	end
	local target_left = target_size - target_offset
	local source_left = source_size - source_offset
	if length <= target_left and length <= source_left then
		return length, target_offset, source_offset
	elseif target_left < length and target_left < source_left then
		return target_left, target_offset, source_offset
	else
		return source_left, target_offset, source_offset
	end
end

-- standard writers for blitting
local function write_lower_default(dest_ptr, value)
	dest_ptr[0] = band(dest_ptr[0], 0xF0)
	dest_ptr[0] = bor(dest_ptr[0], value)
end
local function write_upper_default(dest_ptr, value)
	dest_ptr[0] = band(dest_ptr[0], 0x0F)
	dest_ptr[0] = bor(dest_ptr[0], value)
end
local function write_full_default(dest_ptr, value)
	dest_ptr[0] = value
end

--[[
Blits a given source buffer onto this buffer

@param source buffer to get data from
@param dest_x X coordinate to blit to
@param dest_y Y coordinate to blit to
@param offs_x X coordinate of source rectangle in source buffer
@param offs_y Y coordinate of source rectangle in source buffer
@param width width of source rectangle
@param height height of source rectangle
@param write_full function(ptr, value, param) that writes value to ptr[0], potentially modifying it according to param
@param write_upper function(ptr, value, param) that writes value to upper nibble of ptr[0], potentially modifying it according to param
@param write_lower function(ptr, value, param) that writes value to lower nibble of ptr[0], potentially modifying it according to param
@param blit_param param for write functions, *must* be set if alternative write functions are to be used
--]]
function BB_mt.__index:blit4From4(source, dest_x, dest_y, offs_x, offs_y, width, height,
	write_full, write_upper, write_lower, blit_param)

	dest_x, dest_y, offs_x, offs_y, width, height =
		tonumber(ffi.cast(int, dest_x or 0)),
		tonumber(ffi.cast(int, dest_y or 0)),
		tonumber(ffi.cast(int, offs_x or 0)),
		tonumber(ffi.cast(int, offs_y or 0)),
		tonumber(ffi.cast(int, width or source:getWidth())),
		tonumber(ffi.cast(int, height or source:getHeight()))

	if not blit_param then
		write_full = write_full_default
		write_upper = write_upper_default
		write_lower = write_lower_default
	end

	source = ffi.cast(BBtype, source)

	width, dest_x, offs_x = BB.checkBounds(width, dest_x, offs_x, self.w, source.w)
	height, dest_y, offs_y = BB.checkBounds(height, dest_y, offs_y, self.h, source.h)

	local dest_pitch = self.pitch
	local dest_ptr = self.data + dest_y * dest_pitch + rshift(dest_x, 1)
	local src_pitch = source.pitch
	local src_ptr = source.data + offs_y * src_pitch + rshift(offs_x, 1)
	if band(dest_x, 1) == 1 then
		-- this will render the leftmost column when we have
		-- an odd target coordinate (update lower nibble)
		if band(offs_x, 1) == 1 then
			-- odd source coordinate: take lower nibble
			for y = 1, height do
				write_lower(dest_ptr, band(src_ptr[0], 0x0F), blit_param)
				dest_ptr = dest_ptr + dest_pitch
				src_ptr = src_ptr + src_pitch
			end
		else
			-- even source coordinate: take upper nibble
			for y = 1, height do
				write_lower(dest_ptr, rshift(src_ptr[0], 4), blit_param)
				dest_ptr = dest_ptr + dest_pitch
				src_ptr = src_ptr + src_pitch
			end
		end
		-- update the parameters
		dest_x = dest_x + 1;
		offs_x = offs_x + 1;
		width = width - 1;
		dest_ptr = self.data + dest_y * dest_pitch + rshift(dest_x, 1)
		src_ptr = source.data + offs_y * src_pitch + rshift(offs_x, 1)
	end
	-- at this point, the target X coordinate is even

	-- cache length of full-byte (2 pixel) copies
	local l = rshift(width, 1)

	if band(offs_x, 1) == 1 then
		-- odd source coordinate:
		-- take lower nibble of source byte, make it upper nibble of target byte
		-- take upper nibble of following source byte, make it lower nibble of target byte
		for y = 1, height do
			for x = 0, l - 1 do
				write_full(dest_ptr + x, bor(lshift(src_ptr[x], 4), rshift(src_ptr[x+1], 4)), blit_param)
			end
			-- check for odd width, leaving one pixel to process:
			if band(width, 1) == 1 then
				write_upper(dest_ptr + l, lshift(src_ptr[l], 4), blit_param)
				dest_ptr[l] = band(dest_ptr[l], 0x0F)
				dest_ptr[l] = bor(dest_ptr[l], lshift(src_ptr[l], 4))
			end
			dest_ptr = dest_ptr + dest_pitch
			src_ptr = src_ptr + src_pitch
		end
	else
		-- simple case: even source coordinate, we can do a 1:1 byte copy
		for y = 1, height do
			if blit_param == nil then
				ffi.copy(dest_ptr, src_ptr, l)
			else
				for x = 0, l-1 do write_full(dest_ptr + x, src_ptr[x], blit_param) end
			end
			-- check for odd width, leaving one pixel to process
			if band(width, 1) == 1 then
				write_upper(dest_ptr + l, band(src_ptr[l], 0xF0), blit_param)
			end
			dest_ptr = dest_ptr + dest_pitch
			src_ptr = src_ptr + src_pitch
		end
	end
end
-- blitting 4 bits to 4 bits is the standard procedure
-- this can be made a function adapting to different depths
BB_mt.__index.blitFrom = BB_mt.__index.blit4From4

--[[
we use this as a transformation matrix
--]]
local rotate_table = {
	--  { cos, sin }
	[90]  = { 0, 1 }, -- 90 degrees
	[180] = {-1, 0 }, -- 180 degrees
	[270] = { 0, -1}  -- 270 degrees
}

--[[
blit a rotated version of a source buffer

@param source source buffer
@param degree (supported are 90, 180, 270 and 0)
--]]
function BB_mt.__index:blitFromRotate(source, degree)
	source = ffi.cast(BBtype, source)
	if degree == 0 then self:blitFullFrom(source) end
	local cosT, sinT = rotate_table[degree][1], rotate_table[degree][2]
	local y_adj = 0
	local x_adj = 0

	if degree == 90 then
		x_adj = self.w - 1
	elseif degree == 180 then
		y_adj = self.h - 1
		x_adj = self.w - 1
	elseif degree == 270 then
		y_adj = self.h - 1
	end
	
	local u = x_adj
	local v = y_adj;
	for j = 0, self.h - 1 do
		-- x = -sinT * j + x_adj;
		-- y = cosT * j + y_adj;
		local x = u
		local y = v
		for i = 0, self.w - 1 do
			-- each (i, j) maps to (x, y)
			-- x = cosT * i - sinT * j + x_adj;
			-- y = cosT * j + sinT * i + y_adj;
			self:setPixel(x, y, source:getPixel(i, j));
			x = x + cosT;
			y = y + sinT;
		end
		u = u - sinT;
		v = v + cosT;
	end
end

-- writers for blitting with retaining original value
local function write_lower_add(dest_ptr, value, intensity)
	value = value * intensity + band(dest_ptr[0], 0x0F) * (1-intensity)
	dest_ptr[0] = band(dest_ptr[0], 0xF0)
	dest_ptr[0] = bor(dest_ptr[0], value)
end
local function write_upper_add(dest_ptr, value, intensity)
	value = value * intensity + band(dest_ptr[0], 0xF0) * (1-intensity)
	dest_ptr[0] = band(dest_ptr[0], 0x0F)
	dest_ptr[0] = bor(dest_ptr[0], band(value, 0xF0))
end
local function write_full_add(dest_ptr, value, intensity)
	local value_low = band(value, 0x0F) * intensity + band(dest_ptr[0], 0x0F) * (1-intensity)
	local value_high = band(value, 0xF0) * intensity + band(dest_ptr[0], 0xF0) * (1-intensity)
	dest_ptr[0] = bor(band(value_low, 0x0F), band(value_high, 0xF0))
end
--[[
Blits a given source buffer onto this buffer retaining some degree of the previous

@param source buffer to get data from
@param dest_x X coordinate to blit to
@param dest_y Y coordinate to blit to
@param offs_x X coordinate of source rectangle in source buffer
@param offs_y Y coordinate of source rectangle in source buffer
@param width width of source rectangle
@param height height of source rectangle
@param intensity factor (0..1) that the blitted buffer gets multiplied with
--]]
function BB_mt.__index:addblitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height, intensity)
	self:blitFrom(source, dest_x, dest_y, offs_x, offs_y, width, height,
		write_full_add, write_upper_add, write_lower_add, intensity)
end

--[[
do a 1:1 blit

@param source buffer to get data from
--]]
function BB_mt.__index:blitFullFrom(source)
	source = ffi.cast(BBtype, source)
	if self.w ~= source.w
	or self.h ~= source.h
	or self.pitch ~= source.pitch
	then
		error("buffers do not have identical layout!")
	end
	ffi.copy(self.data, source.data, self.pitch * self.h)
end

--[[
paint a rectangle onto this buffer

@param x1 X coordinate
@param y1 Y coordinate
@param w width
@param h height
@param value color value
--]]
function BB_mt.__index:paintRect(x1, y1, w, h, value)
	if w <= 0 or h <= 0 then return end
	w, x1 = BB.checkBounds(w, x1, 0, self.w, 0xFFFF)
	h, y1 = BB.checkBounds(h, y1, 0, self.h, 0xFFFF)
	for y = y1, y1+h-1 do
		for x = x1, x1+w-1 do
			self:setPixel(x, y, value)
		end
	end
end

--[[
paint a circle onto this buffer

@param x1 X coordinate of the circle's center
@param y1 Y coordinate of the circle's center
@param r radius
@param c color value (defaults to black)
@param w width of line (defaults to radius)
--]]
function BB_mt.__index:paintCircle(center_x, center_y, r, c, w)
	if c == nil then c = 15 end
	if w == nil then w = r end

	if center_x + r > self.w or center_x - r < 0
	or center_y + r > self.h or center_y - r < 0
	or r == 0
	then
		return
	end

	if w > r then w = r end

	-- for outer circle
	local x = 0
	local y = r
	local delta = 5/4 - r

	-- for inner circle
	local r2 = r - w
	local x2 = 0
	local y2 = r2
	local delta2 = 5/4 - r

	-- draw two axles
	for tmp_y = r, r2+1, -1 do
		self:setPixel(center_x+0, center_y+tmp_y, c)
		self:setPixel(center_x-0, center_y-tmp_y, c)
		self:setPixel(center_x+tmp_y, center_y+0, c)
		self:setPixel(center_x-tmp_y, center_y-0, c)
	end

	while x < y do
		-- decrease y if we are out of circle
		x = x + 1;
		if delta > 0 then
			y = y - 1
			delta = delta + 2*x - 2*y + 2
		else
			delta = delta + 2*x + 1
		end

		-- inner circle finished drawing, increase y linearly for filling
		if x2 > y2 then
			y2 = y2 + 1
			x2 = x2 + 1
		else
			x2 = x2 + 1
			if delta2 > 0 then
				y2 = y2 - 1
				delta2 = delta2 + 2*x2 - 2*y2 + 2
			else
				delta2 = delta2 + 2*x2 + 1
			end
		end

		for tmp_y = y, y2+1, -1 do
			self:setPixel(center_x+x, center_y+tmp_y, c)
			self:setPixel(center_x+tmp_y, center_y+x, c)

			self:setPixel(center_x+tmp_y, center_y-x, c)
			self:setPixel(center_x+x, center_y-tmp_y, c)

			self:setPixel(center_x-x, center_y-tmp_y, c)
			self:setPixel(center_x-tmp_y, center_y-x, c)

			self:setPixel(center_x-tmp_y, center_y+x, c)
			self:setPixel(center_x-x, center_y+tmp_y, c)
		end
	end
	if r == w then
		self:setPixel(center_x, center_y, c)
	end
end

function BB_mt.__index:paintRoundedCorner(off_x, off_y, w, h, bw, r, c)
	if c == nil then c = 15 end

	if 2*r > h
	or 2*r > w
	or r == 0
	then
		return
	end

	r = math.min(r, h, w)
	if bw > r then
		bw = r
	end

	-- for outer circle
	local x = 0
	local y = r
	local delta = 5/4 - r

	-- for inner circle
	local r2 = r - bw
	local x2 = 0
	local y2 = r2
	local delta2 = 5/4 - r

	while x < y do
		-- decrease y if we are out of circle
		x = x + 1
		if delta > 0 then
			y = y - 1
			delta = delta + 2*x - 2*y + 2
		else
			delta = delta + 2*x + 1
		end

		-- inner circle finished drawing, increase y linearly for filling
		if x2 > y2 then
			y2 = y2 + 1
			x2 = x2 + 1
		else
			x2 = x2 + 1
			if delta2 > 0 then
				y2 = y2 - 1
				delta2 = delta2 + 2*x2 - 2*y2 + 2
			else
				delta2 = delta2 + 2*x2 + 1
			end
		end

		for tmp_y = y, y2+1, -1 do
			self:setPixel((w-r)+off_x+x-1, (h-r)+off_y+tmp_y-1, c)
			self:setPixel((w-r)+off_x+tmp_y-1, (h-r)+off_y+x-1, c)

			self:setPixel((w-r)+off_x+tmp_y-1, (r)+off_y-x, c)
			self:setPixel((w-r)+off_x+x-1, (r)+off_y-tmp_y, c)

			self:setPixel((r)+off_x-x, (r)+off_y-tmp_y, c)
			self:setPixel((r)+off_x-tmp_y, (r)+off_y-x, c)

			self:setPixel((r)+off_x-tmp_y, (h-r)+off_y+x-1, c)
			self:setPixel((r)+off_x-x, (h-r)+off_y+tmp_y-1, c)
		end
	end
end

--[[
modify pixel values of a rectangular area

@param x1 X coordinate
@param y1 Y coordinate
@param w width
@param h height
@param modification a Lua function taking a pixel color value and an optional parameter as arguments
@param parameter parameter that gets passed to modification function
--]]
function BB_mt.__index:modifyRect(x1, y1, w, h, modification, parameter)
	w, x1 = BB.checkBounds(w, x1, 0, self.w, 0xFFFF)
	h, y1 = BB.checkBounds(h, y1, 0, self.h, 0xFFFF)
	for y = y1, y1+h-1 do
		for x = x1, x1+w-1 do
			self:setPixel(x, y, modification(self:getPixel(x, y), parameter))
		end
	end
end


local function modifyInvert(value)
	return 15 - value
end

--[[
invert color values in rectangular area

@param x1 X coordinate
@param y1 Y coordinate
@param w width
@param h height
--]]
function BB_mt.__index:invertRect(x1, y1, w, h)
	self:modifyRect(x1, y1, w, h, modifyInvert)
end


local function modifyDim(value)
	return bit.rshift(value, 1)
end

--[[
dim color values in rectangular area

@param x1 X coordinate
@param y1 Y coordinate
@param w width
@param h height
--]]
function BB_mt.__index:dimRect(x1, y1, w, h)
	self:modifyRect(x1, y1, w, h, modifyDim)
end


local function modifyLighten(value, low)
	if value < low then return low end
	return value
end

--[[
lighten color values in rectangular area

@param x1 X coordinate
@param y1 Y coordinate
@param w width
@param h height
--]]
function BB_mt.__index:lightenRect(x1, y1, w, h, low)
	self:modifyRect(x1, y1, w, h, modifyLighten, low * 0x0F)
end

--[[
explicit unset

will free immediately
--]]
function BB_mt.__index:free()
	if self.allocated ~= 0 then
		ffi.C.free(self.data)
		self.allocated = 0
	end
end

--[[
memory management
--]]
BB_mt.__gc = BB_mt.__index.free

--[[
Return ASCII char resembling hex notation of @value

@value an integer between 0 and 15
--]]
local function hexChar(value)
	local offset = string.byte("0")
	if value >= 10 then offset = string.byte("A") - 10 end
	return string.char(offset+value)
end

--[[
Dump buffer as hex values for debugging
--]]
function BB_mt.__index:dumpHex()
	self = ffi.cast(BBtype, self)
	io.stdout:write("BlitBuffer, width=", self.w, ", height=", self.h, ", pitch=", self.pitch, "\n")
	for y = 0, self.h-1 do
		for x = 0, self.w-1 do
			io.stdout:write(hexChar(self:getPixel(x, y)))
		end
		io.stdout:write("\n")
	end
end

--[[
Draw a border

@x:  start position in x axis
@y:  start position in y axis
@w:  width of the border
@h:  height of the border
@bw: line width of the border
@c:  color for loading bar
@r:  radius of for border's corner (nil or 0 means right corner border)
--]]
function BB_mt.__index:paintBorder(x, y, w, h, bw, c, r)
	x, y = math.ceil(x), math.ceil(y)
	h, w = math.ceil(h), math.ceil(w)
	if not r or r == 0 then
		self:paintRect(x, y, w, bw, c)
		self:paintRect(x, y+h-bw, w, bw, c)
		self:paintRect(x, y+bw, bw, h - 2*bw, c)
		self:paintRect(x+w-bw, y+bw, bw, h - 2*bw, c)
	else
		if h < 2*r then r = math.floor(h/2) end
		if w < 2*r then r = math.floor(w/2) end
		self:paintRoundedCorner(x, y, w, h, bw, r, c)
		self:paintRect(r+x, y, w-2*r, bw, c)
		self:paintRect(r+x, y+h-bw, w-2*r, bw, c)
		self:paintRect(x, r+y, bw, h-2*r, c)
		self:paintRect(x+w-bw, r+y, bw, h-2*r, c)
	end
end


--[[
Fill a rounded corner rectangular area

@x:  start position in x axis
@y:  start position in y axis
@w:  width of the area
@h:  height of the area
@c:  color used to fill the area
@r:  radius of for four corners
--]]
function BB_mt.__index:paintRoundedRect(x, y, w, h, c, r)
	x, y = math.ceil(x), math.ceil(y)
	h, w = math.ceil(h), math.ceil(w)
	if not r or r == 0 then
		self:paintRect(x, y, w, h, c)
	else
		if h < 2*r then r = math.floor(h/2) end
		if w < 2*r then r = math.floor(w/2) end
		self:paintBorder(x, y, w, h, r, c, r)
		self:paintRect(x+r, y+r, w-2*r, h-2*r, c)
	end
end


--[[
Draw a progress bar according to following args:

@x:  start position in x axis
@y:  start position in y axis
@w:  width for progress bar
@h:  height for progress bar
@load_m_w: width margin for loading bar
@load_m_h: height margin for loading bar
@load_percent: progress in percent
@c:  color for loading bar
--]]
function BB_mt.__index:progressBar(x, y, w, h,
								load_m_w, load_m_h, load_percent, c)
	if load_m_h*2 > h then
		load_m_h = h/2
	end
	self:paintBorder(x, y, w, h, 2, 15)
	self:paintRect(x+load_m_w, y+load_m_h,
				(w-2*load_m_w)*load_percent, (h-2*load_m_h), c)
end

local BlitBuffer = ffi.metatype("BlitBuffer", BB_mt)

function BB.new(width, height, pitch, buffer)
	local allocated = 0
	if buffer == nil then
		if pitch == nil then
			pitch = bit.rshift(width + (width % 2), 1)
		end
		buffer = ffi.C.malloc(pitch * height)
		if buffer == nil then
			error("cannot allocate buffer")
		end
		ffi.fill(buffer, pitch * height)
		allocated = 1
	end
	return BlitBuffer(width, height, pitch, buffer, allocated)
end

return BB
