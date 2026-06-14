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
    return o
end

function NetInfo:free()
    if self.nl then
        self.nl:close()
        self.nl = nil
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
            print(string.format("\tssid: %s", iface.ssid))
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

local Netlink = require "ffi/netlink"

function NetInfo:_iface_ssid(ifa_index)
    local nl = self.nl
    if not nl then
        nl = Netlink:new():connect()
        self.nl = nl
    end
    nl:new_message(nl:get_family_id("nl80211"), C.NL80211_CMD_GET_SCAN, true)
    nl:put_u32(C.NL80211_ATTR_IFINDEX, ifa_index)
    for msg_type, attrs_data, attrs_size in nl:send():receive() do
        local associated, ssid
        for nla_type, nla_data, nla_size in nl.iter_attrs(attrs_data, attrs_size) do
            if nla_type ~= C.NL80211_ATTR_BSS then
                goto continue
            end
            for bss_nla_type, bss_nla_data, bss_nla_size in Netlink.iter_attrs(nla_data, nla_size) do
                if bss_nla_type == C.NL80211_BSS_INFORMATION_ELEMENTS then
                    while bss_nla_size > 0 do
                        local iehdr = ffi.cast("struct iehdr *", bss_nla_data)
                        if iehdr.id == C.EID_SSID then
                            ssid = ffi.string(bss_nla_data + C.SIZEOF_IEHDR, iehdr.len)
                            break
                        end
                        bss_nla_data = bss_nla_data + iehdr.len + C.SIZEOF_IEHDR
                        bss_nla_size = bss_nla_size - iehdr.len - C.SIZEOF_IEHDR
                    end
                elseif bss_nla_type == C.NL80211_BSS_STATUS then
                    assert(bss_nla_size == 4)
                    local status = ffi.cast("uint32_t *", bss_nla_data)[0]
                    associated = status == C.NL80211_BSS_STATUS_ASSOCIATED
                end
            end
            ::continue::
        end
        if associated and ssid then
            return ssid
        end
    end
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
    iface.wireless = C.access("/sys/class/net/" .. iface.name .. "/wireless/", C.F_OK) == 0
    if not iface.wireless then
        return iface
    end
    local ok, err = pcall(self._iface_ssid, self, iface.index)
    if not ok then
        io.stderr:write("retrieving ssid with netlink failed: " .. err)
        return iface
    end
    iface.ssid = err
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
