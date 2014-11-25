local ffi = require("ffi")
local BB = require("ffi/blitbuffer")

local dummy = require("ffi/posix_h")

local framebuffer = {
-- pass device object here for proper model detection:
    device = nil,

    mech_wait_update_complete = nil,
    mech_wait_update_submission = nil,
    wait_for_marker_partial = false,
    wait_for_marker_ui = false,
    wait_for_marker_full = true,
    wait_for_marker_fast = false,
    waveform_partial = nil,
    waveform_ui = nil,
    waveform_full = nil,
    waveform_fast = nil,
    update_mode_partial = nil,
    update_mode_ui = nil,
    update_mode_full = nil,
    update_mode_fast = nil,
    mech_refresh = nil,

    calc_update_marker = 0,
    wait_update_marker = ffi.new("uint32_t[1]"),

    marker_waiting = nil,
}

--[[ handlers for the wait API of the eink driver --]]

-- Kindle's MXCFB_WAIT_FOR_UPDATE_COMPLETE_PEARL == 0x4004462f
local function kindle_pearl_mxc_wait_for_update_complete(fb, marker)
    -- Wait for the previous update to be completed
    return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_COMPLETE_PEARL, marker)
end

-- Kobo's MXCFB_WAIT_FOR_UPDATE_COMPLETE == 0x4004462f
local function kobo_mxc_wait_for_update_complete(fb, marker)
    -- Wait for the previous update to be completed
    return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_COMPLETE, marker)
end

-- Kindle's MXCFB_WAIT_FOR_UPDATE_COMPLETE == 0xc008462f
local function kindle_carta_mxc_wait_for_update_complete(fb, marker)
    -- Wait for the previous update to be completed
    local carta_update_marker = ffi.new("struct mxcfb_update_marker_data[1]")
    carta_update_marker[0].update_marker = marker[0]
    -- We're not using EPDC_FLAG_TEST_COLLISION, assume 0 is okay.
    carta_update_marker[0].collision_test = 0
    return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_COMPLETE, carta_update_marker)
end

-- Kindle's MXCFB_WAIT_FOR_UPDATE_SUBMISSION == 0x40044637
local function kindle_mxc_wait_for_update_submission(fb, marker)
    -- Wait for the current (the one we just sent) update to be submitted
    return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_SUBMISSION, marker)
end


--[[ refresh functions ]]--

-- Kindle's MXCFB_SEND_UPDATE == 0x4048462e | Kobo's MXCFB_SEND_UPDATE == 0x4044462e
local function mxc_update(fb, refarea, refreshtype, waveform_mode, wait, x, y, w, h)
    -- if we have a lingering update marker that we should wait for, we do so now:
    if fb.mech_wait_update_complete and fb.wait_update_marker[0] ~= 0 then
        fb.debug("refresh: wait for update", fb.wait_update_marker[0])
        fb.mech_wait_update_complete(fb, fb.wait_update_marker)
        fb.wait_update_marker[0] = 0
    end
    -- if we should wait (later) for the update we're doing now, we need to register a new
    -- update marker:
    if wait then
        fb.calc_update_marker = (fb.calc_update_marker % 16 ) + 1
        fb.wait_update_marker[0] = fb.calc_update_marker
        fb.debug("refresh: next update has marker", fb.wait_update_marker[0])
    end

	w, x = BB.checkBounds(w or fb.bb:getWidth(), x or 0, 0, fb.bb:getWidth(), 0xFFFF)
	h, y = BB.checkBounds(h or fb.bb:getHeight(), y or 0, 0, fb.bb:getHeight(), 0xFFFF)
	x, y, w, h = fb.bb:getPhysicalRect(x, y, w, h)

	refarea[0].update_mode = refreshtype or ffi.C.UPDATE_MODE_PARTIAL
	refarea[0].waveform_mode = waveform_mode or ffi.C.WAVEFORM_MODE_GC16
	refarea[0].update_region.left = x
	refarea[0].update_region.top = y
	refarea[0].update_region.width = w
	refarea[0].update_region.height = h
	-- Update marker - either set above (when wait==true), or 0
	refarea[0].update_marker = fb.wait_update_marker[0]
	-- NOTE: We're not using EPDC_FLAG_USE_ALT_BUFFER
	refarea[0].alt_buffer_data.phys_addr = 0
	refarea[0].alt_buffer_data.width = 0
	refarea[0].alt_buffer_data.height = 0
	refarea[0].alt_buffer_data.alt_update_region.top = 0
	refarea[0].alt_buffer_data.alt_update_region.left = 0
	refarea[0].alt_buffer_data.alt_update_region.width = 0
	refarea[0].alt_buffer_data.alt_update_region.height = 0
	ffi.C.ioctl(fb.fd, ffi.C.MXCFB_SEND_UPDATE, refarea)

    if fb.mech_wait_update_submission and wait then
        fb.debug("refresh: wait for submission")
        fb.mech_wait_update_submission(fb, fb.wait_update_marker)
    end
end

local function refresh_k51(fb, refreshtype, waveform_mode, wait, x, y, w, h)
	local refarea = ffi.new("struct mxcfb_update_data[1]")
	-- only for Amazon's driver, try to mostly follow what the stock reader does...
	if waveform_mode == ffi.C.WAVEFORM_MODE_REAGL then
		-- If we're requesting WAVEFORM_MODE_REAGL, it's REAGL all around!
		refarea[0].hist_bw_waveform_mode = waveform_mode
	else
		refarea[0].hist_bw_waveform_mode = ffi.C.WAVEFORM_MODE_DU
	end
	-- Same as our requested waveform_mode
	refarea[0].hist_gray_waveform_mode = waveform_mode or ffi.C.WAVEFORM_MODE_GC16
	-- TEMP_USE_PAPYRUS on Touch/PW1, TEMP_USE_AUTO on PW2 (same value in both cases, 0x1001)
	refarea[0].temp = ffi.C.TEMP_USE_AUTO
	-- NOTE: We never use any flags on Kindle.
	-- TODO: EPDC_FLAG_ENABLE_INVERSION & EPDC_FLAG_FORCE_MONOCHROME might be of use, though...
	refarea[0].flags = 0

	return mxc_update(fb, refarea, refreshtype, waveform_mode, wait, x, y, w, h)
end

local function refresh_kobo(fb, refreshtype, waveform_mode, wait, x, y, w, h)
	local refarea = ffi.new("struct mxcfb_update_data[1]")
	-- only for Kobo's driver:
	refarea[0].alt_buffer_data.virt_addr = nil
	-- TEMP_USE_AMBIENT
	refarea[0].temp = 0x1000
	-- Enable the appropriate flag when requesting a REAGLD waveform (NTX_WFM_MODE_GLD16)
	if waveform_mode == ffi.C.WAVEFORM_MODE_REAGLD then
		refarea[0].flags = ffi.C.EPDC_FLAG_USE_AAD
	else
		refarea[0].flags = 0
	end

	return mxc_update(fb, refarea, refreshtype, waveform_mode, wait, x, y, w, h)
end

--[[ framebuffer API ]]--

function framebuffer:refreshPartialImp(x, y, w, h)
    self.debug("refresh: partial", x, y, w, h)
    self:mech_refresh(self.update_mode_partial, self.waveform_partial, self.wait_for_marker_partial, x, y, w, h)
end

function framebuffer:refreshUIImp(x, y, w, h)
    self.debug("refresh: ui-mode", x, y, w, h)
    self:mech_refresh(self.update_mode_ui, self.waveform_ui, self.wait_for_marker_ui, x, y, w, h)
end

function framebuffer:refreshFullImp(x, y, w, h)
    self.debug("refresh: full", x, y, w, h)
    self:mech_refresh(self.update_mode_full, self.waveform_full, self.wait_for_marker_full, x, y, w, h)
end

function framebuffer:refreshFastImp(x, y, w, h)
    self.debug("refresh: fast", x, y, w, h)
    self:mech_refresh(self.update_mode_fast, self.waveform_fast, self.wait_for_marker_fast, x, y, w, h)
end

function framebuffer:init()
    framebuffer.parent.init(self)

    if self.device:isKindle() then
        require("ffi/mxcfb_kindle_h")

        self.mech_refresh = refresh_k51
        self.mech_wait_update_complete = kindle_pearl_mxc_wait_for_update_complete
        self.mech_wait_update_submission = kindle_mxc_wait_for_update_submission

        self.update_mode_partial = ffi.C.UPDATE_MODE_PARTIAL
        self.update_mode_full = ffi.C.UPDATE_MODE_FULL
        self.update_mode_fast = ffi.C.UPDATE_MODE_PARTIAL
        self.update_mode_ui = ffi.C.UPDATE_MODE_PARTIAL

        self.waveform_fast = ffi.C.WAVEFORM_MODE_A2
        self.waveform_ui = ffi.C.WAVEFORM_MODE_GC16_FAST
        self.waveform_full = ffi.C.WAVEFORM_MODE_GC16

        if self.device.model == "KindleTouch" then
            self.waveform_partial = ffi.C.WAVEFORM_MODE_GL16_FAST
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = false
            self.wait_for_marker_fast = false
            self.wait_for_marker_ui = false
        elseif self.device.model == "KindlePaperWhite" then
            self.waveform_partial = ffi.C.WAVEFORM_MODE_GL16_FAST
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = false
            self.wait_for_marker_fast = false
            self.wait_for_marker_ui = false
        elseif self.device.model == "KindlePaperWhite2" then
            self.mech_wait_update_complete = kindle_carta_mxc_wait_for_update_complete
            self.waveform_partial = ffi.C.WAVEFORM_MODE_REAGL
            self.update_mode_partial = ffi.C.UPDATE_MODE_FULL -- REAGL get upgraded to full
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = true
            self.wait_for_marker_fast = true
            self.wait_for_marker_ui = true
        elseif self.device.model == "KindleBasic" then
            self.mech_wait_update_complete = kindle_carta_mxc_wait_for_update_complete
            self.waveform_partial = ffi.C.WAVEFORM_MODE_REAGL
            self.update_mode_partial = ffi.C.UPDATE_MODE_FULL -- REAGL get upgraded to full
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = true
            self.wait_for_marker_fast = true
            self.wait_for_marker_ui = true
        elseif self.device.model == "KindleVoyage" then
            self.mech_wait_update_complete = kindle_carta_mxc_wait_for_update_complete
            self.waveform_partial = ffi.C.WAVEFORM_MODE_REAGL
            self.update_mode_partial = ffi.C.UPDATE_MODE_FULL -- REAGL get upgraded to full
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = true
            self.wait_for_marker_fast = true
            self.wait_for_marker_ui = true
        end
    elseif self.device:isKobo() then
        require("ffi/mxcfb_kobo_h")

        self.mech_refresh = refresh_kobo
        self.mech_wait_update_complete = kobo_mxc_wait_for_update_complete

        self.update_mode_partial = ffi.C.UPDATE_MODE_PARTIAL
        self.update_mode_full = ffi.C.UPDATE_MODE_FULL
        self.update_mode_fast = ffi.C.UPDATE_MODE_PARTIAL
        self.update_mode_ui = ffi.C.UPDATE_MODE_PARTIAL

        self.waveform_fast = ffi.C.WAVEFORM_MODE_A2
        self.waveform_ui = ffi.C.WAVEFORM_MODE_AUTO
        self.waveform_full = ffi.C.NTX_WFM_MODE_GC16
        self.waveform_partial = ffi.C.WAVEFORM_MODE_AUTO

        self.wait_for_marker_ui = false

        if self.device.model == "Kobo_phoenix" then
            self.waveform_partial = ffi.C.NTX_WFM_MODE_GLD16
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = true
            self.wait_for_marker_fast = true
        elseif self.device.model == "Kobo_dahlia" then
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = true
            self.wait_for_marker_fast = true
        elseif self.device.model == "Kobo_pixie" then
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = false
            self.wait_for_marker_fast = false
        elseif self.device.model == "Kobo_trilogy" then
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = false
            self.wait_for_marker_fast = false
        elseif self.device.model == "Kobo_dragon" then
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = false
            self.wait_for_marker_fast = false
        elseif self.device.model == "Kobo_kraken" then
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = false
            self.wait_for_marker_fast = false
        end

        -- some Kobo framebuffers need to be rotated counter-clockwise (they start in landscape mode)
        if self.bb:getWidth() > self.bb:getHeight() then
            self.bb:rotate(-90)
            self.blitbuffer_rotation_mode = self.bb:getRotation()
            self.native_rotation_mode = self.ORIENTATION_PORTRAIT
            self.cur_rotation_mode = self.native_rotation_mode
        end
    else
        error("unknown device type")
    end
end

return require("ffi/framebuffer_linux"):extend(framebuffer)
