local Freetype = require("ffi/freetype")

describe("Freetype module", function()
    it("should create new face without error", function()
        ok, face = pcall(Freetype.newFace, './fonts/droid/DroidSansMono.ttf',
                         18)
        assert.True(ok)
        assert.are_not.equals(face, nil)
    end)
end)
