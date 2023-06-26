require("ffi_wrapper")
local Freetype = require("ffi/freetype")

describe("Freetype module", function()
    it("should create new face size without error", function()
        assert.has_no.errors(function()
            local ftsize = Freetype.newFaceSize('./fonts/droid/DroidSansMono.ttf', 18)
            assert.are_not.equals(ftsize, nil)
        end)
    end)
end)
