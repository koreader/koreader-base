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
int gettimeofday(struct timeval *tp, void *tzp);

unsigned int sleep(unsigned int seconds);
int usleep(unsigned int usec);

struct statvfs
{
	unsigned long int f_bsize;
	unsigned long int f_frsize;
	unsigned long int f_blocks;
	unsigned long int f_bfree;
	unsigned long int f_bavail;
	unsigned long int f_files;
	unsigned long int f_ffree;
	unsigned long int f_favail;
	unsigned long int f_fsid;
	unsigned long int f_flag;
	unsigned long int f_namemax;
	int __f_spare[6];
};
int statvfs(const char *path, struct statvfs *buf);
]]

local util = {}

function util.gettime()
	local timeval = ffi.new("struct timeval")
	ffi.C.gettimeofday(timeval, nil)
	return tonumber(timeval.tv_sec),
		tonumber(timeval.tv_usec)
end

util.sleep=ffi.C.sleep
util.usleep=ffi.C.usleep

function util.df(path)
	local statvfs = ffi.new("struct statvfs")
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
	if ffi.arch == "arm" then
		return 0
	end
	return 1
end

return util
