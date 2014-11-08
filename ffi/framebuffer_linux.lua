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
	if refreshtype == ffi.C.UPDATE_MODE_PARTIAL then
		refarea[0].which_fx = ffi.C.fx_update_partial
	else
		refarea[0].which_fx = ffi.C.fx_update_full
	end

	ffi.C.ioctl(fb.fd, ffi.C.FBIO_EINK_UPDATE_DISPLAY_AREA, refarea);
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

-- Kindle's MXCFB_WAIT_FOR_UPDATE_COMPLETE_PEARL == 0x4004462f
local function kindle_pearl_mxc_wait_for_update_complete(fb)
	-- Wait for the previous update to be completed
	return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_COMPLETE_PEARL, update_marker)
end

-- Kobo's MXCFB_WAIT_FOR_UPDATE_COMPLETE == 0x4004462f
local function kobo_mxc_wait_for_update_complete(fb)
	-- Wait for the previous update to be completed
	return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_COMPLETE, update_marker)
end

-- Kindle's MXCFB_WAIT_FOR_UPDATE_COMPLETE == 0xc008462f
local function kindle_carta_mxc_wait_for_update_complete(fb)
	-- Wait for the previous update to be completed
	local carta_update_marker = ffi.new("struct mxcfb_update_marker_data[1]")
	carta_update_marker[0].update_marker = update_marker[0];
	-- We're not using EPDC_FLAG_TEST_COLLISION, assume 0 is okay.
	carta_update_marker[0].collision_test = 0;
	return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_COMPLETE, carta_update_marker)
end

-- Kindle's MXCFB_SEND_UPDATE == 0x4048462e | Kobo's MXCFB_SEND_UPDATE == 0x4044462e
local function mxc_update(fb, refarea, refreshtype, waveform_mode, x, y, w, h)
	refarea[0].update_mode = refreshtype or ffi.C.UPDATE_MODE_PARTIAL
	refarea[0].waveform_mode = waveform_mode or 0x2
	refarea[0].update_region.left = x or 0
	refarea[0].update_region.top = y or 0
	refarea[0].update_region.width = w or fb.vinfo.xres
	refarea[0].update_region.height = h or fb.vinfo.yres
	-- Get a new update marker
	refarea[0].update_marker = mxc_new_update_marker()
	-- NOTE: We're not using EPDC_FLAG_USE_ALT_BUFFER
	refarea[0].alt_buffer_data.phys_addr = 0
	refarea[0].alt_buffer_data.width = 0
	refarea[0].alt_buffer_data.height = 0
	refarea[0].alt_buffer_data.alt_update_region.top = 0
	refarea[0].alt_buffer_data.alt_update_region.left = 0
	refarea[0].alt_buffer_data.alt_update_region.width = 0
	refarea[0].alt_buffer_data.alt_update_region.height = 0
	ffi.C.ioctl(fb.fd, ffi.C.MXCFB_SEND_UPDATE, refarea)
end

-- Kindle's MXCFB_WAIT_FOR_UPDATE_SUBMISSION == 0x40044637
local function kindle_mxc_wait_for_update_submission(fb)
	-- Wait for the current (the one we just sent) update to be submitted
	return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_SUBMISSION, update_marker)
end

local function k51_update(fb, refreshtype, waveform_mode, x, y, w, h)
	local refarea = ffi.new("struct mxcfb_update_data[1]")
	-- only for Amazon's driver, try to mostly follow what the stock reader does...
	if waveform_mode == ffi.C.WAVEFORM_MODE_REAGL then
		-- If we're requesting WAVEFORM_MODE_REAGL, it's regal all around!
		refarea[0].hist_bw_waveform_mode = waveform_mode
	else
		refarea[0].hist_bw_waveform_mode = ffi.C.WAVEFORM_MODE_DU
	end
	-- Same as our requested waveform_mode
	refarea[0].hist_gray_waveform_mode = waveform_mode
	-- TEMP_USE_PAPYRUS on Touch/PW1, TEMP_USE_AUTO on PW2 (same value in both cases, 0x1001)
	refarea[0].temp = ffi.C.TEMP_USE_AUTO
	-- NOTE: We never use any flags on Kindle.
	-- TODO: EPDC_FLAG_ENABLE_INVERSION & EPDC_FLAG_FORCE_MONOCHROME might be of use, though...
	refarea[0].flags = 0

	return mxc_update(fb, refarea, refreshtype, waveform_mode, x, y, w, h)
end

local function kobo_update(fb, refreshtype, waveform_mode, x, y, w, h)
	local refarea = ffi.new("struct mxcfb_update_data[1]")
	-- only for Kobo's driver:
	refarea[0].alt_buffer_data.virt_addr = nil
	-- TEMP_USE_AMBIENT
	refarea[0].temp = 0x1000
	-- Enable the appropriate flag when requesting a regal waveform (Kobo)
	if waveform_mode == ffi.C.WAVEFORM_MODE_KOBO_REGAL then
		refarea[0].flags = ffi.C.EPDC_FLAG_USE_AAD
	else
		refarea[0].flags = 0
	end

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
			if fb.vinfo.xres > fb.vinfo.yres then
				-- Kobo framebuffers need to be rotated counter-clockwise (they start in landscape mode)
				fb.bb:rotate(-90)
			end
			-- NOTE: I'm assuming this won't blow up on older Kobo devices...
			fb.einkWaitForCompleteFunc = kobo_mxc_wait_for_update_complete
		elseif fb.vinfo.bits_per_pixel == 8 then
			-- Kindle PaperWhite and KT with 5.1 or later firmware
			local dummy = require("ffi/mxcfb_kindle_h")
			-- NOTE: We need to differentiate the REAGL-aware devices from the rest... I hope this check is solid enough... (cf #550).
			-- FIXME: The KT2 needs to go here!
			-- I'm not sure it'll actually handle REAGL (although the kernel seems to indicate it does), since it's not using a Carta screen, but it is still a Wario device ;).
			if fb.finfo.smem_len == 3145728 or fb.finfo.smem_len == 6782976 then
				-- We're a PW2/KT2/KV! Use the correct function.
				fb.einkWaitForCompleteFunc = kindle_carta_mxc_wait_for_update_complete
			elseif fb.finfo.smem_len == 2179072 or fb.finfo.smem_len == 4718592 then
				-- We're a Touch/PW1
				fb.einkWaitForCompleteFunc = kindle_pearl_mxc_wait_for_update_complete
			else
				error("unknown smem_len value for the Kindle mxc eink driver")
			end
			fb.einkUpdateFunc = k51_update
			fb.einkWaitForSubmissionFunc = kindle_mxc_wait_for_update_submission
			fb.bb = BB.new(fb.vinfo.xres, fb.vinfo.yres, BB.TYPE_BB8, fb.data, fb.finfo.line_length)
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
        -- classic eink framebuffer driver has grayscale values inverted (i.e. 0xF = black, 0 = white)
        fb.bb:invert()
	else
		error("eink model not supported");
	end

    fb.bb:fill(BB.COLOR_WHITE)
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

function framebuffer_mt.__index:refresh(refreshtype, waveform_mode, wait_for_marker, x, y, w, h)
	-- Always wait for the previous update when queuing a FULL update. Mostly matters for REAGL updates, which are always FULL anyway :).
	if refreshtype == ffi.C.UPDATE_MODE_FULL then
		-- Start by checking that our previous update has completed
		if self.einkWaitForCompleteFunc then
			-- We have nothing to check on our first refresh() call!
			if update_marker[0] ~= 0 then
				self:einkWaitForCompleteFunc()
			end
		end
	end

	w, x = BB.checkBounds(w or self.bb:getWidth(), x or 0, 0, self.bb:getWidth(), 0xFFFF)
	h, y = BB.checkBounds(h or self.bb:getHeight(), y or 0, 0, self.bb:getHeight(), 0xFFFF)
	x, y, w, h = self.bb:getPhysicalRect(x, y, w, h)
	self:einkUpdateFunc(refreshtype, waveform_mode, x, y, w, h)

	-- If needed, finish by waiting for our current update to be submitted
	-- NOTE: Getting rid of wait_for_marker by testing for UPDATE_MODE_FULL instead doesn't gain us much speed, so keep doing it the safe way ;).
	-- In the specific case of the vritual keyboard, it would probably need more than this to make it blazing fast: besides not waiting for any marker,
	-- the stock reader handles that issue by partly using WAVEFORM_MODE_DU & EPDC_FLAG_FORCE_MONOCHROME for very fast refreshes.
	if wait_for_marker then
		if self.einkWaitForSubmissionFunc then
			self:einkWaitForSubmissionFunc()
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
