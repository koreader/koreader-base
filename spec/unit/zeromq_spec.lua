local ffi = require("ffi")
local zyre = ffi.load("libs/libzyre.so.1")
local filemq = ffi.load("libs/libfmq.so.1")

ffi.cdef[[
int zre_msg_test(bool verbose);
void zyre_peer_test(bool verbose);
void zyre_group_test(bool verbose);
void zyre_node_test(bool verbose);
void zyre_event_test(bool verbose);
void zyre_test(bool verbose);

int fmq_msg_test(bool verbose);
int fmq_server_test(bool verbose);
int fmq_client_test(bool verbose);
]]

describe("Zyre module", function()
    it("should pass self test", function()
        local verbose = true
        zyre.zre_msg_test(verbose)
        zyre.zyre_peer_test(verbose)
        zyre.zyre_group_test(verbose)
        zyre.zyre_node_test(verbose)
        zyre.zyre_event_test(verbose)
        zyre.zyre_test(verbose)
    end)
end)

local anonymous_cfg = [[
#   Configure server to allow anonymous access
#
security
    echo = I: server accepts anonymous access
    anonymous = 1
]]

local server_test_cfg = [[
#   Configure server for plain access
#
server
    monitor = 1             #   Check mount points
    heartbeat = 1           #   Heartbeat to clients

# publish
#     location = physicalpath
#     virtual = virtualpath
# publish
#     location = physicalpath
#     virtual = virtualpath

security
    echo = I: use guest/guest to login to server
    #   These are SASL mechanisms we accept
    anonymous = 0
    plain = 1
        account
            login = guest
            password = guest
            group = guest
        account
            login = super
            password = secret
            group = admin
]]

local client_test_cfg = [[
#   Configure server for plain access
#
client
    heartbeat = 1           #   Interval in seconds
    inbox = ./fmqroot/recv
    resync = 1

# inbox
#     path = ./some/directory
# subscribe
#     path = /logs

security
    plain
    login = guest
    password = guest
]]

describe("FileMQ module", function()
    io.open("anonymous.cfg", "w"):write(anonymous_cfg)
    io.open("server_test.cfg", "w"):write(server_test_cfg)
    io.open("client_test.cfg", "w"):write(client_test_cfg)
    it("should pass self test", function()
        local verbose = true
        filemq.fmq_msg_test(verbose)
        filemq.fmq_server_test(verbose)
        filemq.fmq_client_test(verbose)
    end)
end)
