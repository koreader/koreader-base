local ffi = require("ffi")
local BB = require("ffi/blitbuffer")

local dummy = require("ffi/posix_h")

-- Valid marker bounds
local MARKER_MIN = 42
local MARKER_MAX = (42 * 42)

local framebuffer = {
    -- pass device object here for proper model detection:
    device = nil,

    mech_wait_update_complete = nil,
    mech_wait_update_submission = nil,
    waveform_partial = nil,
    waveform_ui = nil,
    waveform_full = nil,
    waveform_fast = nil,
    mech_refresh = nil,
    -- start with an out-of bound marker value to avoid doing something stupid on our first update
    marker = MARKER_MIN - 1,
}

--[[ refresh list management: --]]

-- Returns an incrementing marker value, w/ a sane wraparound.
function framebuffer:_get_next_marker()
    local marker = self.marker + 1
    if marker > MARKER_MAX then
        marker = MARKER_MIN
    end

    self.marker = marker
    return marker
end

-- Returns current marker value.
function framebuffer:_get_marker()
    local marker = self.marker
    return marker
end

-- Returns true if waveform_mode arg matches the UI waveform mode for current device
-- NOTE: This is to avoid explicit comparison against device-specific waveform constants in mxc_update()
--       Here, it's because of the Kindle-specific WAVEFORM_MODE_GC16_FAST
function framebuffer:_isUIWaveFormMode(waveform_mode)
    return waveform_mode == self.waveform_ui
end

-- Returns true if waveform_mode arg matches the REAGL waveform mode for current device
-- NOTE: This is to avoid explicit comparison against device-specific waveform constants in mxc_update()
--       Here, it's Kindle's WAVEFORM_MODE_REAGL vs. Kobo's NTX_WFM_MODE_GLD16
function framebuffer:_isREAGLWaveFormMode(waveform_mode)
    local ret = false

    if self.device:isKindle() then
        ret = waveform_mode == ffi.C.WAVEFORM_MODE_REAGL
    elseif self.device:isKobo() then
        ret = waveform_mode == ffi.C.NTX_WFM_MODE_GLD16
    end

    return ret
end

-- Returns true if w & h are equal or larger than our visible screen estate (i.e., we asked for a full-screen update)
function framebuffer:_isFullScreen(fb, w, h)
    -- NOTE: fb:getWidth() & fb:getHeight() return the viewport size, but obey rotation, which means we can't rely on it directly.
    --       fb:getScreenWidth() & fb:getScreenHeight return the full screen size, without the viewport, and in the default rotatoin, which doesn't help either.
    -- Settle for getWidth() & getHeight() w/ rotation handling, like what bb:getPhysicalRect() does...
    if fb:getRotationMode() % 2 == 1 then w, h = h, w end

    if w >= fb:getWidth() and h >= fb:getHeight() then
        return true
    else
        return false
    end
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
local function kindle_carta_mxc_wait_for_update_complete(fb, marker, collision_test)
    -- Wait for the previous update to be completed
    local carta_update_marker = ffi.new("struct mxcfb_update_marker_data[1]")
    carta_update_marker[0].update_marker = marker
    -- NOTE: Assume a fallback of 0 is okay.
    --       On a slightly related note, the EPDC_FLAG_TEST_COLLISION flag is for dry-run collision tests, never set it.
    carta_update_marker[0].collision_test = collision_test or 0
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
local function mxc_update(fb, refarea, refresh_type, waveform_mode, x, y, w, h)
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

    -- NOTE: If we're trying to send a:
    --         * true FULL update,
    --         * GC16_FAST update (i.e., popping-up a menu),
    --       then wait for submission of previous marker first.
    local marker = fb:_get_marker()
    -- Make sure it's a valid marker, to avoid doing something stupid on our first update.
    if (refresh_type == ffi.C.UPDATE_MODE_FULL
      or fb:_isUIWaveFormMode(waveform_mode))
      and fb.mech_wait_update_submission
      and (marker >= MARKER_MIN and marker <= MARKER_MAX) then
        fb.debug("refresh: wait for submission of (previous) marker", marker)
        fb.mech_wait_update_submission(fb, marker)
    end

    -- NOTE: If we're trying to send a:
    --         * REAGL update,
    --         * GC16 update,
    --         * Full-screen, flashing GC16_FAST update,
    --       then wait for completion of previous marker first.
    local collision_test = 0
    -- Again, make sure the marker is valid, too.
    if (fb:_isREAGLWaveFormMode(waveform_mode)
      or waveform_mode == ffi.C.WAVEFORM_MODE_GC16
      or (refresh_type == ffi.C.UPDATE_MODE_FULL and fb:_isUIWaveFormMode(waveform_mode) and fb:_isFullScreen(fb, w, h)))
      and fb.mech_wait_update_complete
      and (marker >= MARKER_MIN and marker <= MARKER_MAX) then
        -- NOTE: Setup the slightly mysterious collision_test flag...
        if fb:_isREAGLWaveFormMode(waveform_mode) then
            collision_test = 0
        elseif waveform_mode == ffi.C.WAVEFORM_MODE_GC16 or fb:_isUIWaveFormMode(waveform_mode) then
            collision_test = 1642888
        end
        fb.debug("refresh: wait for completion of (previous) marker", marker, "with collision_test", collision_test)
        fb.mech_wait_update_complete(fb, marker, collision_test)
    end

    refarea[0].update_mode = refresh_type or ffi.C.UPDATE_MODE_PARTIAL
    refarea[0].waveform_mode = waveform_mode or ffi.C.WAVEFORM_MODE_GC16
    refarea[0].update_region.left = x
    refarea[0].update_region.top = y
    refarea[0].update_region.width = w
    refarea[0].update_region.height = h
    marker = fb:_get_next_marker()
    refarea[0].update_marker = marker
    -- NOTE: We're not using EPDC_FLAG_USE_ALT_BUFFER
    refarea[0].alt_buffer_data.phys_addr = 0
    refarea[0].alt_buffer_data.width = 0
    refarea[0].alt_buffer_data.height = 0
    refarea[0].alt_buffer_data.alt_update_region.top = 0
    refarea[0].alt_buffer_data.alt_update_region.left = 0
    refarea[0].alt_buffer_data.alt_update_region.width = 0
    refarea[0].alt_buffer_data.alt_update_region.height = 0

    -- Handle REAGL promotion...
    -- NOTE: We need to do this here, because we rely on the pre-promotion actual refresh_type in previous heuristics.
    if fb:_isREAGLWaveFormMode(waveform_mode) then
        -- NOTE: REAGL updates always need to be full.
        refarea[0].update_mode = ffi.C.UPDATE_MODE_FULL
    end

    ffi.C.ioctl(fb.fd, ffi.C.MXCFB_SEND_UPDATE, refarea)

    -- NOTE: We wait for completion after *any kind* of full update.
    if refarea[0].update_mode == ffi.C.UPDATE_MODE_FULL
      and fb.mech_wait_update_complete then
        -- NOTE: Again, setup collision_test magic numbers...
        if fb:_isREAGLWaveFormMode(waveform_mode) then
            collision_test = 4
        elseif waveform_mode == ffi.C.WAVEFORM_MODE_GC16 or fb:_isUIWaveFormMode(waveform_mode) then
            collision_test = 1
        end
        fb.debug("refresh: wait for completion of marker", marker, "with collision_test", collision_test)
        fb.mech_wait_update_complete(fb, marker, collision_test)
    end
end

local function refresh_k51(fb, refreshtype, waveform_mode, x, y, w, h)
    local refarea = ffi.new("struct mxcfb_update_data[1]")
    -- only for Amazon's driver, try to mostly follow what the stock reader does...
    if waveform_mode == ffi.C.WAVEFORM_MODE_REAGL then
        -- If we're requesting WAVEFORM_MODE_REAGL, it's REAGL all around!
        refarea[0].hist_bw_waveform_mode = waveform_mode
        refarea[0].hist_gray_waveform_mode = waveform_mode
    else
        refarea[0].hist_bw_waveform_mode = ffi.C.WAVEFORM_MODE_DU
        refarea[0].hist_gray_waveform_mode = ffi.C.WAVEFORM_MODE_GC16_FAST
    end
    -- And we're only left with true full updates to special-case.
    if waveform_mode == ffi.C.WAVEFORM_MODE_GC16 then
        refarea[0].hist_gray_waveform_mode = waveform_mode
    end
    -- TEMP_USE_PAPYRUS on Touch/PW1, TEMP_USE_AUTO on PW2 (same value in both cases, 0x1001)
    refarea[0].temp = ffi.C.TEMP_USE_AUTO
    -- NOTE: We never use any flags on Kindle.
    -- TODO: EPDC_FLAG_ENABLE_INVERSION & EPDC_FLAG_FORCE_MONOCHROME might be of use, though,
    --       although the framework itself barely ever sets any flags, for some reason...
    refarea[0].flags = 0

    return mxc_update(fb, refarea, refreshtype, waveform_mode, x, y, w, h)
end

local function refresh_kobo(fb, refreshtype, waveform_mode, x, y, w, h)
    local refarea = ffi.new("struct mxcfb_update_data[1]")
    -- only for Kobo's driver:
    refarea[0].alt_buffer_data.virt_addr = nil
    -- TEMP_USE_AMBIENT, not that there was ever any other choice on Kobo...
    refarea[0].temp = ffi.C.TEMP_USE_AMBIENT
    -- Enable the appropriate flag when requesting a REAGLD waveform (NTX_WFM_MODE_GLD16 on the Aura)
    if waveform_mode == ffi.C.NTX_WFM_MODE_GLD16 then
        refarea[0].flags = ffi.C.EPDC_FLAG_USE_AAD
    elseif waveform_mode == ffi.C.WAVEFORM_MODE_A2 then
        -- As well as when requesting a 2bit waveform
        refarea[0].flags = ffi.C.EPDC_FLAG_FORCE_MONOCHROME
    else
        refarea[0].flags = 0
    end

    return mxc_update(fb, refarea, refreshtype, waveform_mode, x, y, w, h)
end

local function refresh_pocketbook(fb, refreshtype, waveform_mode, x, y, w, h)
    local refarea = ffi.new("struct mxcfb_update_data[1]")
    -- TEMP_USE_AMBIENT
    refarea[0].temp = 0x1000

    return mxc_update(fb, refarea, refreshtype, waveform_mode, x, y, w, h)
end

--[[ framebuffer API ]]--

function framebuffer:refreshPartialImp(x, y, w, h)
    self.debug("refresh: partial", x, y, w, h)
    self:mech_refresh(ffi.C.UPDATE_MODE_PARTIAL, self.waveform_partial, x, y, w, h)
end

-- NOTE: UPDATE_MODE_FULL doesn't mean full screen or no region, it means ask for a black flash!
function framebuffer:refreshFlashPartialImp(x, y, w, h)
    self.debug("refresh: partial w/ flash", x, y, w, h)
    self:mech_refresh(ffi.C.UPDATE_MODE_FULL, self.waveform_partial, x, y, w, h)
end

function framebuffer:refreshUIImp(x, y, w, h)
    self.debug("refresh: ui-mode", x, y, w, h)
    self:mech_refresh(ffi.C.UPDATE_MODE_PARTIAL, self.waveform_ui, x, y, w, h)
end

function framebuffer:refreshFlashUIImp(x, y, w, h)
    self.debug("refresh: ui-mode w/ flash", x, y, w, h)
    self:mech_refresh(ffi.C.UPDATE_MODE_FULL, self.waveform_ui, x, y, w, h)
end

function framebuffer:refreshFullImp(x, y, w, h)
    self.debug("refresh: full", x, y, w, h)
    self:mech_refresh(ffi.C.UPDATE_MODE_FULL, self.waveform_full, x, y, w, h)
end

function framebuffer:refreshFastImp(x, y, w, h)
    self.debug("refresh: fast", x, y, w, h)
    self:mech_refresh(ffi.C.UPDATE_MODE_PARTIAL, self.waveform_fast, x, y, w, h)
end

function framebuffer:init()
    framebuffer.parent.init(self)

    self.refresh_list = {}

    if self.device:isKindle() then
        require("ffi/mxcfb_kindle_h")

        self.mech_refresh = refresh_k51
        self.mech_wait_update_complete = kindle_pearl_mxc_wait_for_update_complete
        self.mech_wait_update_submission = kindle_mxc_wait_for_update_submission

        self.waveform_fast = ffi.C.WAVEFORM_MODE_A2
        self.waveform_ui = ffi.C.WAVEFORM_MODE_GC16_FAST
        self.waveform_full = ffi.C.WAVEFORM_MODE_GC16

        -- New devices are REAGL-aware, default to REAGL
        local isREAGL = true

        if self.device.model == "Kindle2" then
            isREAGL = false
        elseif self.device.model == "KindleDXG" then
            isREAGL = false
        elseif self.device.model == "Kindle3" then
            isREAGL = false
        elseif self.device.model == "Kindle4" then
            isREAGL = false
        elseif self.device.model == "KindleTouch" then
            isREAGL = false
        elseif self.device.model == "KindlePaperWhite" then
            isREAGL = false
        end

        if isREAGL then
            self.mech_wait_update_complete = kindle_carta_mxc_wait_for_update_complete
            --self.waveform_fast = ffi.C.WAVEFORM_MODE_AUTO
            self.waveform_partial = ffi.C.WAVEFORM_MODE_REAGL
        else
            self.waveform_partial = ffi.C.WAVEFORM_MODE_GL16_FAST -- NOTE: Depending on FW, might instead be AUTO w/ hist_gray_waveform_mode set to GL16_FAST
        end
    elseif self.device:isKobo() then
        require("ffi/mxcfb_kobo_h")

        self.mech_refresh = refresh_kobo
        self.mech_wait_update_complete = kobo_mxc_wait_for_update_complete

        self.waveform_fast = ffi.C.WAVEFORM_MODE_A2
        self.waveform_ui = ffi.C.WAVEFORM_MODE_AUTO
        self.waveform_full = ffi.C.NTX_WFM_MODE_GC16
        self.waveform_partial = ffi.C.WAVEFORM_MODE_AUTO

        -- New devices *may* be REAGL-aware, but generally don't expect explicit REAGL requests, default to not.
        local isREAGL = false

        -- NOTE: AFAICT, the Aura was the only one explicitly requiring REAGL requests...
        if self.device.model == "Kobo_phoenix" then
            isREAGL = true
        end

        if isREAGL then
            self.waveform_partial = ffi.C.NTX_WFM_MODE_GLD16
            self.waveform_fast = ffi.C.WAVEFORM_MODE_DU -- Mainly menu HLs, compare to Kindle's use of AUTO in these instances ;).
        end
    elseif self.device:isPocketBook() then
        require("ffi/mxcfb_pocketbook_h")

        self.mech_refresh = refresh_pocketbook
        self.mech_wait_update_complete = pocketbook_mxc_wait_for_update_complete

        self.waveform_fast = ffi.C.WAVEFORM_MODE_A2
        self.waveform_ui = ffi.C.WAVEFORM_MODE_GC16
        self.waveform_full = ffi.C.WAVEFORM_MODE_GC16
        self.waveform_partial = ffi.C.WAVEFORM_MODE_GC16
    else
        error("unknown device type")
    end
end

return require("ffi/framebuffer_linux"):extend(framebuffer)
