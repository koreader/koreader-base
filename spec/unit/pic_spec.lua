local DrawContext = require("ffi/drawcontext")

--require "libs/libkoreader-pic"
--local Pic = pic
local Pic = require("ffi/pic")

local SAMPLE_JPG = "spec/base/unit/data/sample.jpg"

describe("Pic module", function()
	it("should load jpg file", function()
		local p = Pic.openDocument(SAMPLE_JPG)
		assert.are_not.equal(p, nil)
		p:close()
	end)
	describe("basic API", function()
		local p = Pic.openDocument(SAMPLE_JPG)
		local dc_null = DrawContext.new()

		it("should be able to get image size", function()
			assert.are.same({p:getOriginalPageSize()}, {313, 234, 3})
			page = p:openPage()
			assert.are_not.equal(page, nil)
			assert.are.same({page:getSize(dc_null)}, {313, 234})
			page:close()
		end)
		it("should return emtpy table of content", function()
			assert.are.same(p:getToc(), {})
		end)
		it("should return 1 on get number of pages", function()
			assert.are.same(p:getPages(), 1)
		end)
		it("should return 0 on get cache size", function()
			assert.are.same(p:getCacheSize(), 0)
		end)

		p:close()
	end)
end)
