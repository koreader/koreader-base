local lfs = require "lfs"

describe("generated", function()
    local ffi_cdecl_dir = lfs.symlinkattributes("ffi").target .. "-cdecl"

    for variant in string.gmatch([[
        android_arm
        android_arm64
        android_x64
        android_x86
        linux_arm
        linux_arm64
        linux_x64
        macos
        ]], "[^%s]+") do
        local file = string.format("%s/posix_h_%s.lua", ffi_cdecl_dir, variant)

        it(file.." should load", function()
            local ret = os.execute("./luajit "..file)
            assert.are.equal(0, ret)
        end)
    end
end)
