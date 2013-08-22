--[[
Module for various utility functions
]]

local ffi = require "ffi"
local bit = require "bit"

ffi.cdef[[
struct timeval {
	long int tv_sec;
	long int tv_usec;
};
int gettimeofday(struct timeval *restrict, struct timezone *restrict) __attribute__((__nothrow__, __leaf__));

unsigned int sleep(unsigned int);
int usleep(unsigned int);

struct statvfs {
	long unsigned int f_bsize;
	long unsigned int f_frsize;
	long unsigned int f_blocks;
	long unsigned int f_bfree;
	long unsigned int f_bavail;
	long unsigned int f_files;
	long unsigned int f_ffree;
	long unsigned int f_favail;
	long unsigned int f_fsid;
	int __f_unused;
	long unsigned int f_flag;
	long unsigned int f_namemax;
	int __f_spare[6];
};
int statvfs(const char *restrict, struct statvfs *restrict) __attribute__((__nothrow__, __leaf__));
]]

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

return util
