local ffi = require("ffi")
local KOPTContext = require("ffi/koptcontext")
local k2pdfopt = ffi.load("libs/libk2pdfopt.so.2")

local sample_pdf = "spec/unit/data/Alice.pdf"
local paper_pdf = "spec/unit/data/Paper.pdf"

describe("KOPTContext module", function()
	it("should be created", function()
		local kc = KOPTContext.new()
		assert.is_not_nil(kc)
	end)
	describe("set/get API", function()
		it("should set/get wrap", function()
			local kc = KOPTContext.new()
			for wrap = 0, 1 do
				kc:setWrap(wrap)
				assert.equals(kc:getWrap(), wrap)
			end
		end)
		it("should set/get trim", function()
			local kc = KOPTContext.new()
			for trim = 0, 1 do
				kc:setTrim(trim)
				assert.equals(kc:getTrim(), trim)
			end
		end)
		it("should set/get zoom", function()
			local kc = KOPTContext.new()
			for zoom = 0.2, 2.0, 0.2 do
				kc:setZoom(zoom)
				assert.equals(kc:getZoom(), zoom)
			end
		end)
		it("should set/get BBox", function()
			local kc = KOPTContext.new()
			local bbox = {10, 20, 500, 400}
			kc:setBBox(unpack(bbox))
			assert.are.same({kc:getBBox()}, bbox)
		end)
		it("should set/get language", function()
			local kc = KOPTContext.new()
			local lang = "eng"
			kc:setLanguage(lang)
			assert.are.same(kc:getLanguage(), lang)
		end)
	end)
	it("should copy bmp from other context", function()
		local kc1 = KOPTContext.new()
		assert.are.same({kc1.dst.width, kc1.dst.height}, {0, 0})
		local kc2 = KOPTContext.new()
		k2pdfopt.bmpmupdf_pdffile_to_bmp(kc2.dst, ffi.cast("char*", sample_pdf), 1, 300, 8)
		kc1:copyDestBMP(kc2)
		assert.are_not.same({kc1.dst.width, kc1.dst.height}, {0, 0})
		assert.are.same({kc1.dst.width, kc1.dst.height}, {kc2.dst.width, kc2.dst.height})
	end)
	it("should be used as reflowing context", function()
		local kc = KOPTContext.new()
		k2pdfopt.bmpmupdf_pdffile_to_bmp(kc.src, ffi.cast("char*", sample_pdf), 2, 300, 8)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		assert(kc.dst.size_allocated ~= 0)
		assert.are_not.same({kc.dst.width, kc.dst.height}, {0, 0})
	end)
	it("should get larger reflowed page with larger original page", function()
		local kc1 = KOPTContext.new()
		local kc2 = KOPTContext.new()
		k2pdfopt.bmpmupdf_pdffile_to_bmp(kc1.src, ffi.cast("char*", sample_pdf), 2, 167, 8)		
		k2pdfopt.bmpmupdf_pdffile_to_bmp(kc2.src, ffi.cast("char*", sample_pdf), 2, 300, 8)
		k2pdfopt.k2pdfopt_reflow_bmp(kc1)
		k2pdfopt.k2pdfopt_reflow_bmp(kc2)
		assert(kc1.dst.height < kc2.dst.height)
	end)
	it("should get reflowed word boxes", function()
		local kc = KOPTContext.new()
		k2pdfopt.bmpmupdf_pdffile_to_bmp(kc.src, ffi.cast("char*", sample_pdf), 3, 300, 8)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		local boxes = kc:getReflowedWordBoxes(0, 0, kc.dst.width, kc.dst.height)
		for i = 1, #boxes do
			for j = 1, #boxes[i] do
				local box = boxes[i][j]
				assert.are_not_nil(box.x0, box.y0, box.x1, box.y1)
			end
		end
	end)
	it("should get native word boxes", function()
		local kc = KOPTContext.new()
		k2pdfopt.bmpmupdf_pdffile_to_bmp(kc.src, ffi.cast("char*", sample_pdf), 4, 300, 8)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		local boxes = kc:getNativeWordBoxes(0, 0, kc.dst.width, kc.dst.height)
		for i = 1, #boxes do
			for j = 1, #boxes[i] do
				local box = boxes[i][j]
				assert.are_not_nil(box.x0, box.y0, box.x1, box.y1)
			end
		end
	end)
	it("should transform native postion to reflowed position", function()
		local kc = KOPTContext.new()
		k2pdfopt.bmpmupdf_pdffile_to_bmp(kc.src, ffi.cast("char*", sample_pdf), 5, 300, 8)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		for j = 0, 800, 100 do
			for i = 0, 600, 100 do
				local x, y = kc:nativeToReflowPosTransform(i, j)
				assert.are_not_nil(x, y)
			end
		end
	end)
	it("should transform reflow postion to native position", function()
		local kc = KOPTContext.new()
		k2pdfopt.bmpmupdf_pdffile_to_bmp(kc.src, ffi.cast("char*", sample_pdf), 5, 300, 8)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		for j = 0, 800, 100 do
			for i = 0, 600, 100 do
				local x, y = kc:reflowToNativePosTransform(i, j, 0.5, 0.5)
				assert.are_not_nil(x, y)
			end
		end
	end)
	it("should get OCR word from tesseract OCR engine", function()
		local kc = KOPTContext.new()
		k2pdfopt.bmpmupdf_pdffile_to_bmp(kc.src, ffi.cast("char*", sample_pdf), 5, 300, 8)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		local word = kc:getTOCRWord(280, 40, 100, 40, "data", "eng", 3, 0, 0)
		assert.are_same(word, "Alice")
		kc:freeOCR()
	end)
	it("should free dst bitmap after reflowing", function()
		local kc = KOPTContext.new()
		k2pdfopt.bmpmupdf_pdffile_to_bmp(kc.src, ffi.cast("char*", sample_pdf), 6, 300, 8)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		assert(kc.dst.size_allocated ~= 0)
		kc:free()
		assert(kc.dst.size_allocated == 0)
	end)
	it("should get list of page regions", function()
		local kc = KOPTContext.new()
		k2pdfopt.bmpmupdf_pdffile_to_bmp(kc.dst, ffi.cast("char*", paper_pdf), 1, 300, 8)
		kc.page_width, kc.page_height = kc.dst.width, kc.dst.height
		local regions = kc:getPageRegions()
		for i = 1, #regions do
			assert(regions[i].x1 - regions[i].x0 <= 1)
			assert(regions[i].y1 - regions[i].y0 <= 1)
		end
	end)
end)
