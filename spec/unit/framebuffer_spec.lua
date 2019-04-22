describe("Framebuffer unit tests", function()
    local fb

    setup(function()
        fb = require("ffi/framebuffer_dummy"):new{
            dummy = true,
            device = {
                device_dpi = 167,
            }
        }
    end)

    it("should set & update DPI", function()
        assert.are.equals(160, fb:getDPI())

        fb:setDPI(120)
        assert.are.equals(120, fb:getDPI())

        fb:setDPI(60)
        assert.are.equals(60, fb:getDPI())
    end)

    it("should scale by DPI", function()
        fb:setDPI(167)
        assert.are.equals(31, fb:scaleBySize(30))

        fb:setDPI(167 * 3)
        assert.are.equals(62, fb:scaleBySize(30))
    end)
end)
