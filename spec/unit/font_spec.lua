require("ffi_wrapper")
local ffi = require("ffi")

describe("Low level font interfaces", function()
    it("FreeType and HarfBuzz FFI should work", function()
        assert.has_no.errors(function()
            -- HL wrappers are omitted deliberately - faster bisect in case those fail, but we don't.
            local ft = ffi.loadlib("freetype", "6")
            require("ffi/freetype_h")
            local hb = require("ffi/harfbuzz")

            -- This font is deliberately "odd" - raw ttf data - to test that both can see it the same
            local font = "spec/base/unit/data/testfont.ttf"
            local nglyphs = 15

            -- First try with HB
            local fontdata = io.open(font, "rb"):read("*a")
            local blob = hb.hb_blob_create(fontdata, #fontdata, hb.HB_MEMORY_MODE_READONLY, nil, nil)
            local face = hb.hb_face_create(blob, 0)
            hb.hb_blob_destroy(blob)
            assert.are.equals(hb.hb_face_get_glyph_count(face), nglyphs)
            hb.hb_face_destroy(face)

            -- Then with FT
            local ftlibp = ffi.new("FT_Library[1]")
            local facep = ffi.new("FT_Face[1]")
            ft.FT_Init_FreeType(ftlibp)
            ft.FT_New_Face(ftlibp[0], font, 0, facep)
            assert.are.equals(facep[0].num_glyphs, nglyphs)

            -- Try to turn the FT face into HB face
            face = hb.hb_ft_face_create_referenced(facep[0])
            ft.FT_Done_Face(facep[0])

            -- Check if it works
            assert.are.equals(hb.hb_face_get_glyph_count(face), nglyphs)
            hb.hb_face_destroy(face)
            --ft.FT_Done_FreeType(ftlibp[0])
        end)
    end)
end)

