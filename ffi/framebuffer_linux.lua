local ffi = require("ffi")
local bit = require("bit")
local BB = require("ffi/blitbuffer")

local dummy = require("ffi/linux_fb_h")
local dummy = require("ffi/posix_h")

local framebuffer = {}
local framebuffer_mt = {__index={}}
-- Init our marker to 0, which happens to be an invalid value, so we can detect our first update
local update_marker = ffi.new("uint32_t[1]", 0)

local function einkfb_update(fb, refreshtype, waveform_mode, x, y, w, h)
	local refarea = ffi.new("struct update_area_t[1]")

	refarea[0].x1 = x or 0
	refarea[0].y1 = y or 0
	refarea[0].x2 = x + (w or (fb.vinfo.xres-x))
	refarea[0].y2 = y + (h or (fb.vinfo.yres-y))
	refarea[0].buffer = nil
	if refreshtype == 0 then
		refarea[0].which_fx = ffi.C.fx_update_partial
	else
		refarea[0].which_fx = ffi.C.fx_update_full
	end

	ioctl(fb.fd, ffi.C.FBIO_EINK_UPDATE_DISPLAY_AREA, refarea);
end

local function mxc_new_update_marker()
	-- Simply increment our current marker
	local new_update_marker = ffi.new("uint32_t[1]", update_marker[0] + 1)
	-- 1 to 16, strictly clamped.
	if new_update_marker[0] > 16 or new_update_marker[0] < 1 then
		new_update_marker[0] = 1
	end
	-- Keep track of it, and return it
	update_marker[0] = new_update_marker[0]
	return new_update_marker[0]
end

local function kindle_pearl_mxc_wait_for_update_complete(fb)
	-- Wait for the previous update to be completed
	print("# Send MXCFB_WAIT_FOR_UPDATE_COMPLETE_PEARL for marker="..update_marker[0])
	return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_COMPLETE_PEARL, update_marker)
end

local function kindle_carta_mxc_wait_for_update_complete(fb)
	-- Wait for the previous update to be completed
	local carta_update_marker = ffi.new("struct mxcfb_update_marker_data[1]")
	carta_update_marker[0].update_marker = update_marker[0];
	-- We're not using EPDC_FLAG_TEST_COLLISION, assume 0 is okay.
	carta_update_marker[0].collision_test = 0;
	print("# Send MXCFB_WAIT_FOR_UPDATE_COMPLETE for marker="..update_marker[0])
	return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_COMPLETE, carta_update_marker)
end

local function mxc_update(fb, refarea, refreshtype, waveform_mode, x, y, w, h)
	refarea[0].update_mode = refreshtype or 0
	refarea[0].waveform_mode = waveform_mode or 2
	refarea[0].update_region.left = x or 0
	refarea[0].update_region.top = y or 0
	refarea[0].update_region.width = w or fb.vinfo.xres
	refarea[0].update_region.height = h or fb.vinfo.yres
	-- Get a new update marker
	refarea[0].update_marker = mxc_new_update_marker()
	-- TODO: make the flag configurable from UI,
	-- e.g., the EPDC_FLAG_ENABLE_INVERSION flag inverts all the pixels on display  09.01 2013 (houqp)
	refarea[0].flags = 0
	-- NOTE: We're not using EPDC_FLAG_USE_ALT_BUFFER
	refarea[0].alt_buffer_data.phys_addr = 0
	refarea[0].alt_buffer_data.width = 0
	refarea[0].alt_buffer_data.height = 0
	refarea[0].alt_buffer_data.alt_update_region.top = 0
	refarea[0].alt_buffer_data.alt_update_region.left = 0
	refarea[0].alt_buffer_data.alt_update_region.width = 0
	refarea[0].alt_buffer_data.alt_update_region.height = 0
	print("# Send MXCFB_SEND_UPDATE for marker="..update_marker[0])
	ffi.C.ioctl(fb.fd, ffi.C.MXCFB_SEND_UPDATE, refarea)
end

local function kindle_mxc_wait_for_update_submission(fb)
	-- Wait for the current (the one we just sent) update to be submitted
	print("# Send MXCFB_WAIT_FOR_UPDATE_SUBMISSION for marker="..update_marker[0])
	return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_SUBMISSION, update_marker)
end

local function k51_update(fb, refreshtype, waveform_mode, x, y, w, h)
	local refarea = ffi.new("struct mxcfb_update_data[1]")
	-- only for Amazon's driver (NOTE: related to debugPaint prefbw & prefgray?):
	refarea[0].hist_bw_waveform_mode = 0
	refarea[0].hist_gray_waveform_mode = 0
	-- TEMP_USE_PAPYRUS on Touch/PW1, TEMP_USE_AUTO on PW2
	refarea[0].temp = 0x1001

	return mxc_update(fb, refarea, refreshtype, waveform_mode, x, y, w, h)
end

local function kobo_update(fb, refreshtype, waveform_mode, x, y, w, h)
	local refarea = ffi.new("struct mxcfb_update_data[1]")
	-- only for Kobo's driver:
	refarea[0].alt_buffer_data.virt_addr = nil
	-- TEMP_USE_AMBIENT
	refarea[0].temp = 0x1000

	return mxc_update(fb, refarea, refreshtype, waveform_mode, x, y, w, h)
end

function framebuffer.open(device)
	local fb = {
		fd = -1,
		finfo = ffi.new("struct fb_fix_screeninfo"),
		vinfo = ffi.new("struct fb_var_screeninfo"),
		fb_size = -1,
		einkWaitForCompleteFunc = nil,
		einkUpdateFunc = nil,
		einkWaitForSubmissionFunc = nil,
		wait_for_full_updates = false,
		wait_for_every_updates = false,
		bb = nil,
		data = nil
	}
	setmetatable(fb, framebuffer_mt)

	fb.fd = ffi.C.open(device, ffi.C.O_RDWR)
	assert(fb.fd ~= -1, "cannot open framebuffer")

	-- Get fixed screen information
	assert(ffi.C.ioctl(fb.fd, ffi.C.FBIOGET_FSCREENINFO, fb.finfo) == 0,
		"cannot get screen info")

	assert(ffi.C.ioctl(fb.fd, ffi.C.FBIOGET_VSCREENINFO, fb.vinfo) == 0,
		"cannot get variable screen info")

	assert(fb.finfo.type == ffi.C.FB_TYPE_PACKED_PIXELS,
		"video type not supported")

	--Kindle Paperwhite doesn't set this properly?
	--assert(fb.vinfo.grayscale == 0, "only grayscale is supported but framebuffer says it isn't")
	assert(fb.vinfo.xres_virtual > 0 and fb.vinfo.yres_virtual > 0, "invalid framebuffer resolution")

	-- it seems that fb.finfo.smem_len is unreliable on kobo
	-- Figure out the size of the screen in bytes
	fb.fb_size = fb.vinfo.xres_virtual * fb.vinfo.yres_virtual * fb.vinfo.bits_per_pixel / 8

	fb.data = ffi.C.mmap(nil, fb.fb_size, bit.bor(ffi.C.PROT_READ, ffi.C.PROT_WRITE), ffi.C.MAP_SHARED, fb.fd, 0)
	assert(fb.data ~= ffi.C.MAP_FAILED, "can not mmap() framebuffer")

	if ffi.string(fb.finfo.id, 11) == "mxc_epdc_fb" then
		-- TODO: implement a better check for Kobo
		if fb.vinfo.bits_per_pixel == 16 then
			-- this ought to be a Kobo
			local dummy = require("ffi/mxcfb_kobo_h")
			fb.einkUpdateFunc = kobo_update
			fb.bb = BB.new(fb.vinfo.xres, fb.vinfo.yres, BB.TYPE_BBRGB16, fb.data, fb.finfo.line_length)
			fb.bb:invert()
			if fb.vinfo.xres > fb.vinfo.yres then
				-- Kobo framebuffers need to be rotated counter-clockwise (they start in landscape mode)
				fb.bb:rotate(-90)
			end
		elseif fb.vinfo.bits_per_pixel == 8 then
			-- Kindle PaperWhite and KT with 5.1 or later firmware
			local dummy = require("ffi/mxcfb_kindle_h")
			-- NOTE: We need to differentiate the PW2 from the Touch/PW1... I hope this check is solid enough... (cf #550)
			if fb.vinfo.xres == 758 and fb.vinfo.yres == 1024 and fb.vinfo.xres_virtual == 768 and fb.vinfo.yres_virtual == 4096 then
				-- We're a PW2! Use the correct function, and ask to wait for every update.
				fb.wait_for_every_updates = true
				fb.einkWaitForCompleteFunc = kindle_carta_mxc_wait_for_update_complete
			else
				-- We're a Touch/PW1
				fb.wait_for_full_updates = true
				fb.einkWaitForCompleteFunc = kindle_pearl_mxc_wait_for_update_complete
			end
			fb.einkUpdateFunc = k51_update
			fb.einkWaitForSubmissionFunc = kindle_mxc_wait_for_update_submission
			fb.bb = BB.new(fb.vinfo.xres, fb.vinfo.yres, BB.TYPE_BB8, fb.data, fb.finfo.line_length)
			fb.bb:invert()
		else
			error("unknown bpp value for the mxc eink driver")
		end
	elseif ffi.string(fb.finfo.id, 7) == "eink_fb" then
		local dummy = require("ffi/einkfb_h")
		fb.einkUpdateFunc = einkfb_update

		if fb.vinfo.bits_per_pixel == 8 then
			fb.bb = BB.new(fb.vinfo.xres, fb.vinfo.yres, BB.TYPE_BB8, fb.data, fb.finfo.line_length)
		elseif fb.vinfo.bits_per_pixel == 4 then
			fb.bb = BB.new(fb.vinfo.xres, fb.vinfo.yres, BB.TYPE_BB4, fb.data, fb.finfo.line_length)
		else
			error("unknown bpp value for the classic eink driver")
		end
	else
		error("eink model not supported");
	end

	return fb
end

function framebuffer_mt:getOrientation()
	local mode = ffi.new("int[1]")
	ffi.C.ioctl(self.fd, ffi.C.FBIO_EINK_GET_DISPLAY_ORIENTATION, mode)

	-- adjust ioctl's rotate mode definition to KPV's
	-- refer to screen.lua
	if mode == 2 then
		return 1
	elseif mode == 1 then
		return 2
	end
	return mode
end

function framebuffer_mt:setOrientation(mode)
	mode = ffi.cast("int", mode or 0)
	if mode < 0 or mode > 3 then
		error("Wrong rotation mode given!")
	end

	--[[
         ioctl has a different definition for rotation mode.
	 	          1
	 	   +--------------+
	 	   | +----------+ |
	 	   | |          | |
	 	   | | Freedom! | |
	 	   | |          | |
	 	   | |          | |
	 	 3 | |          | | 2
	 	   | |          | |
	 	   | |          | |
	 	   | +----------+ |
	 	   |              |
	 	   |              |
	 	   +--------------+
	 	          0
	--]]
	if mode == 1 then
		mode = 2
	elseif mode == 2 then
		mode = 1
	end

	ffi.C.ioctl(self.fd, ffi.C.FBIO_EINK_SET_DISPLAY_ORIENTATION, mode)
end

function framebuffer_mt.__index:refresh(refreshtype, waveform_mode, x, y, w, h)
	-- The Touch/PW1 only do this for full updates
	if refreshtype == 1 and self.wait_for_full_updates or self.wait_for_every_updates then
		-- Start by checking that our previous update has completed
		if self.einkWaitForCompleteFunc then
			-- We have nothing to check on our first refresh() call!
			if update_marker[0] ~= 0 then
				-- TODO: Check return value?
				self:einkWaitForCompleteFunc()
				print("# Sent MXCFB_WAIT_FOR_UPDATE_COMPLETE(_PEARL) marker="..update_marker[0])
			end
		end
	end

	w, x = BB.checkBounds(w or self.bb:getWidth(), x or 0, 0, self.bb:getWidth(), 0xFFFF)
	h, y = BB.checkBounds(h or self.bb:getHeight(), y or 0, 0, self.bb:getHeight(), 0xFFFF)
	x, y, w, h = self.bb:getPhysicalRect(x, y, w, h)
	self:einkUpdateFunc(refreshtype, waveform_mode, x, y, w, h)
	print("# Sent MXCFB_SEND_UPDATE for marker="..update_marker[0])

	-- Finish by waiting for our curren tupdate to be submitted
	if refreshtype == 1 and self.wait_for_full_updates or self.wait_for_every_updates then
		if self.einkWaitForSubmissionFunc then
			-- TODO: Check return value?
			self:einkWaitForSubmissionFunc()
			print("# Sent MXCFB_WAIT_FOR_UPDATE_SUBMISSION for marker="..update_marker[0])
		end
	end
end

function framebuffer_mt.__index:getSize()
	return self.bb:getWidth(), self.bb:getHeight()
end

function framebuffer_mt.__index:getPitch()
	return self.bb.pitch
end

function framebuffer_mt.__index:close()
	ffi.C.munmap(self.data, self.fb_size)
	ffi.C.close(self.fd)
	self.fd = -1
	self.data = nil
	self.bb = nil
end

return framebuffer
