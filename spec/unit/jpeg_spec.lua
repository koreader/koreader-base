local ffi = require("ffi")
require("ffi_wrapper")
local Jpeg = require("ffi/jpeg")
local C = ffi.C

require "ffi/posix_h"


local function readfile(fname)
    local fp = io.open(fname, "rb")
    local data = fp:read("*a")
    fp:close()
    return data
end

describe("Jpeg module", function()

    local ko_w, ko_h = 16, 16

    for n, format in pairs{
        [1] = "gray",
        [3] = "rgb",
    } do
        it("should load "..format.." bitmap from jpeg file", function()
            local bb, bb_w, bb_h, bb_n = Jpeg.openDocument("spec/base/unit/data/ko.rgb.jpg", n ~= 1)
            assert.are.same({ko_w, ko_h, n}, {bb_w, bb_h, bb_n})
            assert.are.equal(0, C.memcmp(bb.data, readfile("spec/base/unit/data/ko.rgb.jpg."..format), ko_w * ko_h * n))
        end)
    end

    for n, format in pairs{
        [3] = "rgb",
        [4] = "rgba",
    } do
        it("should write "..format.." bitmap to jpeg file", function()
            local data = readfile("spec/base/unit/data/ko."..format)
            local fn = os.tmpname()
            local ok, err = Jpeg.encodeToFile(fn, ffi.cast("uint8_t *", data), ko_w, ko_h, n, 100)
            if not ok then
                print(err)
            end
            assert.is_true(ok)
            local bb, bb_w, bb_h, bb_n = Jpeg.openDocument(fn, true)
            assert.are.same({ko_w, ko_h, 3}, {bb_w, bb_h, bb_n})
            assert.are.equal(0, C.memcmp(bb.data, readfile("spec/base/unit/data/ko.rgb.jpg.rgb"), ko_w * ko_h * 3))
            os.remove(fn)
        end)
    end

    for n, format in pairs{
        [1] = "gray",
        [3] = "rgb",
        [4] = "rgba",
    } do
        it("should write "..format.." bitmap to bmp file", function()
            local data = readfile("spec/base/unit/data/ko."..format)
            local fn = os.tmpname()
            local ok, err = Jpeg.writeBMP(fn, ffi.cast("uint8_t *", data), ko_w, ko_h, n)
            if not ok then
                print(err)
            end
            assert.is_true(ok)
            local actual = readfile(fn)
            local expect = readfile("spec/base/unit/data/ko."..(n == 1 and "gray" or "rgb")..".bmp")
            assert.are.equal(#expect, #actual)
            assert.are.equal(0, C.memcmp(actual, expect, #expect))
            os.remove(fn)
        end)
    end

end)
