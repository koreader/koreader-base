local Blitbuffer = require("ffi/blitbuffer")
local ffi = require("ffi")

describe("Blitbuffer unit tests", function()
    describe("Color conversion", function()
        -- 0xFF = 0b11111111
        -- 0xAA = 0b10101010
        -- 0x55 = 0b01010101
        local cRGB32 = Blitbuffer.ColorRGB32(0xFF, 0xAA, 0x55, 0)
        local cRGB24 = Blitbuffer.ColorRGB24(0xFF, 0xAA, 0x55)
        local cRGB24_32 = cRGB32:getColorRGB24()

        it("should convert RGB32 to RGB16", function()
            local c16_32 = cRGB32:getColorRGB16()
            assert.are.equals(0xFD4A, c16_32.v)
            assert.are.equal(c16_32:getR(), 0xFF) -- 0b11111 111
            assert.are.equal(c16_32:getG(), 0xAA) -- 0b101010 10
            assert.are.equal(c16_32:getB(), 0x52) -- 0b01010 010
        end)

        it("should convert RGB32 to gray8", function()
            local c8_32 = cRGB32:getColor8()
            assert.are.equals(0xB9, c8_32.a)
        end)

        it("should convert RGB32 to gray4 (lower nibble)", function()
            local c4l_32 = cRGB32:getColor4L()
            assert.are.equals(0x0B, c4l_32.a)
        end)

        it("should convert RGB32 to gray4 (upper nibble)", function()
            local c4u_32 = cRGB32:getColor4U()
            assert.are.equals(0xB0, c4u_32.a)
        end)
    end)

    describe("basic BB API", function()
        it("should create new buffer with correct width and length", function()
            local bb = Blitbuffer.new(100, 200)
            assert.are_not.equals(bb, nil)
            assert.are.equals(bb:getWidth(), 100)
            assert.are.equals(bb:getHeight(), 200)
        end)

        local bb = Blitbuffer.new(800, 600, Blitbuffer.TYPE_BB4)
        it("should set pixel correctly", function()
            local test_x = 15
            local test_y = 20
            local new_c = Blitbuffer.Color4(2)
            assert.are_not.equals(bb:getPixel(test_x, test_y)['a'], new_c['a'])
            bb:setPixel(test_x, test_y, new_c)
            assert.are.equals(bb:getPixel(test_x, test_y)['a'], new_c['a'])
        end)

        it("should do color comparison correctly", function()
            assert.True(Blitbuffer.Color4(122) == Blitbuffer.Color4(122))
            assert.True(Blitbuffer.Color4L(122) == Blitbuffer.Color4L(122))
            assert.True(Blitbuffer.Color4U(123) == Blitbuffer.Color4U(123))
            assert.True(Blitbuffer.Color8(127) == Blitbuffer.Color8(127))
            assert.True(Blitbuffer.ColorRGB24(128, 125, 123) ==
                        Blitbuffer.ColorRGB24(128, 125, 123))
            assert.True(Blitbuffer.ColorRGB32(128, 120, 123, 1) ==
                        Blitbuffer.ColorRGB32(128, 120, 123, 1))
        end)

        it("should do color comparison with conversion correctly", function()
            assert.True(Blitbuffer.Color8(127) ==
                        Blitbuffer.ColorRGB24(127, 127, 127))
            assert.True(Blitbuffer.Color8A(127, 100) ==
                        Blitbuffer.ColorRGB32(127, 127, 127, 100))
        end)

        it("should do color blending correctly", function()
            -- opaque
            local c = Blitbuffer.Color8(100)
            c:blend(Blitbuffer.Color8(200))
            assert.True(c == Blitbuffer.Color8(200))
            c = Blitbuffer.Color4U(0)
            c:blend(Blitbuffer.Color4U(4))
            assert.True(c == Blitbuffer.Color4U(4))
            c = Blitbuffer.Color4L(10)
            c:blend(Blitbuffer.Color4L(0))
            assert.True(c == Blitbuffer.Color4L(0))
            -- alpha
            c = Blitbuffer.Color8(100)
            c:blend(Blitbuffer.Color8A(200, 127))
            assert.True(c == Blitbuffer.Color8(149))
        end)

        it("should scale blitbuffer correctly", function()
            local bb = Blitbuffer.new(100, 100, Blitbuffer.TYPE_BBRGB24)
            local test_c1 = Blitbuffer.ColorRGB24(255, 128, 0)
            local test_c2 = Blitbuffer.ColorRGB24(128, 128, 0)
            local test_c3 = Blitbuffer.ColorRGB24(0, 128, 0)
            bb:setPixel(0, 0, test_c1)
            bb:setPixel(1, 0, test_c2)
            bb:setPixel(2, 0, test_c3)

            local scaled_bb = bb:scale(200, 200)
            assert.are.equals(scaled_bb:getWidth(), 200)
            assert.are.equals(scaled_bb:getHeight(), 200)
            assert.True(test_c1 == scaled_bb:getPixel(0, 0))
            assert.True(test_c1 == scaled_bb:getPixel(0, 1))
            assert.True(test_c1 == scaled_bb:getPixel(1, 0))
            assert.True(test_c1 == scaled_bb:getPixel(1, 1))

            assert.True(test_c2 == scaled_bb:getPixel(2, 0))
            assert.True(test_c2 == scaled_bb:getPixel(3, 0))
            assert.True(test_c2 == scaled_bb:getPixel(2, 1))
            assert.True(test_c2 == scaled_bb:getPixel(3, 1))

            scaled_bb = bb:scale(50, 50)
            assert.are.equals(scaled_bb:getWidth(), 50)
            assert.are.equals(scaled_bb:getHeight(), 50)

            assert.True(test_c1 == scaled_bb:getPixel(0, 0))
            assert.True(test_c3 == scaled_bb:getPixel(1, 0))
        end)

        it("should blit correctly", function()
            local bb1 = Blitbuffer.new(100, 100, Blitbuffer.TYPE_BBRGB24)
            local test_c1 = Blitbuffer.ColorRGB24(255, 128, 0)
            local test_c2 = Blitbuffer.ColorRGB24(128, 128, 0)
            local test_c3 = Blitbuffer.ColorRGB24(0, 128, 0)
            bb1:setPixel(0, 0, test_c1)
            bb1:setPixel(1, 0, test_c2)
            bb1:setPixel(2, 0, test_c3)
            assert.True(test_c1 == bb1:getPixel(0, 0))
            assert.True(test_c2 == bb1:getPixel(1, 0))
            assert.True(test_c3 == bb1:getPixel(2, 0))

            local test_c4 = Blitbuffer.ColorRGB24(0, 0, 0)
            local bb2 = Blitbuffer.new(100, 100, Blitbuffer.TYPE_BBRGB24)
            assert.True(test_c4 == bb2:getPixel(0, 0))
            assert.True(test_c4 == bb2:getPixel(1, 0))
            assert.True(test_c4 == bb2:getPixel(2, 0))

            bb2:addblitFrom(bb1, 0, 0, 0, 0, 100, 100, 1)
            assert.True(test_c1 == bb2:getPixel(0, 0))
            assert.True(test_c2 == bb2:getPixel(1, 0))
            assert.True(test_c3 == bb2:getPixel(2, 0))
        end)

    end)

    describe("BB rotation functionality", function()
        it("should get physical rect in all rotation modes", function()
            local bb = Blitbuffer.new(600, 800)
            bb:setRotation(0)
            assert.are_same({50, 100, 150, 200}, {bb:getPhysicalRect(50, 100, 150, 200)})
            bb:setRotation(1)
            assert.are_same({50, 100, 150, 200}, {bb:getPhysicalRect(100, 400, 200, 150)})
            bb:setRotation(2)
            assert.are_same({50, 100, 150, 200}, {bb:getPhysicalRect(400, 500, 150, 200)})
            bb:setRotation(3)
            assert.are_same({50, 100, 150, 200}, {bb:getPhysicalRect(500, 50, 200, 150)})
        end)

        it("should set pixel in all rotation modes", function()
            local width, height = 100, 200
            for rotation = 0, 3 do
                local bb = Blitbuffer.new(width, height)
                bb:setRotation(rotation)
                local w = rotation%2 == 1 and height or width
                local h = rotation%2 == 1 and width or height
                for i = 0, (h - 1) do
                    for j = 0, (w - 1) do
                        local color = Blitbuffer.Color4(2)
                        assert.are_not_same(color.a, bb:getPixel(j, i):getColor4L().a)
                        bb:setPixel(j, i, color)
                        assert.are_same(color.a, bb:getPixel(j, i):getColor4L().a)
                    end
                end
            end
        end)
    end)
end)

