describe("nnsvg library", function()
    it("should load libkoreader-nnsvg library", function()
        local NnSVG = require("libs/libkoreader-nnsvg")
        assert.are_not.equal(NnSVG, nil)
        assert.are_not.equal(NnSVG.new, nil)
    end)

    describe("NnSVG.new", function()
        it("should parse SVG image", function()
            local svg_file = "spec/base/unit/data/simple.svg"
            local NnSVG = require("libs/libkoreader-nnsvg")
            local svg_image = NnSVG.new(svg_file)
            local native_w, native_h = svg_image:getSize()
            assert.are.equal(native_w, 744)
            assert.are.equal(native_h, 1052)
        end)

    end)
end)
