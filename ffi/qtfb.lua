require("ffi/qtfb_h")

local M = {}

-- Model detection logic
local is_rmpp = false
local is_rmppm = false
local is_rm2 = false
local is_rm1 = false

local f = io.open("/sys/devices/soc0/machine", "r")
if f then
    local machine = f:read("*all"):upper()
    f:close()
    if machine:find("FERRARI") then
        is_rmpp = true
    elseif machine:find("CHIAPPA") then
        is_rmppm = true
    elseif machine:find("2.0") then
        is_rm2 = true
    else
        is_rm1 = true
    end
end

M.is_rmpp = is_rmpp
M.is_rmppm = is_rmppm
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

return M
