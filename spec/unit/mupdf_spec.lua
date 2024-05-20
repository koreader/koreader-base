local sample_pdf = "spec/base/unit/data/Alice.pdf"
local paper_pdf = "spec/base/unit/data/Paper.pdf"
local password_pdf = "spec/base/unit/data/testdocument.pdf"
local simple_pdf = "spec/base/unit/data/simple.pdf"
local simple_pdf_compare = "spec/base/unit/data/simple-out.pdf"
local simple_pdf_annotated_compare = "spec/base/unit/data/simple-out-annotated.pdf"
local simple_pdf_annotation_deleted_compare = "spec/base/unit/data/simple-out-annotation-deleted.pdf"
local test_img = "spec/base/unit/data/sample.jpg"
local jbig2_pdf = "spec/base/unit/data/2col.jbig2.pdf"
local aes_encrypted_zip = "spec/base/unit/data/encrypted-aes.zip"
local none_encrypted_zip = "spec/base/unit/data/encrypted-none.zip"
local plain_encrypted_zip = "spec/base/unit/data/encrypted-plain.zip"

describe("mupdf module", function()
    local M
    local md5

    setup(function()
        M = require("ffi/mupdf")
        md5 = require("ffi/MD5")
    end)

    it("should open and close PDFs", function()
        local doc = M.openDocument(sample_pdf)
        assert.is_not_nil(doc)
        doc:close()
    end)

    it("should open and close 1000 PDFs", function()
        local t = {}
        for i = 1, 1000 do
            t[i] = M.openDocument(sample_pdf)
            assert.is_not_nil(t[i])
            t[i]:close()
        end
    end)

    it("should render jbig2 PDFs", function()
        local doc = M.openDocument(jbig2_pdf)
        assert.is_not_nil(doc)
        local page = doc:openPage(1)
        local dc = require("ffi/drawcontext").new()
        local bb = require("ffi/blitbuffer").new(800, 600)
        page:draw(dc, bb, 0, 0)
        doc:close()
    end)

    describe("ZIP document API", function()
        local aes_encry_zip, none_encry_zip, plain_encry_zip
        setup(function()
            aes_encry_zip = M.openDocument(aes_encrypted_zip)
            none_encry_zip = M.openDocument(none_encrypted_zip)
            plain_encry_zip = M.openDocument(plain_encrypted_zip)
        end)
        teardown(function()
            aes_encry_zip:close()
            none_encry_zip:close()
            plain_encry_zip:close()
        end)
        it("should check password presence", function()
            assert.equals(aes_encry_zip:needsPassword(), true)
            assert.equals(none_encry_zip:needsPassword(), false)
            assert.equals(plain_encry_zip:needsPassword(), true)
        end)
        it("should not accept wrong password", function()
            assert.equals(aes_encry_zip:authenticatePassword("QWERTY"), false)
            assert.equals(aes_encry_zip:authenticatePassword("qwerty"), true)
            assert.equals(plain_encry_zip:authenticatePassword("QWERTY"), false)
            assert.equals(plain_encry_zip:authenticatePassword("qwerty"), true)
        end)
    end)

    describe("PDF document API", function()
        local doc1, doc2, doc3
        local ffi = require("ffi")
        local annotation_quadpoints = ffi.new("fz_quad[1]", {{
            { 70,  930, 510,  930 },
            { 510,  970, 70,  970 }
        }})
        setup(function()
            doc1 = M.openDocument(sample_pdf)
            assert.is_not_nil(doc1)
            doc2 = M.openDocument(paper_pdf)
            assert.is_not_nil(doc2)
            doc3 = M.openDocument(password_pdf)
            assert.is_not_nil(doc3)
        end)
        teardown(function()
            doc1:close()
            doc2:close()
            doc3:close()
        end)
        it("should check password presence", function()
            assert.equals(doc3:needsPassword(), true)
            assert.equals(doc2:needsPassword(), false)
        end)
        it("should not accept wrong password", function()
            assert.equals(doc3:authenticatePassword("bad"), false)
        end)
        it("should unlock document with correct password", function()
            assert.equals(doc3:authenticatePassword("test"), true)
        end)
        it("should return right number of pages", function()
            assert.equals(doc1:getPages(), 69)
        end)
        it("should read the table of contents (TOC)", function()
            assert.are.same(doc1:getToc(), {})
            assert.are.same(doc3:getToc(), {
                { ["page"] = 1, ["title"] = "Part 1", ["depth"] = 1 },
                { ["page"] = 1, ["title"] = "Subpart 1.1", ["depth"] = 2 },
                { ["page"] = 1, ["title"] = "Part 2", ["depth"] = 2 },
                { ["page"] = 1, ["title"] = "Subpart 2.1", ["depth"] = 2 },
                { ["page"] = 2, ["title"] = "Subpart 2.2", ["depth"] = 2 }
            })
        end)
        it("should open a page", function()
            assert.is_not_nil(doc3:openPage(1))
        end)
        it("should open a page 1000x", function()
            for i = 1, 1000 do
                assert.is_not_nil(doc3:openPage(1))
            end
        end)
        it("should open a page, add an annotation and write a new document", function()
            local doc = M.openDocument(simple_pdf)
            assert.is_not_nil(doc)
            local page = doc:openPage(1)
            assert.is_not_nil(page)
            page:addMarkupAnnotation(annotation_quadpoints, 1, ffi.C.PDF_ANNOT_HIGHLIGHT)
            page:close()
            local tmp_pdf = os.tmpname()
            doc:writeDocument(tmp_pdf)
            doc:close()
            assert.is_equal(
                md5.sumFile(tmp_pdf),
                md5.sumFile(simple_pdf_compare)
            )
            os.remove(tmp_pdf)
        end)
        it("should open a page, add an annotation, delete it again, and write a new document", function()
            local doc = M.openDocument(simple_pdf)
            assert.is_not_nil(doc)
            local page = doc:openPage(1)
            assert.is_not_nil(page)
            local tmp_pdf = os.tmpname()
            doc:writeDocument(tmp_pdf)
            page:addMarkupAnnotation(annotation_quadpoints, 1, ffi.C.PDF_ANNOT_HIGHLIGHT)
            local annot = page:getMarkupAnnotation(annotation_quadpoints, 1)
            page:deleteMarkupAnnotation(annot)
            page:close()
            doc:writeDocument(tmp_pdf)
            doc:close()
            assert.is_equal(
                md5.sumFile(tmp_pdf),
                md5.sumFile(simple_pdf_annotation_deleted_compare)
            )
            os.remove(tmp_pdf)
        end)
        it("should open a page, add contents to an existing annotation and write a new document", function()
            local doc = M.openDocument(simple_pdf_compare)
            assert.is_not_nil(doc)
            local page = doc:openPage(1)
            assert.is_not_nil(page)
            local annot = page:getMarkupAnnotation(annotation_quadpoints, 1)
            page:updateMarkupAnnotation(annot, "annotation contents")
            page:close()
            local tmp_pdf = os.tmpname()
            doc:writeDocument(tmp_pdf)
            doc:close()
            assert.is_equal(
                md5.sumFile(tmp_pdf),
                md5.sumFile(simple_pdf_annotated_compare)
            )
            os.remove(tmp_pdf)
        end)

        describe("PDF page API", function()
            local page
            local dc
            setup(function()
                doc3:authenticatePassword("test")
                page = doc3:openPage(2)
                dc = require("ffi/drawcontext").new()
            end)
            teardown(function()
            page:close()
            end)
            it("should get page size", function()
                assert.are.same({page:getSize(dc)}, {612, 792})
            end)
            it("should get used bbox of page", function()
                local bbox = {page:getUsedBBox()}
                -- floating point values without proper expression
                assert.equals(math.floor(bbox[1]*1000), 56145)
                assert.equals(math.floor(bbox[2]*1000), 69233)
                assert.equals(math.floor(bbox[3]*1000), 144790)
                assert.equals(math.floor(bbox[4]*1000), 103669)
            end)
            it("should get page text", function()
                local text = page:getPageText()
                assert.equals(#text, 2)
                assert.equals(#text[2], 2)
                assert.equals(text[2][2].word, "there!")
                -- floating point values via FFI, integers in old API:
                assert.equals(math.floor(text[2][2].x0), 71)
                assert.equals(math.floor(text[2][2].x1), 99)
                assert.equals(math.floor(text[2][2].y0), 91)
                assert.equals(math.floor(text[2][2].y1), 105)
            end)
            it("should get page hyperlinks", function()
                local links = doc3:openPage(1):getPageLinks()
                assert.equals(#links, 2)
                assert.equals(links[1].uri, "https://www.google.com/")
                assert.equals(links[2].page, 1)
                assert.equals(math.floor(links[2].x0), 237)
                assert.equals(math.floor(links[2].x1), 328)
                assert.equals(math.floor(links[2].y0), 559)
                assert.equals(math.floor(links[2].y1), 573)
            end)
            describe("k2pdfopt reflow API", function()
                local koptcontext
                setup(function()
                    koptcontext = require("ffi/koptcontext").new()
                    koptcontext:setBBox(page:getUsedBBox())
                end)
                it("should get a page picture", function()
                    page:getPagePix(koptcontext)
                end)
            end)
        end)
    end)
    describe("image API", function()
        it("should render an image", function()
            local img = M.renderImageFile(test_img)
            assert.is_not_nil(img)
            img:free()
        end)
        it("should render an image, 10 times", function()
            for i = 1, 10 do
                local img = M.renderImageFile(test_img)
                assert.is_not_nil(img)
                img:free()
            end
        end)
        it("should render an image, 1000 times", function()
            for i = 1, 1000 do
                local img = M.renderImageFile(test_img)
                assert.is_not_nil(img)
                img:free()
            end
        end)
    end)
end)
