-- Automatically generated with {0}.

local ffi = require("ffi")
local C = ffi.C

local target_version
for __, version in ipairs{{ {1} }} do
    if C.POCKETBOOK_VERSION >= version then
        target_version = version
    end
end
if not target_version then
    error("unsupported PocketBook software version: " .. tonumber(C.POCKETBOOK_VERSION))
end
print("target PocketBook software version: " ..  target_version)

require "ffi/posix_h"
