local bit = require("bit")
local ffi = require("ffi")
local C = ffi.C

require "ffi/posix_h"

local posix = {}

local function strerror(err)
    return ffi.string(C.strerror(err or ffi.errno()))
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

function posix.open(path, flags, mode)
    local fd = C.open(path, flags or C.O_RDONLY, mode and ffi.cast("mode_t", mode))
    if fd < 0 then
        error("open: "..strerror())
    end
    return fd
end

function posix.read(fd, ptr, len, deny_short)
    ptr = ffi.cast("uint8_t *", ptr)
    local count = 0
    while count < len do
        local ret = C.read(fd, ptr + count, len - count)
        if ret == 0 then
            if deny_short then
                error("read: "..string.format("short read, %u/%u", count, len))
            end
            break
        end
        if ret < 0 then
            if ffi.errno() ~= C.EINTR then
                error("read: "..strerror())
            end
        else
            count = count + ret
        end
    end
    return count
end

posix.strerror = strerror

function posix.write(fd, ptr, len, deny_short)
    ptr = ffi.cast("uint8_t *", ptr)
    local count = 0
    while count < len do
        local ret = C.write(fd, ptr + count, len - count)
        if ret == 0 then
            if deny_short then
                error("write: "..string.format("short write, %u/%u", count, len))
            end
            break
        end
        if ret < 0 then
            if ffi.errno() ~= C.EINTR then
                error("write: "..strerror())
            end
        else
            count = count + ret
        end
    end
    return count
end

return posix
