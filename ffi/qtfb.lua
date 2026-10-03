require("ffi/qtfb_h")

local M = {}

-- Model detection logic
local is_rmpp = false
local is_rmppm = false
local is_rmppure = false
local is_rm2 = false
local is_rm1 = false

-- NOTE: model identifiers:
-- reMarkable 1: reMarkable 1.0 or reMarkable Prototype 1
-- reMarkable 2: reMarkable 2.0
-- reMarkable Paper Pro: reMarkable Ferrari
-- reMarkable Paper Pro Move: reMarkable Chiappa
-- reMarkable Paper Pure: reMarkable Tatsu
local f = io.open("/sys/devices/soc0/machine", "r")
if f then
    local machine = f:read("*all"):upper()
    f:close()
    if machine:find("FERRARI") then
        is_rmpp = true
    elseif machine:find("CHIAPPA") then
        is_rmppm = true
    elseif machine:find("TATSU") then
        is_rmppure = true
    elseif machine:find("2.0") then
        is_rm2 = true
    else
        is_rm1 = true
    end
end

M.is_rmpp = is_rmpp
M.is_rmppm = is_rmppm
M.is_rmppure = is_rmppure
M.is_rm2 = is_rm2
M.is_rm1 = is_rm1

-- Constants for ClientMessage types
M.MESSAGE_INITIALIZE = 0
M.MESSAGE_UPDATE = 1
M.MESSAGE_CUSTOM_INITIALIZE = 2
M.MESSAGE_TERMINATE = 3
M.MESSAGE_USERINPUT = 4
M.MESSAGE_SET_REFRESH_MODE = 5
M.MESSAGE_REQUEST_FULL_REFRESH = 6
M.MESSAGE_DEVICE_STATE_CHANGED = 7
M.MESSAGE_DEVICE_STATE_INIT = 8

M.REFRESH_MODE_UFAST = 0 -- WARNING! USING UFAST CAUSES EXCESSIVE GHOSTING AND SHOULD NOT BE USED.
M.REFRESH_MODE_FAST = 1
M.REFRESH_MODE_ANIMATE = 2
M.REFRESH_MODE_CONTENT = 3
M.REFRESH_MODE_UI = 4

M.STATE_CHANGED_REASON_ROTATION = 0

M.ROTATION_0 = 0
M.ROTATION_L90 = 1
M.ROTATION_R90 = 2
M.ROTATION_180 = 3

-- Framebuffer formats the QTFB server knows.
-- NOTE: Keep in sync with FBFMT_* in rm-appload's src/qtfb/common.h
M.FBFMT_RM2FB = 0
M.FBFMT_RMPP_RGB888 = 1
M.FBFMT_RMPP_RGBA8888 = 2
M.FBFMT_RMPP_RGB565 = 3
M.FBFMT_RMPPM_RGB888 = 4
M.FBFMT_RMPPM_RGBA8888 = 5
M.FBFMT_RMPPM_RGB565 = 6
M.FBFMT_RMPPURE_RGB888 = 7
M.FBFMT_RMPPURE_RGBA8888 = 8
M.FBFMT_RMPPURE_RGB565 = 9

-- Setting the correct framebuffer format for the device.
-- We set it in a common place so KOReader and qtfb_keep_alive always have the same values.
-- Color panels must use RGBA8888 because RGB565 tints the grays and causes dithering.
-- fb_format_fallback is used for when qtfb_keep_alive still holds the old format after
-- an in-app update.
if is_rmpp then
    M.fb_format = M.FBFMT_RMPP_RGBA8888
    M.fb_format_fallback = M.FBFMT_RMPP_RGB565
elseif is_rmppm then
    M.fb_format = M.FBFMT_RMPPM_RGBA8888
    M.fb_format_fallback = M.FBFMT_RMPPM_RGB565
elseif is_rmppure then
    M.fb_format = M.FBFMT_RMPPURE_RGB565
    M.fb_format_fallback = M.FBFMT_RM2FB
else
    M.fb_format = M.FBFMT_RM2FB
end

return M
