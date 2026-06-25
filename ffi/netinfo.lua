local bit = require "bit"
local ffi = require "ffi"
local C = ffi.C
local posix = require "ffi/posix"

-- Misc {{{

local function getifaddrs()
    local ifaddr = ffi.new("struct ifaddrs *[1]")
    if C.getifaddrs(ifaddr) == -1 then
        io.stderr:write("getifaddrs() failed: " .. posix.strerror())
        return function() end
    end
    ifaddr = ffi.gc(ifaddr[0], C.freeifaddrs)
    local ifa_next = ifaddr
    return function()
        local ifa = ifa_next
        if ifa == nil then
            C.freeifaddrs(ffi.gc(ifaddr, nil))
            return
        end
        ifa_next = ifa.ifa_next
        return ifa
    end
end

local function format_mac(mac)
    return string.format("%02X:%02X:%02X:%02X:%02X:%02X",
                         bit.band(mac[0], 0xFF),
                         bit.band(mac[1], 0xFF),
                         bit.band(mac[2], 0xFF),
                         bit.band(mac[3], 0xFF),
                         bit.band(mac[4], 0xFF),
                         bit.band(mac[5], 0xFF))
end

-- }}}

-- NetInfo {{{

local NetInfo = {}

function NetInfo:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.nl = nil
    self.sd = nil
    return o
end

function NetInfo:free()
    if self.nl then
        self.nl:close()
        self.nl = nil
    end
    if self.sd then
        C.close(self.sd)
        self.sd = nil
    end
end

function NetInfo:dump()
    for __, iface in ipairs(self:retrieve()) do
        print(string.format("%d:\t%s", iface.index, iface.name))
        print(string.format("\tmac: %s", iface.mac))
        if iface.ipv4 then
            print(string.format("\tipv4: %s", iface.ipv4))
        end
        if iface.ipv6 then
            print(string.format("\tipv6: %s", iface.ipv6))
        end
        if iface.wireless then
            print(string.format("\tssid: %s", iface.ssid or "off/any"))
        end
    end
end

function NetInfo:retrieve()
    local interfaces = {}
    local ipv4 = {}
    local ipv6 = {}
    for ifa in getifaddrs() do
        if ifa.ifa_addr == nil or
            bit.band(ifa.ifa_flags, C.IFF_UP) == 0 or
            bit.band(ifa.ifa_flags, C.IFF_LOOPBACK) ~= 0 then
            goto continue
        end
        if ifa.ifa_addr.sa_family == C.AF_INET or ifa.ifa_addr.sa_family == C.AF_INET6 then
            local host = ffi.new("char[?]", C.NI_MAXHOST)
            local addrlen = ffi.sizeof("struct sockaddr_" .. (ifa.ifa_addr.sa_family == C.AF_INET and "in" or "in6"))
            local ret = C.getnameinfo(ifa.ifa_addr, addrlen, host, C.NI_MAXHOST, nil, 0, C.NI_NUMERICHOST)
            if ret ~= 0 then
                io.stderr:write("getnameinfo() failed: " .. ffi.string(C.gai_strerror(ret)))
            else
                local ipvt = ifa.ifa_addr.sa_family == C.AF_INET and ipv4 or ipv6
                local name = ffi.string(ifa.ifa_name)
                local ip = ffi.string(host)
                if not ipvt[name] then
                    ipvt[name] = ip
                else
                    ipvt[name] = ipvt[name] .. " / " .. ip
                end
            end
        else
            local iface = self:_process_ifaddr(ifa)
            if iface then
                table.insert(interfaces, iface)
            end
        end
        ::continue::
    end
    for __, iface in ipairs(interfaces) do
        iface.ipv4 = ipv4[iface.name]
        iface.ipv6 = ipv6[iface.name]
    end
    table.sort(interfaces, function(i1, i2) return i1.index < i2.index end)
    return interfaces
end

if ffi.os == "Linux" then -- {{{

function NetInfo:_iface_ssid_ioctl(iface)
    local sd = self.sd
    if not sd then
        sd = C.socket(C.AF_INET, bit.bor(C.SOCK_DGRAM, C.SOCK_CLOEXEC), C.IPPROTO_IP)
        if sd < 0 then
            error(string.format("socket(AF_INET) failed: %s", posix.strerror()))
        end
        self.sd = sd
    end
    local essid = ffi.new("char[?]", C.IW_ESSID_MAX_SIZE + 1)
    local iwr = ffi.new("struct iwreq")
    assert(#iface.name <= C.IFNAMSIZ)
    ffi.copy(iwr.ifr_ifrn.ifrn_name, iface.name)
    iwr.u.essid.pointer = ffi.cast("caddr_t", essid)
    iwr.u.essid.length = C.IW_ESSID_MAX_SIZE + 1
    iwr.u.essid.flags = 0
    if C.ioctl(sd, C.SIOCGIWESSID, iwr) ~= 0 then
        error(string.format("ioctl(SIOCGIWESSID) failed: %s", posix.strerror()))
    end
    return iwr.u.data.flags ~= 0 and ffi.string(essid) or nil
end

function NetInfo:_process_ifaddr(ifa)
    if ifa.ifa_addr.sa_family ~= C.AF_PACKET then
        return
    end
    local sll = ffi.cast("struct sockaddr_ll *", ifa.ifa_addr)
    if sll.sll_ifindex == 0 then
        return
    end
    assert(sll.sll_halen == 6)
    assert(ifa.ifa_name ~= nil)
    local iface = {
        name = ffi.string(ifa.ifa_name),
        index = sll.sll_ifindex,
        mac = format_mac(sll.sll_addr),
    }
    iface.wireless = (
        C.access("/sys/class/net/" .. iface.name .. "/phy82011/", C.F_OK) == 0 or
        C.access("/sys/class/net/" .. iface.name .. "/wireless/", C.F_OK) == 0
    )
    if not iface.wireless then
        return iface
    end
    local ok, err = pcall(self._iface_ssid_ioctl, self, iface)
    if ok then
        iface.ssid = err
    else
        io.stderr:write(string.format("retrieving ssid [%s, ioctl] failed: %s\n", iface.name, err))
    end
    return iface
end

end -- }}}

if ffi.os == "macos" then -- {{{

function NetInfo:_process_ifaddr(ifa)
    if ifa.ifa_addr.sa_family ~= C.AF_LINK then
        return
    end
    local sdl = ffi.cast("struct sockaddr_dl *", ifa.ifa_addr)
    if sdl.sdl_index == 0 or sdl.sdl_type ~= C.IFT_ETHER then
        return
    end
    assert(sdl.sdl_alen == 6)
    assert(ifa.ifa_name ~= nil)
    local iface = {
        name = ffi.string(ifa.ifa_name),
        index = sdl.sdl_index,
        mac = format_mac(sdl.sdl_data + sdl.sdl_nlen),
    }
    --[[
    TODO:
    - how to check if the interface is wireless?
    - unfortunately, retrieving SSID on modern version is not possible without location permission
    ]]
    return iface
end

end -- }}}

return NetInfo

-- vim: foldmethod=marker foldlevel=0
