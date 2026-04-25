local bit = require("bit")
local ffi = require("ffi")
local C = ffi.C

require "ffi/posix_h"

local posix = {}

local function strerror(err)
    return ffi.string(C.strerror(err or ffi.errno()))
end

posix.strerror = strerror

function posix.open(path, flags, mode)
    local fd = C.open(path, flags or C.O_RDONLY, mode and ffi.cast("mode_t", mode))
    if fd < 0 then
        error("open: "..strerror())
    end
    return fd
end

function posix.create(path, mode)
    return posix.open(path, bit.bor(C.O_CREAT, C.O_WRONLY, C.O_TRUNC), mode or bit.bor(C.S_IRUSR, C.S_IWUSR, C.S_IRGRP, C.S_IROTH))
end

function posix.lseek(fd, offset, whence)
    local ret = C.lseek(fd, offset, whence or C.SEEK_SET)
    if ret < 0 then
        error("lseek: "..strerror())
    end
    return ret
end

function posix.read(fd, ptr, len)
    local ret = C.read(fd, ptr, len)
    if ret ~= len then
        error("read: "..(ret < 0 and strerror() or string.format("short read, %u/%u", ret, len)))
    end
    return ret
end

function posix.write(fd, ptr, len)
    local ret = C.write(fd, ptr, len)
    if ret ~= len then
        error("write: "..(ret < 0 and strerror() or string.format("short write, %u/%u", ret, len)))
    end
    return ret
end

function posix.fopen(path, mode)
    local fp = C.fopen(path, mode or "rb")
    if fp == nil then
        error("fopen: "..strerror())
    end
    return fp
end

function posix.kill(pid, sig)
    return C.kill(pid, sig or 15)
end

return posix
