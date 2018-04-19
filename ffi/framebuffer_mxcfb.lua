local ffi = require("ffi")
local BB = require("ffi/blitbuffer")
local util = require("ffi/util")

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

    -- we will use this to keep book on the refreshes we
    -- triggered and care to wait for:
    refresh_list = nil,
    -- for now we use up to 10 markers in order to
    -- leave a bit of room for non-tagged updates
    max_marker = 10,
}

--[[ refresh list management: --]]

--[[
helper function: checks if two rectangles overlap
--]]
local function overlaps(rect_a, rect_b)
    -- TODO: use geometry.lua from main koreader repo
    if (rect_a.x >= (rect_b.x + rect_b.w))
    or (rect_a.y >= (rect_b.y + rect_b.h))
    or (rect_b.x >= (rect_a.x + rect_a.w))
    or (rect_b.y >= (rect_a.y + rect_a.h)) then
        return false
    end
    return true
end

--[[
This just waits for a given marker, identified by the place in our
tracking list - which is also the marker number we issue.
--]]
function framebuffer:_wait_marker(index)
    if self.mech_wait_update_complete then
        self.debug("waiting for completion of update", index)
        local duration = self:mech_wait_update_complete(index)
        self.debug("duration:", duration)
    end
    self.refresh_list[index] = nil
end

--[[
check if we have requests to be waited for that cover regions that overlap
the rectangle we are asking for:
--]]
function framebuffer:_wait_for_conflicting(rect)
    for i = 1, self.max_marker do
        if self.refresh_list[i] and overlaps(self.refresh_list[i].rect, rect) then
            self.debug("update area conflicts with active update", i)
            self:_wait_marker(i)
        end
    end
end

--[[
does a scan through our tracking list and waits for the oldest refresh we're still
tracking, waiting for it and then returning its (then available) number
--]]
function framebuffer:_wait_for_next()
    local oldest
    for i = 1, self.max_marker do
        if self.refresh_list[i] then
            if not oldest or self.refresh_list[i].time < self.refresh_list[oldest].time then
                oldest = i
            end
        end
    end
    if oldest then
        self.debug("waiting for a free marker, oldest update is", oldest)
        self:_wait_marker(oldest)
        return oldest
    end
    error("instructed to wait for a marker, but there are none to be waited for")
end

--[[
scans our tracking list for available markers
--]]
function framebuffer:_find_free_marker()
    for i = 1, self.max_marker do
        if self.refresh_list[i] == nil then
            return i
        end
    end
end

--[[
registers a refresh in our tracking list and returns a valid
marker number for the kernel call
--]]
function framebuffer:_get_marker(rect, refreshtype, waveform_mode)
    local marker = self:_find_free_marker() or self:_wait_for_next()
    local time_s, time_us = util.gettime()
    local refresh = {
        rect = rect,
        refreshtype = refreshtype,
        waveform_mode = waveform_mode,
        time = time_s * 1000 + time_us / 1000,
    }
    self.debug("assigned marker", marker, "to update:", refresh)
    self.refresh_list[marker] = refresh
    return marker
end

--[[ handlers for the wait API of the eink driver --]]

-- Kindle's MXCFB_WAIT_FOR_UPDATE_COMPLETE_PEARL == 0x4004462f
local function kindle_pearl_mxc_wait_for_update_complete(fb, marker)
    -- Wait for the previous update to be completed
    return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_COMPLETE_PEARL, ffi.new("uint32_t[1]", marker))
end

-- Kobo's MXCFB_WAIT_FOR_UPDATE_COMPLETE == 0x4004462f
local function kobo_mxc_wait_for_update_complete(fb, marker)
    -- Wait for the previous update to be completed
    return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_COMPLETE, ffi.new("uint32_t[1]", marker))
end

-- Kindle's MXCFB_WAIT_FOR_UPDATE_COMPLETE == 0x4004462f
local function pocketbook_mxc_wait_for_update_complete(fb, marker)
    -- Wait for the previous update to be completed
    return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_COMPLETE, ffi.new("uint32_t[1]", marker))
end

-- Kindle's MXCFB_WAIT_FOR_UPDATE_COMPLETE == 0xc008462f
local function kindle_carta_mxc_wait_for_update_complete(fb, marker)
    -- Wait for the previous update to be completed
    local carta_update_marker = ffi.new("struct mxcfb_update_marker_data[1]")
    carta_update_marker[0].update_marker = marker
    -- We're not using EPDC_FLAG_TEST_COLLISION, assume 0 is okay.
    carta_update_marker[0].collision_test = 0
    return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_COMPLETE, carta_update_marker)
end

-- Kindle's MXCFB_WAIT_FOR_UPDATE_SUBMISSION == 0x40044637
local function kindle_mxc_wait_for_update_submission(fb, marker)
    -- Wait for the current (the one we just sent) update to be submitted
    return ffi.C.ioctl(fb.fd, ffi.C.MXCFB_WAIT_FOR_UPDATE_SUBMISSION, ffi.new("uint32_t[1]", marker))
end


--[[ refresh functions ]]--

-- Kindle's MXCFB_SEND_UPDATE == 0x4048462e
-- Kobo's MXCFB_SEND_UPDATE == 0x4044462e
-- Pocketbook's MXCFB_SEND_UPDATE == 0x4040462e
local function mxc_update(fb, refarea, refreshtype, waveform_mode, wait, x, y, w, h)
    local bb = fb.full_bb or fb.bb
    w, x = BB.checkBounds(w or bb:getWidth(), x or 0, 0, bb:getWidth(), 0xFFFF)
    h, y = BB.checkBounds(h or bb:getHeight(), y or 0, 0, bb:getHeight(), 0xFFFF)
    x, y, w, h = bb:getPhysicalRect(x, y, w, h)

    if w == 0 or h == 0 then
        fb.debug("got a 0 size (height and/or width) refresh request, ignoring it.")
        return
    end

    if w == 1 and h == 1 then
        -- avoid system freeze when updating 1x1 pixel block on KPW2 and KV,
        -- see koreader/koreader#1299 and koreader/koreader#1486
        fb.debug("got a 1x1 pixel refresh request, ignoring it.")
        return
    end

    local rect = { x=x, y=y, w=w, h=h }
    -- always wait for conflicts:
    fb:_wait_for_conflicting(rect)

	refarea[0].update_mode = refreshtype or ffi.C.UPDATE_MODE_PARTIAL
	refarea[0].waveform_mode = waveform_mode or ffi.C.WAVEFORM_MODE_GC16
	refarea[0].update_region.left = x
	refarea[0].update_region.top = y
	refarea[0].update_region.width = w
	refarea[0].update_region.height = h
	-- send a tracked update marker when wait==true, or 42 otherwise
    local submit_marker
    if wait then
        submit_marker = fb:_get_marker(rect, refreshtype, waveform_mode)
    else
        -- NOTE: 0 is an invalid marker id! Use something randomly fun instead, but > self.max_marker to avoid wreaking havoc.
        submit_marker = 42
    end
    refarea[0].update_marker = submit_marker
	-- NOTE: We're not using EPDC_FLAG_USE_ALT_BUFFER
	refarea[0].alt_buffer_data.phys_addr = 0
	refarea[0].alt_buffer_data.width = 0
	refarea[0].alt_buffer_data.height = 0
	refarea[0].alt_buffer_data.alt_update_region.top = 0
	refarea[0].alt_buffer_data.alt_update_region.left = 0
	refarea[0].alt_buffer_data.alt_update_region.width = 0
	refarea[0].alt_buffer_data.alt_update_region.height = 0

	ffi.C.ioctl(fb.fd, ffi.C.MXCFB_SEND_UPDATE, refarea)

    if submit_marker and fb.mech_wait_update_submission then
        fb.debug("refresh: wait for submission")
        fb.mech_wait_update_submission(fb, submit_marker)
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

local function refresh_pocketbook(fb, refreshtype, waveform_mode, wait, x, y, w, h)
	local refarea = ffi.new("struct mxcfb_update_data[1]")
	-- TEMP_USE_AMBIENT
	refarea[0].temp = 0x1000

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

    self.refresh_list = {}

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
            self.wait_for_marker_ui = false
        elseif self.device.model == "KindleBasic" then
            self.mech_wait_update_complete = kindle_carta_mxc_wait_for_update_complete
            self.waveform_partial = ffi.C.WAVEFORM_MODE_REAGL
            self.update_mode_partial = ffi.C.UPDATE_MODE_FULL -- REAGL get upgraded to full
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = true
            self.wait_for_marker_fast = true
            self.wait_for_marker_ui = false
        elseif self.device.model == "KindleVoyage" then
            self.mech_wait_update_complete = kindle_carta_mxc_wait_for_update_complete
            self.waveform_partial = ffi.C.WAVEFORM_MODE_REAGL
            self.update_mode_partial = ffi.C.UPDATE_MODE_FULL -- REAGL get upgraded to full
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = true
            self.wait_for_marker_fast = true
            self.wait_for_marker_ui = false
        elseif self.device.model == "KindlePaperWhite3" then
            self.mech_wait_update_complete = kindle_carta_mxc_wait_for_update_complete
            self.waveform_partial = ffi.C.WAVEFORM_MODE_REAGL
            self.update_mode_partial = ffi.C.UPDATE_MODE_FULL -- REAGL get upgraded to full
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = true
            self.wait_for_marker_fast = true
            self.wait_for_marker_ui = false
        elseif self.device.model == "KindleOasis" then
            self.mech_wait_update_complete = kindle_carta_mxc_wait_for_update_complete
            self.waveform_partial = ffi.C.WAVEFORM_MODE_REAGL
            self.update_mode_partial = ffi.C.UPDATE_MODE_FULL -- REAGL get upgraded to full
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = true
            self.wait_for_marker_fast = true
            self.wait_for_marker_ui = false
        elseif self.device.model == "KindleBasic2" then
            self.mech_wait_update_complete = kindle_carta_mxc_wait_for_update_complete
            self.waveform_partial = ffi.C.WAVEFORM_MODE_REAGL
            self.update_mode_partial = ffi.C.UPDATE_MODE_FULL -- REAGL get upgraded to full
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = true
            self.wait_for_marker_fast = true
            self.wait_for_marker_ui = false
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
            self.wait_for_marker_partial = false
            self.wait_for_marker_fast = false
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
        elseif self.device.model == "Kobo_alyssum" then
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = false
            self.wait_for_marker_fast = false
        elseif self.device.model == "Kobo_pika" then
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = false
            self.wait_for_marker_fast = false
        -- FIXME: Aura SE, did it inherit its ancestor's semi-REAGL support?
        elseif self.device.model == "Kobo_star" then
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = false
            self.wait_for_marker_fast = false
        -- FIXME: Same conundrum for the Aura One...
        elseif self.device.model == "Kobo_daylight" then
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = false
            self.wait_for_marker_fast = false
        -- FIXME: And what of the H2O²?
        elseif self.device.model == "Kobo_snow" then
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = false
            self.wait_for_marker_fast = false
        end
    elseif self.device:isPocketBook() then
        require("ffi/mxcfb_pocketbook_h")

        self.mech_refresh = refresh_pocketbook
        self.mech_wait_update_complete = pocketbook_mxc_wait_for_update_complete

        self.update_mode_partial = ffi.C.UPDATE_MODE_PARTIAL
        self.update_mode_full = ffi.C.UPDATE_MODE_FULL
        self.update_mode_fast = ffi.C.UPDATE_MODE_PARTIAL
        self.update_mode_ui = ffi.C.UPDATE_MODE_PARTIAL

        self.waveform_fast = ffi.C.WAVEFORM_MODE_A2
        self.waveform_ui = ffi.C.WAVEFORM_MODE_GC16
        self.waveform_full = ffi.C.WAVEFORM_MODE_GC16

        if self.device.model == "PocketBook" then
            self.waveform_partial = ffi.C.WAVEFORM_MODE_GC16
            self.wait_for_marker_full = true
            self.wait_for_marker_partial = false
            self.wait_for_marker_fast = false
            self.wait_for_marker_ui = false
        end
    else
        error("unknown device type")
    end
end

return require("ffi/framebuffer_linux"):extend(framebuffer)
