require("ffi/blight_h")

local M = {}

-- Model detection logic
local is_rmpp = false
local is_rmppm = false
local is_rmppure = false
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

return M
