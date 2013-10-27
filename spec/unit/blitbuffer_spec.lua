local Blitbuffer = require("ffi/blitbuffer")
local ffi = require("ffi")

describe("Blitbuffer unit tests", function()
	describe("Color conversion", function()
		local cRGB32 = Blitbuffer.ColorRGB32(0xFF, 0xAA, 0x55, 0)
		local cRGB24 = Blitbuffer.ColorRGB24(0xFF, 0xAA, 0x55)
		local cRGB24_32 = cRGB32:getColorRGB24()

		it("should convert RGB32 to gray16", function()
			local c16_32 = cRGB32:getColor16()
			assert.are.equals(c16_32.a, 0xAAAA)
		end)

		it("should convert RGB32 to RGB16", function()
			local cRGB16_32 = cRGB32:getColorRGB16()
			assert.are.equals(cRGB16_32.v, 0x7EAA)
		end)

		it("should convert RGB32 to gray8", function()
			local c8_32 = cRGB32:getColor8()
			assert.are.equals(c8_32.a, 0xAA)
		end)

		it("should convert RGB32 to gray4 (lower nibble)", function()
			local c4l_32 = cRGB32:getColor4L()
			assert.are.equals(c4l_32.a, 0x0A)
		end)

		it("should convert RGB32 to gray4 (upper nibble)", function()
			local c4u_32 = cRGB32:getColor4U()
			assert.are.equals(c4u_32.a, 0xA0)
		end)
	end)

	describe("basic BB API", function()
		it("should create new buffer with correct width and length", function()
			local bb = Blitbuffer.new(100, 200)
			assert.are_not.equals(bb, nil)
			assert.are.equals(bb:getWidth(), 100)
			assert.are.equals(bb:getHeight(), 200)
		end)

		local bb = Blitbuffer.new(800, 600)
		it("should set pixel correctly", function()
			local test_x = 15
			local test_y = 20
			local new_c = Blitbuffer.Color4(2)
			assert.are_not.equals(bb:getPixel(test_x, test_y)['a'], new_c['a'])
			bb:setPixel(test_x, test_y, new_c)
			assert.are.equals(bb:getPixel(test_x, test_y)['a'], new_c['a'])
		end)
	end)
end)

