local Blitbuffer = require("ffi/blitbuffer")
local ffi = require("ffi")

describe("Blitbuffer unit tests", function()
	describe("Color conversion", function()
		local cRGB32 = Blitbuffer.ColorRGB32(0xFF, 0xAA, 0x55, 0)
		local cRGB24 = Blitbuffer.ColorRGB24(0xFF, 0xAA, 0x55)
		local cRGB24_32 = cRGB32:getColorRGB24()

		it("should convert RGB32 to RGB16", function()
			local c16_32 = cRGB32:getColorRGB16()
			assert.are.equals(0xFD4A, c16_32.v)
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

