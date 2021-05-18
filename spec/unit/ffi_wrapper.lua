-- Check if we're running a busted version recent enough that we don't need to deal with the LuaJIT hacks...
-- That currently means > 2.0.0 (i.e., scm-2, which isn't on LuaRocks...).
local busted_ok = false
for name, _ in pairs(package.loaded) do
    if name == "busted.luajit" then
        busted_ok = true
        break
    end
end

-- Whee!
if busted_ok then
    return
end

-- Don't try to overwrite metatables so we can use --auto-insulate-tests
-- Shamelessly copied from https://github.com/Olivine-Labs/busted/commit/2dfff99bda01fd3da56fd23415aba5a2a4cc0ffd
local ffi = require "ffi"

local original_metatype = ffi.metatype
local original_store = {}
ffi.metatype = function (primary, ...)
    if original_store[primary] then
        return original_store[primary]
    end
    local success, result, err = pcall(original_metatype, primary, ...)
    if not success then
        -- hard error was thrown
        error(result, 2)
    end
    if not result then
        -- soft error was returned
        return result, err
    end
    -- it worked, store and return
    original_store[primary] = result
    return result
end
