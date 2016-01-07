--[[
Module for various utility functions
]]

local bit = require "bit"
local ffi = require "ffi"
local C = ffi.C

-- win32 utility
ffi.cdef[[
typedef unsigned int UINT;
typedef unsigned long DWORD;
typedef char *LPSTR;
typedef wchar_t *LPWSTR;
typedef const char *LPCSTR;
typedef const wchar_t *LPCWSTR;
typedef bool *LPBOOL;

typedef struct _FILETIME {
	DWORD dwLowDateTime;
	DWORD dwHighDateTime;
} FILETIME, *PFILETIME;

void GetSystemTimeAsFileTime(FILETIME*);
DWORD GetFullPathNameA(
    LPCSTR lpFileName,
    DWORD nBufferLength,
    LPSTR lpBuffer,
    LPSTR *lpFilePart
);
UINT GetACP(void);
int MultiByteToWideChar(
    UINT CodePage,
    DWORD dwFlags,
    LPCSTR lpMultiByteStr,
    int cbMultiByte,
    LPWSTR lpWideCharStr,
    int cchWideChar
);
int WideCharToMultiByte(
    UINT CodePage,
    DWORD dwFlags,
    LPCWSTR lpWideCharStr,
    int cchWideChar,
    LPSTR lpMultiByteStr,
    int cbMultiByte,
    LPCSTR lpDefaultChar,
    LPBOOL lpUsedDefaultChar
);
]]

require("ffi/posix_h")

local util = {}


if ffi.os == "Windows" then
	util.gettime = function()
		local ft = ffi.new('FILETIME[1]')[0]
		local tmpres = ffi.new('unsigned long', 0)
		C.GetSystemTimeAsFileTime(ft)
		tmpres = bit.bor(tmpres, ft.dwHighDateTime)
		tmpres = bit.lshift(tmpres, 32)
		tmpres = bit.bor(tmpres, ft.dwLowDateTime)
		-- converting file time to unix epoch
		tmpres = tmpres - 11644473600000000ULL
		tmpres = tmpres / 10
		return tonumber(tmpres / 1000000ULL), tonumber(tmpres % 1000000ULL)
	end
else
    local timeval = ffi.new("struct timeval")
    util.gettime = function()
        C.gettimeofday(timeval, nil)
        return tonumber(timeval.tv_sec), tonumber(timeval.tv_usec)
    end
end

if ffi.os == "Windows" then
	util.sleep = function(sec)
		C.Sleep(sec*1000)
	end
	util.usleep = function(usec)
		C.Sleep(usec/1000)
	end
else
	util.sleep = C.sleep
	util.usleep = C.usleep
end

local statvfs = ffi.new("struct statvfs")
function util.df(path)
	C.statvfs(path, statvfs)
	return tonumber(statvfs.f_blocks * statvfs.f_bsize),
		tonumber(statvfs.f_bfree * statvfs.f_bsize)
end

function util.realpath(path)
	local buffer = ffi.new("char[?]", C.PATH_MAX)
	if ffi.os == "Windows" then
		if C.GetFullPathNameA(path, C.PATH_MAX, buffer, nil) ~= 0 then
			return ffi.string(buffer)
		end
	else
		if C.realpath(path, buffer) ~= nil then
			return ffi.string(buffer)
		end
	end
end

function util.copyFile(from, to)
    local ffp, err = io.open(from, "rb")
    if err ~= nil then
        return err
    end
    local tfp = io.open(to, "wb")
    while true do
        local bytes = ffp:read(8192)
        if not bytes then
            ffp:close()
            break
        end
        tfp:write(bytes)
    end
    tfp:close()
end

--[[
NOTE: If path2 is an absolute path, then ignore path1 and return path2 directly
--]]
function util.joinPath(path1, path2)
    if string.sub(path2, 1, 1) == "/" then
        return path2
    end
    if string.sub(path1, -1, -1) ~= "/" then
        path1 = path1 .. "/"
    end
    return path1 .. path2
end

function util.purgeDir(dir)
    local ok, err
    ok, err = lfs.attributes(dir)
    if err ~= nil then
        return nil, err
    end
    for f in lfs.dir(dir) do
        if f ~= "." and f ~= ".." then
            local fullpath = util.joinPath(dir, f)
            local attributes = lfs.attributes(fullpath)
            if attributes.mode == "directory" then
                ok, err = util.purgeDir(fullpath)
            else
                ok, err = os.remove(fullpath)
            end
            if not ok or err ~= nil then
                return ok, err
            end
        end
    end
    ok, err = os.remove(dir)
    return ok, err
end

function util.execute(...)
    if util.isAndroid() then
        local A = require("android")
        return A.execute(...)
    else
        local pid = C.fork()
        if pid == 0 then
            local args = {...}
            os.exit(C.execl(args[1], unpack(args, 1, #args+1)))
        end
        local status = ffi.new('int[1]')
        C.waitpid(pid, status, 0)
        return status[0]
    end
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

local CP_UTF8 = 65001
-- convert multibyte string to utf-8 encoded string on Windows
function util.multiByteToUTF8(str, codepage)
    -- if codepage is not provided we will query the system codepage
    codepage = codepage or C.GetACP()
    local size = C.MultiByteToWideChar(codepage, 0, str, -1, nil, 0)
    if size > 0 then
        local wstr = ffi.new("wchar_t[?]", size)
        C.MultiByteToWideChar(codepage, 0, str, -1, wstr, size)
        size = C.WideCharToMultiByte(CP_UTF8, 0, wstr, -1, nil, 0, nil, nil)
        if size > 0 then
            local mstr = ffi.new("char[?]", size)
            C.WideCharToMultiByte(CP_UTF8, 0, wstr, -1, mstr, size, nil, nil)
            return ffi.string(mstr)
        end
    end
end

function util.isWindows()
    return ffi.os == "Windows"
end

-- for now, we just check if the "android" module can be loaded
local isAndroid = nil
function util.isAndroid()
	if isAndroid == nil then
		isAndroid = pcall(require, "android")
	end
	return isAndroid
end

local haveSDL1 = nil
local haveSDL2 = nil

function util.haveSDL1()
	if haveSDL1 == nil then
		haveSDL1 = pcall(ffi.load, "SDL")
	end
	return haveSDL1
end

function util.haveSDL2()
	if haveSDL2 == nil then
		haveSDL2 = pcall(ffi.load, "SDL2")
	end
	return haveSDL2
end

local isSDL = nil
function util.isSDL()
	if isSDL == nil then
		isSDL = util.haveSDL2() or util.haveSDL1()
	end
	return isSDL
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

--[[
The util.template function allows for better translations through
dynamic positioning of place markers. The range of place markers
runs from %1 to %99, but normally no more than two or three should
be required. There are no provisions for escaping place markers.

output = util.template(
    _("Hello %1, welcome to %2."),
    name,
    company
)

This function was inspired by Qt:
http://qt-project.org/doc/qt-4.8/internationalization.html#use-qstring-arg-for-dynamic-text
--]]
function util.template(str, ...)
    local params = {...}
    -- shortcut:
    if #params == 0 then return str end
    local result = string.gsub(str, "%%([1-9][0-9]?)",
        function(i)
            return params[tonumber(i)]
        end)
    return result
end

function util.unichar (value)
-- this function is taken from dkjson
-- http://dkolf.de/src/dkjson-lua.fsl/
    local floor = math.floor
    local strchar = string.char
    if value < 0 then
        return nil
    elseif value <= 0x007f then
        return strchar(value)
    elseif value <= 0x07ff then
        return strchar(0xc0 + floor(value/0x40),0x80 + (floor(value) % 0x40))
    elseif value <= 0xffff then
        return strchar(0xe0 + floor(value/0x1000), 0x80 + (floor(value/0x40) % 0x40), 0x80 + (floor(value) % 0x40))
    elseif value <= 0x10ffff then
        return strchar(0xf0 + floor(value/0x40000), 0x80 + (floor(value/0x1000) % 0x40), 0x80 + (floor(value/0x40) % 0x40), 0x80 + (floor(value) % 0x40))
    else
        return nil
    end
end

return util
