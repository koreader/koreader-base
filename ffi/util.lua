--[[--
Module for various utility functions.

@module ffi.util
]]

local bit = require "bit"
local ffi = require "ffi"
local C = ffi.C

local lshift = bit.lshift
local band = bit.band
local bor = bit.bor

-- win32 utility
ffi.cdef[[
typedef unsigned int UINT;
typedef unsigned long DWORD;
typedef char *LPSTR;
typedef wchar_t *LPWSTR;
typedef const char *LPCSTR;
typedef const wchar_t *LPCWSTR;
typedef bool *LPBOOL;
typedef LPSTR LPTSTR;
typedef int BOOL;

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
LPTSTR PathFindFileNameA(LPCSTR lpszPath);
BOOL PathRemoveFileSpec(LPTSTR pszPath);
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
        tmpres = bor(tmpres, ft.dwHighDateTime)
        tmpres = lshift(tmpres, 32)
        tmpres = bor(tmpres, ft.dwLowDateTime)
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

--- Wrapper for C.realpath.
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

--- Wrapper for C.basename.
function util.basename(path)
    local ptr = ffi.cast("uint8_t *", path)
    if ffi.os == "Windows" then
        return ffi.string(C.PathFindFileNameA(ptr))
    else
        return ffi.string(C.basename(ptr))
    end
end

--- Wrapper for C.dirname.
function util.dirname(in_path)
    --[[
    Both PathRemoveFileSpec and dirname will change original input string, so
    we need to make a copy.
    --]]
    local path = ffi.new("char[?]", #in_path + 1)
    ffi.copy(path, in_path)
    local ptr = ffi.cast("uint8_t *", path)
    if ffi.os == "Windows" then
        if C.PathRemoveFileSpec(ptr) then
            return ffi.string(ptr)
        else
            return path
        end
    else
        return ffi.string(C.dirname(ptr))
    end
end

--- Copies file.
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

--[[--
Joins paths.

NOTE: If `path2` is an absolute path, then this function ignores `path1` and returns `path2` directly.
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

--- Purges directory.
function util.purgeDir(dir)
    local ok, err
    ok, err = lfs.attributes(dir)
    if not ok or err ~= nil then
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

--- Executes child process.
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

--- Run lua code (func) in a forked subprocess
--
-- With with_pipe=true, sets up a pipe for communication
-- from children towards parent.
-- func is called with the child pid as 1st argument, and,
-- if with_pipe: a fd for writting
-- This function returns (to parent): the child pid, and,
-- if with_pipe: a fd for reading what the child wrote
-- if double_fork: do a double fork so the child gets reparented to init,
--                 ensuring automatic reaping of zombies.
--                 NOTE: In this case, the pid returned will *already*
--                       have been reaped, making it fairly useless.
--                       This means you do NOT have to call isSubProcessDone on it.
--                       It is safe to do so, though, it'll just immediately return success,
--                       as waitpid will return -1 w/ an ECHILD errno.
function util.runInSubProcess(func, with_pipe, double_fork)
    local parent_read_fd, child_write_fd
    if with_pipe then
        local pipe = ffi.new('int[2]', {-1, -1})
        if C.pipe(pipe) ~= 0 then -- failed creating pipe !
            return false
        end
        parent_read_fd, child_write_fd = pipe[0], pipe[1]
        if parent_read_fd == -1 or child_write_fd == -1 then
            return false
        end
    end
    local pid = C.fork()
    if pid == 0 then -- child process
        if double_fork then
            pid = C.fork()
            if pid ~= 0 then
                -- Parent side of the outer fork, we don't need it anymore, so just exit.
                -- NOTE: Technically ought to be _exit, not exit.
                os.exit((pid < 0) and 1 or 0)
            end
            -- pid == 0 -> inner child :)
        end
        -- We need to wrap it with pcall: otherwise, if we were in a
        -- subroutine, the error would just abort the coroutine, bypassing
        -- our os.exit(0), and this subprocess would be a working 2nd instance
        -- of KOReader (with libraries or drivers probably getting messed up).
        local ok, err = xpcall(function()
            -- Give the child its own process group, so we can kill(-pid) it
            -- to have all its own children killed too (otherwise, parent
            -- process would kill the child, the child's children would
            -- be adopted by init, but parent would still have
            -- util.isSubProcessDone() returning false until all the child's
            -- children are done.
            C.setpgid(0, 0)
            if parent_read_fd then
                -- close our duplicate of parent fd
                C.close(parent_read_fd)
            end
            -- Just run the provided lua code object in this new process,
            -- and exit immediatly (so we do not release drivers and
            -- resources still used by parent process)
            -- We pass child pid to func, which can serve as a key
            -- to communicate with parent process.
            -- We pass child_write_fd (if with_pipe) so 'func' can write to it
            pid = C.getpid()
            func(pid, child_write_fd)
        end, debug.traceback)
        if not ok then
            print("error in subprocess:", err)
        end
        os.exit(0)
    end
    -- parent/main process
    if pid < 0 then -- on failure, fork() returns -1
        return false
    end
    -- If we double-fork, reap the outer fork now, since its only purpose is fork -> _exit
    if double_fork then
        local status = ffi.new('int[1]')
        local ret = C.waitpid(pid, status, 0)
        -- Returns pid on success, -1 on failure
        if ret < 0 then
            return false
        end
    end
    if child_write_fd then
        -- close our duplicate of child fd
        C.close(child_write_fd)
    end
    return pid, parent_read_fd
end

--- Collect subprocess so it does not become a zombie.
-- This does not block. Returns true if process was collected or was already
-- no more running, false if process is still running
function util.isSubProcessDone(pid)
    local status = ffi.new('int[1]')
    local ret = C.waitpid(pid, status, 1) -- 1 = WNOHANG : don't wait, just tell
    -- status = tonumber(status[0])
    -- If still running: ret = 0 , status = 0
    -- If exited: ret = pid , status = 0 or 9 if killed
    -- If no more running: ret = -1 , status = 0
    if ret == pid or ret == -1 then
        return true
    end
    return false
end

--- Terminate subprocess pid by sending SIGKILL
function util.terminateSubProcess(pid)
    local done = util.isSubProcessDone(pid)
    if not done then
        -- We kill with signal 9/SIGKILL, which may be violent, but ensures
        -- that it is terminated (a process may catch or ignore SIGTERM)
        -- If we used setpgid(0,0) above, we can kill the process group
        -- instead, by just using -pid
        -- C.kill(pid, 9)
        C.kill(-pid, 9)
        -- Process will still have to be collected with calls to
        -- util.isSubProcessDone(), which may still return false for
        -- some small amount of time after our kill()
    end
end

--- Returns the length of data that can be read immediately without blocking
--
-- Accepts a low-level file descriptor, or a higher level lua file object
-- returns 0 if not readable yet, otherwise len of available data
-- returns nil when unsupported: caller may read (with possible blocking)
--
-- Caveats with pipes: returns 0 too if other side of pipe has exited
-- without writing anything
function util.getNonBlockingReadSize(fd_or_luafile)
    local fileno
    if type(fd_or_luafile) == "number" then -- low-level fd
        fileno = fd_or_luafile
    else -- lua file object
        fileno = C.fileno(fd_or_luafile)
    end
    local available = ffi.new('int[1]')
    local ok = C.ioctl(fileno, C.FIONREAD, available)
    if ok ~= 0 then -- ioctl failed, not supported
        return
    end
    available = tonumber(available[0])
    return available
end

--- Write data to file descriptor, and optionally close it when done
--
-- May block if data is large until the other end has read it.
-- If data fits into kernel pipe buffer, it can return before the
-- other end has started reading it.
function util.writeToFD(fd, data, close_fd)
    local size = #data
    local ptr = ffi.cast("uint8_t *", data)
    -- print("writing to fd")
    local bytes_written = C.write(fd, ptr, size)
    -- print("done writing to fd")
    local success = bytes_written == size
    if close_fd then
        C.close(fd)
        -- print("write fd closed")
    end
    return success
end

--- Read all data from file descriptor, and close it.
-- This blocks until remote side has closed its side of the fd
function util.readAllFromFD(fd)
    local chunksize = 8192
    local buffer = ffi.new('char[?]', chunksize, {0})
    local data = {}
    while true do
        -- print("reading from fd")
        local bytes_read = tonumber(C.read(fd, ffi.cast('void*', buffer), chunksize))
        if bytes_read < 0 then
            local err = ffi.errno()
            print("readFromFD() error: "..ffi.string(C.strerror(err)))
            break
        elseif bytes_read == 0 then -- EOF, no more data to read
            break
        else
            table.insert(data, ffi.string(buffer, bytes_read))
        end
    end
    C.close(fd)
    -- print("read fd closed")
    return table.concat(data)
end

--- Ensure content written to lua file or fd is flushed to the storage device.
--
-- Accepts a low-level file descriptor, or a higher level lua file object,
-- which must still be opened (call :close() only after having called this).
-- If optional parameter sync_metadata is true, use fsync() to also flush
-- file metadata (timestamps...), otherwise use fdatasync() to only flush
-- file content and file size.
-- Returns true if syscall successful
-- See https://stackoverflow.com/questions/37288453/calling-fsync2-after-close2
function util.fsyncOpenedFile(fd_or_luafile, sync_metadata)
    local fileno
    if type(fd_or_luafile) == "number" then -- low-level fd
        fileno = fd_or_luafile
    else -- lua file object
        fd_or_luafile:flush() -- flush user-space buffers to system buffers
        fileno = C.fileno(fd_or_luafile)
    end
    local ret
    if sync_metadata then
        ret = C.fsync(fileno) -- sync file data and metadata
    else
        ret = C.fdatasync(fileno) -- sync only file data
    end
    if ret ~= 0 then
        local err = ffi.errno()
        return false, ffi.string(C.strerror(err))
    end
    return true
end

--- Ensure directory content updates are flushed to the storage device.
--
-- Accepts the directory path as a string, or a file path (from which
-- we can deduce the directory to sync).
-- Returns true if syscall successful
-- See http://blog.httrack.com/blog/2013/11/15/everything-you-always-wanted-to-know-about-fsync/
function util.fsyncDirectory(path)
    local attributes, err = lfs.attributes(path)
    if not attributes or err ~= nil then
        return false, err
    end
    if attributes.mode ~= "directory" then
        -- file, symlink...: get its parent directory
        path = util.dirname(path)
        attributes, err = lfs.attributes(path)
        if not attributes or err ~= nil or attributes.mode ~= "directory" then
            return false, err
        end
    end
    local dirfd = C.open(ffi.cast("char *", path), C.O_RDONLY)
    if dirfd == -1 then
        err = ffi.errno()
        return false, ffi.string(C.strerror(err))
    end
    -- Not certain it's safe to use fdatasync(), so let's go with the more costly fsync()
    -- https://austin-group-l.opengroup.narkive.com/vC4Fjvsn/fsync-ing-a-directory-file-descriptor
    local ret = C.fsync(dirfd)
    if ret ~= 0 then
        err = ffi.errno()
        C.close(dirfd)
        return false, ffi.string(C.strerror(err))
    end
    C.close(dirfd)
    return true
end

--- Gets UTF-8 charcode.
-- See unicodeCodepointToUtf8 in frontend/util for an encoder.
function util.utf8charcode(charstring)
    local ptr = ffi.cast("uint8_t *", charstring)
    local len = #charstring
    if len == 1 then
        return band(ptr[0], 0x7F)
    elseif len == 2 then
        return lshift(band(ptr[0], 0x1F), 6) +
            band(ptr[1], 0x3F)
    elseif len == 3 then
        return lshift(band(ptr[0], 0x0F), 12) +
            lshift(band(ptr[1], 0x3F), 6) +
            band(ptr[2], 0x3F)
    elseif len == 4 then
        return lshift(band(ptr[0], 0x07), 18) +
            lshift(band(ptr[1], 0x3F), 12) +
            lshift(band(ptr[2], 0x3F), 6) +
            band(ptr[3], 0x3F)
    end
end

local CP_UTF8 = 65001
--- Converts multibyte string to utf-8 encoded string on Windows.
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

function util.ffiLoadCandidates(candidates)
    local lib_loaded, lib

    for _, candidate in ipairs(candidates) do
        lib_loaded, lib = pcall(ffi.load, candidate)

        if lib_loaded then
            return lib
        end
    end

    -- we failed, lib is the error message
    return lib_loaded, lib
end

--- Returns true if isWindows…
function util.isWindows()
    return ffi.os == "Windows"
end

local isAndroid = nil
--- Returns true if Android.
-- For now, we just check if the "android" module can be loaded.
function util.isAndroid()
    if isAndroid == nil then
        isAndroid = pcall(require, "android")
    end
    return isAndroid
end

local haveSDL2 = nil

--- Returns true if SDL2
function util.haveSDL2()
    local err

    if haveSDL2 == nil then
        local candidates
        if jit.os == "OSX" then
            candidates = {"libs/libSDL2.dylib", "SDL2"}
        else
            candidates = {"SDL2", "libSDL2-2.0.so", "libSDL2-2.0.so.0"}
        end
        haveSDL2, err = util.ffiLoadCandidates(candidates)
    end
    if not haveSDL2 then
        print("SDL2 not loaded:", err)
    end

    return haveSDL2
end

local isSDL = nil
--- Returns true if SDL
function util.isSDL()
    if isSDL == nil then
        isSDL = util.haveSDL2()
    end
    return isSDL
end

--- Division with integer result.
function util.idiv(a, b)
    local q = a/b
    return (q > 0) and math.floor(q) or math.ceil(q)
end

-- pairs(), but with *keys* sorted alphabetically.
-- c.f., http://lua-users.org/wiki/SortedIteration
-- See also http://lua-users.org/wiki/SortedIterationSimple
local function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

local function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic order.
    -- We use a temporary ordered key table that is stored in the table being iterated.

    local key = nil
    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1,table.getn(t.__orderedIndex) do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function util.orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate in order
    return orderedNext, t, nil
end

--[[--
The util.template function allows for better translations through
dynamic positioning of place markers. The range of place markers
runs from %1 to %99, but normally no more than two or three should
be required. There are no provisions for escaping place markers.

@usage
    output = util.template(
        _("Hello %1, welcome to %2."),
        name,
        company
    )

This function was inspired by Qt:
<http://qt-project.org/doc/qt-4.8/internationalization.html#use-qstring-arg-for-dynamic-text>
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

return util
