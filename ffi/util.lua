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
	local path_ptr = ffi.C.realpath(path, ffi.new("char[?]", ffi.C.PATH_MAX))
	if path_ptr == nil then return nil end
	return ffi.string(path_ptr)
end

function util.execute(...)
	local pid = ffi.C.fork()
	if pid == 0 then
		local args = {...}
		os.exit(ffi.C.execl(args[1], unpack(args, 1, #args+1)))
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

-- for now, we just check if the "android" module can be loaded
local isAndroid = nil
function util.isAndroid()
	if isAndroid == nil then
		isAndroid = pcall(require, "android")
	end
	return isAndroid
end

local haveSDL2 = nil

function util.haveSDL2()
	if haveSDL2 == nil then
		haveSDL2 = pcall(ffi.load, "SDL2")
	end
	return haveSDL2
end

function util.idiv(a, b)
    q = a/b
    return (q > 0) and math.floor(q) or math.ceil(q)
end

function util.orderedPairs(t)
    local function __genOrderedIndex( t )
    -- this function is taken from http://lua-users.org/wiki/SortedIteration
        local orderedIndex = {}
        for key in pairs(t) do
            table.insert( orderedIndex, key )
        end
        table.sort( orderedIndex )
        return orderedIndex
    end

    local function orderedNext(t, state)
    -- this function is taken from http://lua-users.org/wiki/SortedIteration
    
        -- Equivalent of the next function, but returns the keys in the alphabetic
        -- order. We use a temporary ordered key table that is stored in the
        -- table being iterated.

        if state == nil then
            -- the first time, generate the index
            t.__orderedIndex = __genOrderedIndex( t )
            key = t.__orderedIndex[1]
            return key, t[key]
        end
        -- fetch the next value
        key = nil
        for i = 1,table.getn(t.__orderedIndex) do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end

        if key then
            return key, t[key]
        end

        -- no more value to return, cleanup
        t.__orderedIndex = nil
        return
    end

-- this function is taken from http://lua-users.org/wiki/SortedIteration
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

function util.unichar (value)
-- this function is taken from dkjson
-- http://dkolf.de/src/dkjson-lua.fsl/
    local floor = math.floor
    local strchar = string.char
    if value < 0 then
        return nil
    elseif value <= 0x007f then
        return string.char (value)
    elseif value <= 0x07ff then
        return string.char (0xc0 + floor(value/0x40),0x80 + (floor(value) % 0x40))
    elseif value <= 0xffff then
        return string.char (0xe0 + floor(value/0x1000), 0x80 + (floor(value/0x40) % 0x40), 0x80 + (floor(value) % 0x40))
    elseif value <= 0x10ffff then
        return string.char (0xf0 + floor(value/0x40000), 0x80 + (floor(value/0x1000) % 0x40), 0x80 + (floor(value/0x40) % 0x40), 0x80 + (floor(value) % 0x40))
    else
        return nil
    end
end

return util
