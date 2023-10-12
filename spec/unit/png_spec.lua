local ffi = require("ffi")
require("ffi_wrapper")
local BB = require("ffi/blitbuffer")
local Png = require("ffi/png")

describe("Png module", function()
    it("should write bitmap to png file", function()
        local re, ok
        local fn = os.tmpname()
        local w, h = 400, 600
        local bb = BB.new(w, h, BB.TYPE_BBRGB32)
        bb:setPixel(0, 0, BB.ColorRGB32(128, 128, 128, 0))
        bb:setPixel(200, 300, BB.ColorRGB32(10, 128, 205, 50))
        bb:setPixel(400, 100, BB.ColorRGB32(120, 28, 25, 255))

        local cdata = ffi.C.malloc(w * h * 4)
        local mem = ffi.cast("unsigned char*", cdata)
        for x = 0, w-1 do
            for y = 0, h-1 do
                local c = bb:getPixel(x, y):getColorRGB32()
                local offset = 4 * w * y + 4 * x
                mem[offset] = c.r
                mem[offset + 1] = c.g
                mem[offset + 2] = c.b
                mem[offset + 3] = c.alpha
            end
        end

        ok = Png.encodeToFile(fn, mem, w, h, 4)
        ffi.C.free(cdata)
        assert.are.same(ok, true)

        ok, re = Png.decodeFromFile(fn, 4)
        assert.are.same(ok, true)
        local bb2 = BB.new(re.width, re.height, BB.TYPE_BBRGB32, re.data)
        bb2:setAllocated(1)
        local c = bb2:getPixel(0, 0)
        assert.are.same({0x80, 0x80, 0x80, 0}, {c.r, c.g, c.b, c.alpha})
        c = bb2:getPixel(200, 200)
        assert.are.same({0, 0, 0, 0}, {c.r, c.g, c.b, c.alpha})
        c = bb2:getPixel(200, 300)
        assert.are.same({10, 128, 205, 50}, {c.r, c.g, c.b, c.alpha})
        c = bb2:getPixel(400, 100)
        assert.are.same({120, 28, 25, 255}, {c.r, c.g, c.b, c.alpha})
        os.remove(fn)
    end)
end)
