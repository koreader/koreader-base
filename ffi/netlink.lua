local bit = require "bit"
local buffer = require "string.buffer"
local ffi = require "ffi"
local posix = require "ffi/posix"
local C = ffi.C

require "ffi/netlink_h"
require "ffi/nl80211_h"

-- C declarations. {{{

ffi.cdef[[
struct iehdr {
  uint8_t id;
  uint8_t len;
};
static const unsigned SIZEOF_IEHDR = sizeof(struct iehdr);
static const unsigned EID_SSID = 0;
typedef struct {
    struct nlmsghdr;
    union {
        struct genlmsghdr;
        int err;
    };
    uint8_t data[];
} netlink_message;
static const unsigned SIZEOF_NETLINK_MESSAGE = sizeof(netlink_message);
]]

-- }}}

-- Netlink. {{{

local Netlink = {}

Netlink.family_id = {}

function Netlink:new(manifest_url, state_dir, seed)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.buf = buffer:new(8 * 1024)
    o.seq = 0
    return o
end

function Netlink:new_message(msg_type, msg_cmd, msg_dump)
    local len = C.SIZEOF_NETLINK_MESSAGE
    self.buf:reset():reserve(len)
    self.buf:commit(len)
    self.msg_type = msg_type
    self.msg_flags = bit.bor(C.NLM_F_ACK, C.NLM_F_REQUEST, msg_dump and C.NLM_F_DUMP or 0)
    self.msg_cmd = msg_cmd
    return self
end

function Netlink:connect()
    local fd = C.socket(C.AF_NETLINK, bit.bor(C.SOCK_DGRAM, C.SOCK_CLOEXEC), C.NETLINK_GENERIC)
    if -1 == fd then
        error(posix.strerror())
    end
    local value = ffi.new("uint32_t[1]")
    value[0] = 32768
    if C.setsockopt(fd, C.SOL_SOCKET, C.SO_SNDBUF, value, 4) ~= 0 then
        io.stderr:write(string.format("setsockopt(SO_SNDBUF) failed: %s\n", posix.strerror()))
    end
    if C.setsockopt(fd, C.SOL_SOCKET, C.SO_RCVBUF, value, 4) ~= 0 then
        io.stderr:write(string.format("setsockopt(SO_RCVBUF) failed: %s\n", posix.strerror()))
    end
    if C.setsockopt(fd, C.SOL_NETLINK, C.NETLINK_CAP_ACK, value, 4) ~= 0 then
        local err = ffi.errno()
        if err ~= C.ENOPROTOOPT then
            io.stderr:write(string.format("setsockopt(NETLINK_CAP_ACK) failed: %s\n", posix.strerror(err)))
        end
    end
    local sa = ffi.new("struct sockaddr_nl", C.AF_NETLINK)
    local addr_len = ffi.new("socklen_t[1]", ffi.sizeof(sa))
    if C.getsockname(fd, ffi.cast("struct sockaddr *", sa), addr_len) ~= 0 then
        error(posix.strerror())
    end
    if addr_len[0] ~= ffi.sizeof(sa) or sa.nl_family ~= C.AF_NETLINK then
        error("netlink not supported")
    end
    self.fd = fd
    return self
end

function Netlink:close()
    if self.fd then
        C.close(self.fd)
        self.fd = nil
    end
end

function Netlink:_put(nla_type, nla_data, nla_size)
    local len = C.SIZEOF_NLATTR + nla_size
    local pad = len % 4
    if pad ~= 0 then
        -- Attribute headers must be aligned to
        -- 4 bytes from the start of the message.
        pad = 4 - pad
    end
    local ptr = self.buf:reserve(len + pad)
    local attr = ffi.cast("struct nlattr *", ptr)
    attr.nla_len = len
    attr.nla_type = nla_type
    ffi.copy(ptr + C.SIZEOF_NLATTR, nla_data, nla_size)
    if pad ~= 0 then
        ffi.fill(ptr + len, pad)
    end
    self.buf:commit(len + pad)
    return self
end

function Netlink:put_string(nla_type, s)
    return self:_put(nla_type, s, #s + 1)
end

function Netlink:put_u64(nla_type, u)
    local u64 = ffi.new("uint64_t[1]", u)
    return self:_put(nla_type, u64, 8)
end

function Netlink:put_u32(nla_type, u)
    local u32 = ffi.new("uint32_t[1]", u)
    return self:_put(nla_type, u32, 4)
end

function Netlink:send()
    assert(self.msg_type and self.msg_flags and self.msg_cmd)
    local ptr, len = self.buf:ref()
    local msg = ffi.cast("netlink_message *", ptr)
    self.seq = self.seq + 1
    msg.nlmsg_len = #self.buf
    msg.nlmsg_type = self.msg_type
    msg.nlmsg_flags = self.msg_flags
    msg.nlmsg_seq = self.seq
    msg.nlmsg_pid = 0;
    msg.cmd = self.msg_cmd
    msg.version = 1
    msg.reserved = 0
    self.msg_type = nil
    self.msg_flags = nil
    self.msg_cmd = nil
    posix.send(self.fd, ptr, len)
    return self
end

function Netlink:receive()
    self.buf:reset()
    while true do
        -- Peek at message length.
        local len = posix.recv(self.fd, nil, 0, bit.bor(C.MSG_PEEK, C.MSG_TRUNC))
        if len < C.SIZEOF_NLMSGHDR then
            error("message too short")
        end
        local ptr = self.buf:reserve(len)
        posix.recv(self.fd, ptr, len)
        local msg = ffi.cast("netlink_message *", ptr)
        assert(msg.nlmsg_seq == self.seq)
        assert(msg.nlmsg_len >= C.SIZEOF_NETLINK_MESSAGE)
        assert(bit.band(msg.nlmsg_flags, C.NLM_F_DUMP_INTR) == 0)
        if msg.nlmsg_type == C.NLMSG_ERROR or msg.nlmsg_type == C.NLMSG_DONE then
            local err = msg.err
            if err == 0 then
                break
            end
            error(err < 0 and posix.strerror(-err) or tostring(err))
        end
        self.buf:commit(len)
    end
    local ptr, len = self.buf:ref()
    return function()
        if len <= 0 then
            return
        end
        local msg = ffi.cast("netlink_message *", ptr)
        ptr = ptr + msg.nlmsg_len
        len = len - msg.nlmsg_len
        return msg.nlmsg_type, msg.data, msg.nlmsg_len - C.SIZEOF_NETLINK_MESSAGE
    end
end

function Netlink.iter_attrs(ptr, len)
    return function()
        if len <= 0 then
            return
        end
        local attr = ffi.cast("struct nlattr *", ptr)
        local pad = attr.nla_len % 4
        if pad ~= 0 then
            pad = 4 - pad
        end
        assert(attr.nla_len >= C.SIZEOF_NLATTR)
        assert(attr.nla_type ~= 0)
        local nla_data = ptr + C.SIZEOF_NLATTR
        local nla_size = attr.nla_len - C.SIZEOF_NLATTR
        local skip = attr.nla_len + pad
        assert(skip <= len)
        ptr = ptr + skip
        len = len - skip
        return attr.nla_type, nla_data, nla_size
    end
end

function Netlink:get_family_id(family_name)
    local family_id = self.family_id[family_name]
    if family_id then
        return family_id
    end
    self:new_message(C.GENL_ID_CTRL, C.CTRL_CMD_GETFAMILY)
    self:put_string(C.CTRL_ATTR_FAMILY_NAME, family_name)
    for msg_type, attrs_data, attrs_size in self:send():receive() do
        for nla_type, nla_data, nla_size in self.iter_attrs(attrs_data, attrs_size) do
            if nla_type == C.CTRL_ATTR_FAMILY_ID then
                assert(nla_size == 2, tostring(nla_size))
                family_id = ffi.cast("uint16_t *", nla_data)[0]
                self.family_id[family_name] = family_id
            end
        end
    end
    return family_id
end

-- }}}

return Netlink

-- vim: foldmethod=marker foldlevel=0
