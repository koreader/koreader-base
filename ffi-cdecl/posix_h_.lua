-- Automatically generated with {0}.

local ffi = require("ffi")

local platforms = {{ {1} }}

local function is_musl()
    -- musl does not provide glibc's `gnu_get_libc_version`.
    ffi.cdef[[ const char *gnu_get_libc_version(void); ]]
    return not pcall(function() return ffi.C.gnu_get_libc_version end)
end

local platform_str, platform
if os.getenv("IS_ANDROID") then
    platform_str = "android_" .. ffi.arch
elseif ffi.os == "OSX" then
    platform_str = "macos"
else
    platform_str = ffi.os:lower() .. "_" .. ffi.arch
    if ffi.os == "Linux" and is_musl() then
        -- Use a musl specific variant if available (types & structs
        -- can differ from glibc, e.g. 64-bit `time_t` / `off_t` on arm).
        platform = platforms[platform_str .. "_musl"]
    end
end
platform = platform or platforms[platform_str]
if not platform then
    error("unsupported platform: " .. platform_str)
end

-- clock_gettime & friends require librt on old glibc (< 2.17) versions...
if ffi.os == "Linux" then
    -- Load it in the global namespace to make it easier on callers...
    -- NOTE: There's no librt.so symlink, so, specify the SOVER, but not the full path,
    --       in order to let the dynamic loader figure it out on its own (e.g.,  multilib).
    pcall(ffi.load, "rt.so.1", true)
end
