local ffi = require("ffi")

-- The declaration vary depending on the arch, load the right one...

if ffi.arch == "x64" then
    require("ffi/pthread_x64_h")
elseif ffi.arch == "x86" then
    require("ffi/pthread_x86_h")
else
    require("ffi/pthread_def_h")
end

