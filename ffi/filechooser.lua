local ffi = require("ffi")
local util = require("ffi/util")

if util.isSDL() then
    if util.haveSDL2() then
        local ok, gtk = pcall(ffi.load, "gtk-3")
        if not ok then
            ok, gtk = pcall(ffi.load, "gtk-3.so.0")
        end
        if ok then
            return require("ffi/filechooser_gtk-3")
        end
    end
end

return false
