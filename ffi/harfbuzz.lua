local ffi = require("ffi")
require("ffi/harfbuzz_h")
return ffi.load("libs/libharfbuzz." .. (ffi.os == "OSX" and "0.dylib" or "so.0"))
