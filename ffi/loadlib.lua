local ffi = require("ffi")
local android = ffi.os == "Linux" and os.getenv("IS_ANDROID") and require("android")
local log = android and android.LOGI or print

local monolibtic = {
    path = (android and android.nativeLibraryDir or "libs") .. "/libkoreader-monolibtic.so",
    redirects = {
        ["blitbuffer"] = true,
        ["czmq"]       = true,
        ["freetype"]   = true,
        ["fribidi"]    = true,
        ["gif"]        = true,
        ["harfbuzz"]   = true,
        ["jpeg"]       = true,
        ["k2pdfopt"]   = true,
        ["leptonica"]  = true,
        ["lodepng"]    = true,
        ["lunasvg"]    = true,
        ["png16"]      = true,
        ["sharpyuv"]   = true,
        ["sqlite3"]    = true,
        ["tffi_wrap"]  = true,
        ["turbojpeg"]  = true,
        ["unibreak"]   = true,
        ["utf8proc"]   = true,
        ["webp"]       = true,
        ["webpdemux"]  = true,
        ["wrap-mupdf"] = true,
        ["z"]          = true,
        ["zmq"]        = true,
        ["zstd"]       = true,
    },
}
monolibtic.enabled, monolibtic.library = pcall(ffi.load, monolibtic.path)
if monolibtic.enabled then
    log("has monolibtic? yes")
    table.insert(package.loaders, function (modulename)
        local fn
        if modulename:sub(1, 17) == "libs/libkoreader-" then
            -- KOReader Lua modules in `libs/`, loaded with `require("libs/libkoreader-xxx")`.
            fn = "luaopen_" .. modulename:sub(18)
        else
            fn = "luaopen_" .. modulename:gsub("%.", "_")
        end
        log(string.format("package.loadlib: %s [%s]", monolibtic.path, modulename))
        return package.loadlib(monolibtic.path, fn)
    end)
else
    log("has monolibtic? no (" .. monolibtic.library .. ")")
    monolibtic = nil
end

local lib_search_path
local lib_basic_format
local lib_version_format

local function libname(name, version)
    return string.format(version and lib_version_format or lib_basic_format, name, version)
end

local function findlib(...)
    local name, version = ...
    if not name then
        return
    end
    log("ffi.findlib: " .. name .. (version and (" [" .. version .. "]") or ""))
    if monolibtic and monolibtic.redirects[name] then
        return monolibtic.path
    end
    local lib = libname(name, version)
    local path = package.searchpath(lib, lib_search_path, "/", "/")
    if path then
        return path
    end
    return findlib(select(3, ...))
end

local ffi_load = ffi.load

ffi.load = function(lib, global)
    log("ffi.load: " .. lib .. (global and " (RTLD_GLOBAL)" or ""))
    return ffi_load(lib, global)
end

ffi.loadlib = function(...)
    local lib = findlib(...) or libname(...)
    return ffi.load(lib)
end

if android then
    -- Note: our libraries are not versioned on Android.
    lib_search_path = android.nativeLibraryDir .. "/?"
    lib_basic_format = "lib%s.so"
    lib_version_format = "lib%s.so"
    if not monolibtic then
        -- Android need some custom code for KOReader Lua modules loaded
        -- with `require("libs/libkoreader-xxx")`, but actually stored
        -- under the application's directory for native libraries.
        table.insert(package.loaders, 1, function (modulename)
            if modulename:sub(1, 17) ~= "libs/libkoreader-" then
                return
            end
            local path = android.nativeLibraryDir .. "/" .. libname(modulename:sub(9))
            log(string.format("package.loadlib: %s [%s]", path, modulename))
            return package.loadlib(path, "luaopen_" .. modulename:sub(18))
        end)
    end
elseif ffi.os == "Linux" then
    lib_search_path = "libs/?"
    lib_basic_format = "lib%s.so"
    lib_version_format = "lib%s.so.%s"
elseif ffi.os == "OSX" then
    -- Apple M1 homebrew installs libraries outside of default search paths,
    -- and dyld environment variables are sip-protected on MacOS, cf.
    -- https://github.com/Homebrew/brew/issues/13481#issuecomment-1181592842
    local libprefix = os.getenv("KO_DYLD_PREFIX")
    if not libprefix then
        local std_out = io.popen("brew --prefix", "r")
        if std_out then
            libprefix = std_out:read("*line")
            std_out:close()
        end
    end
    lib_search_path = "libs/?"
    if libprefix then
        lib_search_path = lib_search_path .. ";" .. libprefix .. "/lib/?"
    end
    lib_basic_format = "lib%s.dylib"
    lib_version_format = "lib%s.%s.dylib"
end

log("lib_search_path: " .. lib_search_path)
log("lib_basic_format: " .. lib_basic_format)
log("lib_version_format: " .. lib_version_format)
