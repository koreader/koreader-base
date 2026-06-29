local bit = require("bit")
local buffer = require("string.buffer")
local ffi = require("ffi")
local posix = require("ffi/posix")
local util = require("ffi/util")

local C = ffi.C

local Updater = {}

function Updater:new(manifest_url, state_dir, seed, module, progress_frequency)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    -- Forwarded arguments.
    o.manifest_url = manifest_url
    o.seed = seed
    o.state_dir = state_dir
    -- Implementation specific.
    o.module = module
    o.progress_frequency = progress_frequency or 0.25
    -- Internal IPC machinery.
    o.abort_flag = ffi.cast("uint8_t *", C.mmap(nil, 1, bit.bor(ffi.C.PROT_READ, ffi.C.PROT_WRITE), bit.bor(ffi.C.MAP_SHARED, ffi.C.MAP_ANONYMOUS), -1, 0))
    o.buf = buffer:new()
    o.pid = nil
    o.read_fd = nil
    o.write_fd = nil
    o:_subprocess()
    return o
end

function Updater:free()
    if self.pid then
        self:_send()
        util.isSubProcessDone(self.pid, true)
        self.pid = nil
    end
    if self.write_fd then
        C.close(self.write_fd)
        self.write_fd = nil
    end
    if self.read_fd then
        C.close(self.read_fd)
        self.read_fd = nil
    end
    if self.abort_flag then
        C.munmap(self.abort_flag, 1)
        self.abort_flag = nil
    end
    self.buf = nil
    self.module = nil
    self.seed = nil
    self.state_dir = nil
end

function Updater:_recv()
    local len = ffi.new('uint16_t[1]')
    posix.read(self.read_fd, len, 2)
    posix.read(self.read_fd, self.buf:reset():reserve(len[0]), len[0])
    return unpack(self.buf:commit(len[0]):decode())
end

function Updater:_send(...)
    local len = ffi.new('uint16_t[1]', #self.buf:reset():encode{...})
    posix.write(self.write_fd, len, 2)
    posix.write(self.write_fd, self.buf:ref(), len[0])
    return self
end

function Updater:_subprocess()
    if self.pid then
        return
    end
    local pid, read_fd, write_fd = util.runInSubProcess(function(pid, write_fd, read_fd)
        self.write_fd = write_fd
        self.read_fd = read_fd
        local updater = require(self.module).Updater:new(self.manifest_url, self.state_dir, self.seed)
        while true do
            local method, with_progress = self:_recv()
            if not method then
                break
            end
            local last_update = 0
            local ok, ret = pcall(updater[method], updater, with_progress and function(count, total, ...)
                local new_update = util.getTimestamp()
                if count == total or new_update - last_update >= self.progress_frequency then
                    self:_send(true, {count, total, ...})
                    last_update = new_update
                end
                return self.abort_flag[0] == 0
            end or nil)
            self:_send(ok, ret)
        end
    end, "bidi")
    if not pid then
        error(read_fd)
    end
    self.pid = pid
    self.read_fd = read_fd
    self.write_fd = write_fd
end

function Updater:_call(method, progress_cb)
    self.abort_flag[0] = 0
    local len = util.getNonBlockingReadSize(self.read_fd)
    if len > 0 then
        posix.read(self.read_fd, self.buf:reset():reserve(len), len)
    end
    self:_send(method, progress_cb and true or false)
    local ok, ret
    while progress_cb do
        ok, ret = self:_recv()
        if not ok then
            error(ret)
        end
        if not progress_cb(unpack(ret)) then
            self.abort_flag[0] = 1
            return
        end
        if ret[1] == ret[2] then
            break
        end
    end
    ok, ret = self:_recv()
    if not ok then
        error(ret)
    end
    return ret
end

function Updater:fetch_manifest()
    return self:_call('fetch_manifest')
end

function Updater:prepare_update(progress_cb)
    return self:_call('prepare_update', progress_cb)
end

function Updater:download_update(progress_cb)
    return self:_call('download_update', progress_cb)
end

return Updater
