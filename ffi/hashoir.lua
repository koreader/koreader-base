local ffi = require("ffi")
require "ffi/xxhash_h"

local xxhash = ffi.loadlib("xxhash", "0")

local Hashoir = {}

function Hashoir:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.hs = ffi.gc(xxhash.XXH3_createState(), xxhash.XXH3_freeState)
    assert(o.hs ~= nil)
    xxhash.XXH3_64bits_reset(o.hs)
    return o
end

function Hashoir:free()
    xxhash.XXH3_freeState(ffi.gc(self.hs, nil))
    self.hs = nil
end

function Hashoir:reset()
    xxhash.XXH3_64bits_reset(self.hs)
    return self
end

function Hashoir:update(ptr, len)
    xxhash.XXH3_64bits_update(self.hs, ptr, len)
    return self
end

function Hashoir:digest()
    return xxhash.XXH3_64bits_digest(self.hs)
end

function Hashoir:hexdigest()
    return string.format("%016x", xxhash.XXH3_64bits_digest(self.hs))
end

return Hashoir
