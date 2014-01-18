--[[
Module for various utility functions
]]

local ffi = require "ffi"
local bit = require "bit"

require("ffi/posix_h")

local util = {}

local timeval = ffi.new("struct timeval")
function util.gettime()
	ffi.C.gettimeofday(timeval, nil)
	return tonumber(timeval.tv_sec),
		tonumber(timeval.tv_usec)
end

util.sleep=ffi.C.sleep
util.usleep=ffi.C.usleep

local statvfs = ffi.new("struct statvfs")
function util.df(path)
	ffi.C.statvfs(path, statvfs)
	return tonumber(statvfs.f_blocks * statvfs.f_bsize),
		tonumber(statvfs.f_bfree * statvfs.f_bsize)
end

function util.realpath(path)
	local path_ptr = ffi.C.realpath(path, nil)
	if path_ptr == nil then
		return nil
	end
	path = ffi.string(path_ptr)
	ffi.C.free(path_ptr)
	return path
end

function util.execute(...)
	local pid = ffi.C.fork()
	if pid == 0 then
		local args = {...}
		ffi.C.execl(args[1], unpack(args, 1, #args+1))
	end
	local status = ffi.new('int[1]')
	ffi.C.waitpid(pid, status, 0)
	return status[0]
end

function util.utf8charcode(charstring)
	local ptr = ffi.cast("uint8_t *", charstring)
	local len = #charstring
	local result = 0
	if len == 1 then
		return bit.band(ptr[0], 0x7F)
	elseif len == 2 then 
		return bit.lshift(bit.band(ptr[0], 0x1F), 6) +
			bit.band(ptr[1], 0x3F)
	elseif len == 3 then
		return bit.lshift(bit.band(ptr[0], 0x0F), 12) +
			bit.lshift(bit.band(ptr[1], 0x3F), 6) +
			bit.band(ptr[2], 0x3F)
	end
end

function util.isEmulated()
	return (ffi.arch ~= "arm")
end

local haveSDL2 = nil

function util.haveSDL2()
	if haveSDL2 == nil then
		haveSDL2 = pcall(ffi.load, "SDL2")
	end
	return haveSDL2
end

return util
