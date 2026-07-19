local ffi = require("ffi")
require("ffi_wrapper")
local Png = require("ffi/png")
local C = ffi.C

require "ffi/posix_h"


local function readfile(fname)
    local fp = io.open(fname, "rb")
    local data = fp:read("*a")
    fp:close()
    return data
end

describe("Png module", function()

    local ko_w, ko_h = 16, 16
    local ko_samples = {
        [1] = "gray",
        [2] = "graya",
        [3] = "rgb",
        [4] = "rgba",
    }

    for n, format in pairs(ko_samples) do

        local sample = "spec/base/unit/data/ko."..format

        it("should load "..format.." bitmap from png file", function()
            local ok, re = Png.decodeFromFile(sample..".png", n)
            if not ok then
                print(re)
            end
            assert.is_true(ok)
            assert.are.same({ko_w, ko_h, n}, {re.width, re.height, re.ncomp})
            assert.are.equal(0, C.memcmp(re.data, readfile(sample), re.width * re.height * re.ncomp))
        end)

        it("should write "..format.." bitmap to png file", function()
            local data = readfile(sample)
            assert(#data == ko_w * ko_h * n)
            local fn = os.tmpname()
            local ok, err = Png.encodeToFile(fn, data, ko_w, ko_h, n)
            if not ok then
                print(err)
            end
            assert.is_true(ok)
            local re
            ok, re = Png.decodeFromFile(fn, n)
            if not ok then
                print(re)
            end
            assert.is_true(ok)
            assert.are.same({ko_w, ko_h, n}, {re.width, re.height, re.ncomp})
            assert.are.equal(0, C.memcmp(re.data, data, re.width * re.height * re.ncomp))
            os.remove(fn)
        end)
    end

end)
