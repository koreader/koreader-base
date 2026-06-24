-- Automatically generated with {0}.

local ffi = require("ffi")

local platform_str
if os.getenv("IS_ANDROID") then
    platform_str = "android_" .. ffi.arch
elseif ffi.os == "OSX" then
    platform_str = "macos"
else
    platform_str = ffi.os:lower() .. "_" .. ffi.arch
end
local platform = ({{ {1} }})[platform_str]
if not platform then
    error("unsupported platform: " .. platform_str)
end
