-- don't try to overwrite metatables so we can use --auto-insulate-tests
-- shamelessly copied from https://github.com/Olivine-Labs/busted/commit/db6d8b4be8fd099ab387efeb8232cfd905912abb
local ffi = require "ffi"
local old_metatype = ffi.metatype
local exists = {}
ffi.metatype = function(def, mttable)
    if exists[def] then return exists[def] end
    exists[def] = old_metatype(def, mttable)
    return exists[def]
end
