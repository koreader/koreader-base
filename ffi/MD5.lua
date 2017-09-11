--[[--
MD5 hash library.

@module ffi.md5
]]

local ffi = require "ffi"
local bit = require "bit"
local bxor = bit.bxor
local bnot = bit.bnot
local band = bit.band
local bor = bit.bor
local rshift = bit.rshift
local lshift = bit.lshift
local copy = ffi.copy
local fill = ffi.fill

ffi.cdef[[
typedef struct MD5Context {
  uint32_t buf[4];
  uint32_t bits[2];
  unsigned char input[64];
} MD5_CTX;
]]

local function byteReverse(buf, len)
    -- TODO: implement for big-endian architectures?
end

local function F1(x, y, z) return bxor(z, band(x, bxor(y, z))) end
local function F2(x, y, z) return F1(z, x, y) end
local function F3(x, y, z) return bxor(x, y, z) end
local function F4(x, y, z) return bxor(y, bor(x, bnot(z))) end

local function MD5STEP(f, w, x, y, z, data, s)
    w = w + f(x, y, z) + data
    w = bor(lshift(w,s), rshift(w,(32-s)))
    w = w + x

    return w
end

-- Start MD5 accumulation.  Set bit count to 0 and buffer to mysterious
-- initialization constants.
local function MD5Init(ctx)
    ctx.buf[0] = 0x67452301
    ctx.buf[1] = 0xefcdab89
    ctx.buf[2] = 0x98badcfe
    ctx.buf[3] = 0x10325476

    ctx.bits[0] = 0
    ctx.bits[1] = 0
end

local function MD5Transform(buf, input)
    local a = buf[0]
    local b = buf[1]
    local c = buf[2]
    local d = buf[3]

    a = MD5STEP(F1, a, b, c, d, input[0] + 0xd76aa478, 7)
    d = MD5STEP(F1, d, a, b, c, input[1] + 0xe8c7b756, 12)
    c = MD5STEP(F1, c, d, a, b, input[2] + 0x242070db, 17)
    b = MD5STEP(F1, b, c, d, a, input[3] + 0xc1bdceee, 22)
    a = MD5STEP(F1, a, b, c, d, input[4] + 0xf57c0faf, 7)
    d = MD5STEP(F1, d, a, b, c, input[5] + 0x4787c62a, 12)
    c = MD5STEP(F1, c, d, a, b, input[6] + 0xa8304613, 17)
    b = MD5STEP(F1, b, c, d, a, input[7] + 0xfd469501, 22)
    a = MD5STEP(F1, a, b, c, d, input[8] + 0x698098d8, 7)
    d = MD5STEP(F1, d, a, b, c, input[9] + 0x8b44f7af, 12)
    c = MD5STEP(F1, c, d, a, b, input[10] + 0xffff5bb1, 17)
    b = MD5STEP(F1, b, c, d, a, input[11] + 0x895cd7be, 22)
    a = MD5STEP(F1, a, b, c, d, input[12] + 0x6b901122, 7)
    d = MD5STEP(F1, d, a, b, c, input[13] + 0xfd987193, 12)
    c = MD5STEP(F1, c, d, a, b, input[14] + 0xa679438e, 17)
    b = MD5STEP(F1, b, c, d, a, input[15] + 0x49b40821, 22)

    a = MD5STEP(F2, a, b, c, d, input[1] + 0xf61e2562, 5)
    d = MD5STEP(F2, d, a, b, c, input[6] + 0xc040b340, 9)
    c = MD5STEP(F2, c, d, a, b, input[11] + 0x265e5a51, 14)
    b = MD5STEP(F2, b, c, d, a, input[0] + 0xe9b6c7aa, 20)
    a = MD5STEP(F2, a, b, c, d, input[5] + 0xd62f105d, 5)
    d = MD5STEP(F2, d, a, b, c, input[10] + 0x02441453, 9)
    c = MD5STEP(F2, c, d, a, b, input[15] + 0xd8a1e681, 14)
    b = MD5STEP(F2, b, c, d, a, input[4] + 0xe7d3fbc8, 20)
    a = MD5STEP(F2, a, b, c, d, input[9] + 0x21e1cde6, 5)
    d = MD5STEP(F2, d, a, b, c, input[14] + 0xc33707d6, 9)
    c = MD5STEP(F2, c, d, a, b, input[3] + 0xf4d50d87, 14)
    b = MD5STEP(F2, b, c, d, a, input[8] + 0x455a14ed, 20)
    a = MD5STEP(F2, a, b, c, d, input[13] + 0xa9e3e905, 5)
    d = MD5STEP(F2, d, a, b, c, input[2] + 0xfcefa3f8, 9)
    c = MD5STEP(F2, c, d, a, b, input[7] + 0x676f02d9, 14)
    b = MD5STEP(F2, b, c, d, a, input[12] + 0x8d2a4c8a, 20)

    a = MD5STEP(F3, a, b, c, d, input[5] + 0xfffa3942, 4)
    d = MD5STEP(F3, d, a, b, c, input[8] + 0x8771f681, 11)
    c = MD5STEP(F3, c, d, a, b, input[11] + 0x6d9d6122, 16)
    b = MD5STEP(F3, b, c, d, a, input[14] + 0xfde5380c, 23)
    a = MD5STEP(F3, a, b, c, d, input[1] + 0xa4beea44, 4)
    d = MD5STEP(F3, d, a, b, c, input[4] + 0x4bdecfa9, 11)
    c = MD5STEP(F3, c, d, a, b, input[7] + 0xf6bb4b60, 16)
    b = MD5STEP(F3, b, c, d, a, input[10] + 0xbebfbc70, 23)
    a = MD5STEP(F3, a, b, c, d, input[13] + 0x289b7ec6, 4)
    d = MD5STEP(F3, d, a, b, c, input[0] + 0xeaa127fa, 11)
    c = MD5STEP(F3, c, d, a, b, input[3] + 0xd4ef3085, 16)
    b = MD5STEP(F3, b, c, d, a, input[6] + 0x04881d05, 23)
    a = MD5STEP(F3, a, b, c, d, input[9] + 0xd9d4d039, 4)
    d = MD5STEP(F3, d, a, b, c, input[12] + 0xe6db99e5, 11)
    c = MD5STEP(F3, c, d, a, b, input[15] + 0x1fa27cf8, 16)
    b = MD5STEP(F3, b, c, d, a, input[2] + 0xc4ac5665, 23)

    a = MD5STEP(F4, a, b, c, d, input[0] + 0xf4292244, 6)
    d = MD5STEP(F4, d, a, b, c, input[7] + 0x432aff97, 10)
    c = MD5STEP(F4, c, d, a, b, input[14] + 0xab9423a7, 15)
    b = MD5STEP(F4, b, c, d, a, input[5] + 0xfc93a039, 21)
    a = MD5STEP(F4, a, b, c, d, input[12] + 0x655b59c3, 6)
    d = MD5STEP(F4, d, a, b, c, input[3] + 0x8f0ccc92, 10)
    c = MD5STEP(F4, c, d, a, b, input[10] + 0xffeff47d, 15)
    b = MD5STEP(F4, b, c, d, a, input[1] + 0x85845dd1, 21)
    a = MD5STEP(F4, a, b, c, d, input[8] + 0x6fa87e4f, 6)
    d = MD5STEP(F4, d, a, b, c, input[15] + 0xfe2ce6e0, 10)
    c = MD5STEP(F4, c, d, a, b, input[6] + 0xa3014314, 15)
    b = MD5STEP(F4, b, c, d, a, input[13] + 0x4e0811a1, 21)
    a = MD5STEP(F4, a, b, c, d, input[4] + 0xf7537e82, 6)
    d = MD5STEP(F4, d, a, b, c, input[11] + 0xbd3af235, 10)
    c = MD5STEP(F4, c, d, a, b, input[2] + 0x2ad7d2bb, 15)
    b = MD5STEP(F4, b, c, d, a, input[9] + 0xeb86d391, 21)

    buf[0] = band(buf[0] + a, 0xFFFFFFFF)
    buf[1] = band(buf[1] + b, 0xFFFFFFFF)
    buf[2] = band(buf[2] + c, 0xFFFFFFFF)
    buf[3] = band(buf[3] + d, 0xFFFFFFFF)
end

local function MD5Update(ctx, buf, len)
    local t

    t = ctx.bits[0]
    ctx.bits[0] = t + lshift( len, 3)
    if (ctx.bits[0] < t) then
        ctx.bits[1] = ctx.bits[1] + 1
    end

    ctx.bits[1] = ctx.bits[1] + rshift(len, 29)

    t = band(rshift(t, 3), 0x3f)

    if (t > 0) then
        local p = ffi.cast("unsigned char *", ctx.input + t)

        t = 64 - t
        if (len < t) then
            copy(p, buf, len)
            return
        end

        copy(p, buf, t)
        byteReverse(ctx.input, 16)
        MD5Transform(ctx.buf, ffi.cast("uint32_t *", ctx.input))
        buf = buf + t
        len = len - t
    end

    while (len >= 64) do
        copy(ctx.input, buf, 64)
        byteReverse(ctx.input, 16)
        MD5Transform(ctx.buf, ffi.cast("uint32_t *", ctx.input))
        buf = buf + 64
        len = len - 64
    end

    copy(ctx.input, buf, len)
end

local function MD5Final(digest, ctx)

    local count
    local p

    count = band(rshift(ctx.bits[0], 3), 0x3F)

    p = ctx.input + count
    p[0] = 0x80
    p = p + 1
    count = 64 - 1 - count

    if (count < 8) then
        fill(p, count, 0)
        byteReverse(ctx.input, 16)
        MD5Transform(ctx.buf, ffi.cast("uint32_t *", ctx.input))
        fill(ctx.input, 56, 0)
    else
        fill(p, count - 8, 0)
    end

    byteReverse(ctx.input, 14)

    ffi.cast("uint32_t *", ctx.input)[14] = ctx.bits[0]
    ffi.cast("uint32_t *", ctx.input)[15] = ctx.bits[1]

    MD5Transform(ctx.buf, ffi.cast("uint32_t *", ctx.input))
    byteReverse(ffi.cast("unsigned char *",ctx.buf), 4)
    copy(digest, ctx.buf, 16)
    fill(ffi.cast("char *", ctx), ffi.sizeof(ctx), 0)
end

local hex = ffi.new("const char[16]", "0123456789abcdef")
local function bin2str(output, input, len)
    if len > 0 then
        output[0] = hex[rshift(input[0], 4)]
        output[1] = hex[band(input[0], 0xF)]
        return bin2str(output+2, input+1, len-1)
    end
end


local md5_proto = {}
md5_proto.__index = md5_proto

--- Feed content to md5 hashing instance.
---- @string luastr stream to process
function md5_proto:update(luastr)
    MD5Update(self.ctx, ffi.cast("const char*", luastr), #luastr)
end

--- Calcualte md5 sum with the state of a md5 hashing instance.
---- @string luastr stream to process
---- @treturn string md5 sum in Lua string
function md5_proto:sum(luastr)
    local buf = ffi.new("char[33]")
    local hash = ffi.new("uint8_t[16]")
    if luastr then
        self:update(luastr)
    end
    MD5Final(hash, self.ctx)

    bin2str(buf, hash, ffi.sizeof(hash))
    return ffi.string(buf)
end


local md5 = {}

--- Create a new md5 hashing instance.
---- @return md5 instance
function md5.new()
    local o = {}
    o.ctx = ffi.new("MD5_CTX")
    MD5Init(o.ctx)
    setmetatable(o, md5_proto)
    return o
end

--- Calcualte md5 sum.
---- @string luastr stream to process
---- @treturn string md5 sum in Lua string
function md5.sum(luastr)
    return md5:new():sum(luastr)
end

--- Calcualte md5 sum for a file.
---- @string filename
---- @treturn string md5 sum in Lua string
function md5.sumFile(filename)
    local m = md5.new()
    local fd, err = io.open(filename, "rb")
    if err ~= nil then
        return nil, err
    end
    while true do
        local bytes = fd:read(8192)
        if not bytes then
            fd:close()
            break
        end
        m:update(bytes)
    end
    return m:sum()
end

return md5
