--[[--
MuPDF API

This is a FFI wrapper for what was a Lua-based API in the past.
There are no longer FFI C wrappers, all goes straight from cdef.

M is the underlying ffi of mupdf. This is safe only
for functions that never fz_throw(). Usually only stuff
that doesn't accept fz_context as first parameter.

fz_context has special metatype wrapper, which turns
ctx:fz_method(...) into M.fz_method(ctx, ...). Furthermore,
it translates mupdf exceptions into lua error().

So if you want to check for thrown error, you must do

ok, ret = pcall(function()
    return ctx:fz_may_throw(...)
end)

Don't do pcall(M.fz_may_throw, ...) as that does NOT install
the exception wrapper, and lua may crash later in unrelated
section if mupdf throws, making things harder to debug.

The pcall idiom above should be used only when you need to clean up
something on error to prevent memory leaks. error() thrown
by wrapper for everything else is handled by whomever is calling us.

@module ffi.mupdf
--]]

local ffi = require("ffi")
require("ffi/mupdf_h")
require("ffi/posix_h") -- for malloc

local BlitBuffer = require("ffi/blitbuffer")

local M = require("libs/libkoreader-mupdf")

--- @fixme: Don't make cache_size too low, at least not until we bump MµPDF,
---         as there's a pernicious issue that corrupts its store cache on overcommit on old versions.
---         c.f., https://github.com/koreader/koreader/issues/7627
---         (FZ_STORE_DEFAULT is 256MB, we used to set it to 8MB).
---         And when we bump MµPDF, it'll likely have *more* stuff to store in there,
--          so, don't make that too low, period ;).
--          NOTE: Revisit when we bump MµPDF by doing a few tests with the tracing memory allocators,
--                as even 32MB is likely to be too conservative.
local mupdf = {
    debug_memory = false,
    cache_size = 32*1024*1024,
    color = false,
}

local document_mt = { __index = {} }
local page_mt = { __index = {} }

mupdf.debug = function() --[[ no debugging by default ]] end


local save_ctx = nil
-- provides an fz_context for mupdf
local function context()
    if save_ctx ~= nil then return save_ctx end

    local ctx = M.fz_new_context_imp(
        -- TODO: mupdf.debug_memory and M.mupdf_get_my_alloc_context() or nil,
	nil,
        nil,
        mupdf.cache_size, nil)

    if ctx == nil then
        error("cannot create fz_context for MuPDF")
    end
    -- ctx is a cdata<fz_context *>, attach a finalizer to it to release ressources on garbage collection
    ctx = ffi.gc(ctx, mupdf.fz_context_gc)

    M.fz_install_external_font_funcs(ctx)
    M.fz_register_document_handlers(ctx)

    save_ctx = ctx
    return ctx
end

-- a wrapper for mupdf exception error messages
local function merror(message)
    if context() ~= nil then
        error(string.format("%s: %s (%d)", message,
            ffi.string(W.mupdf_error_message(context())),
            W.mupdf_error_code(context())))
    else
        error(message)
    end
end

--
function mupdf.fz_context_gc(ctx)
    if ctx ~= nil then
        M.fz_drop_context(ctx)
    end
end

--[[--
Opens a document.
--]]
function mupdf.openDocument(filename)
    local mupdf_doc = {
        doc = ctx:fz_open_document(filename),
        filename = filename,
        ctx = ctx,
    }

    if mupdf_doc.doc == nil then
        merror("MuPDF cannot open file.")
    end

    -- doc is a cdata<fz_document *>, attach a finalizer to it to release ressources on garbage collection
    mupdf_doc.doc = ffi.gc(mupdf_doc.doc, mupdf.fz_document_gc)

    setmetatable(mupdf_doc, document_mt)

    return mupdf_doc
end

function mupdf.openDocumentFromText(text, magic)
    local stream = W.mupdf_open_memory(context(), ffi.cast("const unsigned char*", text), #text)
    local mupdf_doc = {
        doc = ctx:fz_open_document_with_stream(magic, stream),
        ctx = ctx,
    }
    ctx:fz_drop_stream(stream)

    -- doc is a cdata<fz_document *>, attach a finalizer to it to release ressources on garbage collection
    mupdf_doc.doc = ffi.gc(mupdf_doc.doc, mupdf.fz_document_gc)

    setmetatable(mupdf_doc, document_mt)

    return mupdf_doc
end

-- Document functions:

--[[
close the document

this is done automatically by the garbage collector but can be
triggered explicitly
--]]
function document_mt.__index:close()
    if self.doc ~= nil then
        M.fz_drop_document(context(), self.doc)
        -- Clear the cdata finalizer to avoid a double-free
        self.doc = ffi.gc(self.doc, nil)
        self.doc = nil

        -- Clear the context, too, in order to release memory *now*.
        --- @note: This is mostly for testing the store memory corruption issues investigated in #7627.
        ---        Otherwise, keeping the context around makes sense,
        ---        as we use MµPDF in more places than simply as a Document engine...
        --[[
        if save_ctx then
            print("MuPDF:close dropping context", save_ctx)
            M.fz_drop_context(save_ctx)
            -- Clear the cdata finalizer to avoid a double-free
            save_ctx = ffi.gc(save_ctx, nil)
            save_ctx = nil
        end
        --]]
    end
end

function mupdf.fz_document_gc(doc)
    if doc ~= nil then
        M.fz_drop_document(context(), doc)
    end
end

--[[
check if the document needs a password for access
--]]
function document_mt.__index:needsPassword()
    return self.ctx:fz_needs_password(self.doc) ~= 0
end

--[[
try to authenticate with a password
--]]
function document_mt.__index:authenticatePassword(password)
    if self.ctx:fz_authenticate_password(self.doc, password) == 0 then
        return false
    end
    return true
end

--[[
read number of pages in document
--]]
function document_mt.__index:getPages()
    -- cache number of pages
    if self.number_of_pages then return self.number_of_pages end

    local pages = self.ctx:fz_count_pages(self.doc)
    self.number_of_pages = pages

    return pages
end

function document_mt.__index:isDocumentReflowable()
    if self.is_reflowable then return self.is_reflowable end
    self.is_reflowable = self.ctx:fz_is_document_reflowable(self.doc) == 1
    return self.is_reflowable
end

function document_mt.__index:layoutDocument(width, height, em)
    -- Reset the cache.
    self.number_of_pages = nil

    self.ctx:fz_layout_document(self.doc, width, height, em)
end

local function toc_walker(toc, outline, depth)
    while outline ~= nil do
        table.insert(toc, {
            page = outline.page + 1,
            title = ffi.string(outline.title),
            depth = depth,
        })
        if outline.down then
            toc_walker(toc, outline.down, depth+1)
        end
        outline = outline.next
    end
end

--[[
read table of contents (ToC)

Returns a table like this:
{
    {page=12, depth=1, title="chapter1"},
    {page=54, depth=1, title="chapter2"},
}

Returns an empty table when there is no ToC
--]]
function document_mt.__index:getToc()
    local toc = {}
    local outline = self.ctx:fz_load_outline(self.doc)
    if outline ~= nil then
        toc_walker(toc, outline, 1)
        self.ctx:fz_drop_outline(outline)
    end
    return toc
end

--[[
open a page, return page object
--]]
function document_mt.__index:openPage(number)
    local mupdf_page = {
        page = self.ctx:fz_load_page(self.doc, number-1),
        number = number,
        doc = self,
        ctx = self.ctx,
    }

    if mupdf_page.page == nil then
        merror("cannot open page #" .. number)
    end

    -- page is a cdata<fz_page *>, attach a finalizer to it to release ressources on garbage collection
    mupdf_page.page = ffi.gc(mupdf_page.page, mupdf.fz_page_gc)

    setmetatable(mupdf_page, page_mt)

    return mupdf_page
end

--[[
Get one metadata info entry, return string
--]]
function document_mt.__index:getMetadataInfo(info)
    local buf = ffi.new("char[?]", 255)
    local res = self.ctx:fz_lookup_metadata(self.doc, info, buf, 255)
    if res > -1 then
        return ffi.string(buf, res)
    end
    return ""
end


--[[
Get metadata, return object
--]]
function document_mt.__index:getMetadata()
    local metadata = {
        title = self:getMetadataInfo("info:Title"),
        author = self:getMetadataInfo("info:Author"),
        subject = self:getMetadataInfo("info:Subject"),
        keywords = self:getMetadataInfo("info:Keywords"),
        creator = self:getMetadataInfo("info:Creator"),
        producer = self:getMetadataInfo("info:Producer"),
        creationDate = self:getMetadataInfo("info:CreationDate"),
        modDate = self:getMetadataInfo("info:ModDate")
    }

    return metadata
end

--[[
return currently claimed memory by MuPDF

This will return sensible values only when the debug_memory flag is set
--]]
function document_mt.__index:getCacheSize()
    if mupdf.debug_memory then
        return 0
        --TODO: W.mupdf_get_cache_size()
    else
        return 0
    end
end

function document_mt.__index:cleanCache()
    -- NOP, just for API compatibility
end

--[[
write the document to a new file
--]]
function document_mt.__index:writeDocument(filename)
    local opts = ffi.new("pdf_write_options[1]")
    opts[0].do_incremental = (filename == self.filename ) and 1 or 0
    opts[0].do_ascii = 0
    opts[0].do_garbage = 0
    opts[0].do_linear = 0
    --opts[0].continue_on_error = 1
    self.ctx:pdf_save_document(ffi.cast("pdf_document*", self.doc), filename, opts)
end


-- Page functions:

--[[
explicitly close the page object

this is done implicitly by garbage collection, too.
--]]
function page_mt.__index:close()
    if self.page ~= nil then
        M.fz_drop_page(context(), self.page)
        -- Clear the cdata finalizer to avoid a double-free
        self.page = ffi.gc(self.page, nil)
        self.page = nil
    end
end

function mupdf.fz_page_gc(page)
    if page ~= nil then
        M.fz_drop_page(context(), page)
    end
end

--[[
calculate page size after applying DrawContext
--]]
function page_mt.__index:getSize(draw_context)
    local ctm = M.fz_scale(draw_context.zoom, draw_context.zoom)
    ctm = M.fz_pre_rotate(ctm, draw_context.rotate)

    -- Roygbyte: not sure, this might be supplied wrong arguments? drop bounds?
    M.fz_bound_page(context(), self.page, bounds)
    M.fz_transform_rect(bounds, ctm)

    -- NOTE: fz_bound_page returns an internal representation computed @ 72dpi...
    --       It is often superbly mysterious, even for images,
    --       so we do *NOT* want to round it right now,
    --       as it would introduce rounding errors much too early in the pipeline...
    -- NOTE: ReaderZooming uses it to compute the scale factor, where accuracy matters!
    -- NOTE: This is also used in conjunction with getUsedBBox,
    --       which also returns precise, floating point rectangles!
    --[[
    M.fz_round_rect(bbox, bounds)
    return bbox[0].x1-bbox[0].x0, bbox[0].y1-bbox[0].y0
    --]]

    return bounds[0].x1 - bounds[0].x0, bounds[0].y1 - bounds[0].y0
end

--[[
check which part of the page actually contains content
--]]
function page_mt.__index:getUsedBBox()
    local result = ffi.new("fz_rect[1]")

    local dev = self.ctx:fz_new_bbox_device(result)
    local ok, err = pcall(function()
        return self.ctx:fz_run_page(self.page, dev, M.fz_identity, nil)
    end)
    self.ctx:fz_close_device(dev)
    self.ctx:fz_drop_device(dev)
    if not ok then error(err) end

    return result[0].x0, result[0].y0, result[0].x1, result[0].y1
end

local C = string.byte
local function is_unicode_wspace(c)
    return c == 9 or --  TAB
        c == 0x0a or --  HT
        c == 0x0b or --  LF
        c == 0x0c or --  VT
        c == 0x0d or --  FF
        c == 0x20 or --  CR
        c == 0x85 or --  NEL
        c == 0xA0 or --  No break space
        c == 0x1680 or --  Ogham space mark
        c == 0x180E or --  Mongolian Vowel Separator
        c == 0x2000 or --  En quad
        c == 0x2001 or --  Em quad
        c == 0x2002 or --  En space
        c == 0x2003 or --  Em space
        c == 0x2004 or --  Three-per-Em space
        c == 0x2005 or --  Four-per-Em space
        c == 0x2006 or --  Five-per-Em space
        c == 0x2007 or --  Figure space
        c == 0x2008 or --  Punctuation space
        c == 0x2009 or --  Thin space
        c == 0x200A or --  Hair space
        c == 0x2028 or --  Line separator
        c == 0x2029 or --  Paragraph separator
        c == 0x202F or --  Narrow no-break space
        c == 0x205F or --  Medium mathematical space
        c == 0x3000 --  Ideographic space
end
local function is_unicode_bullet(c)
    -- Not all of them are strictly bullets, but will do for our usage here
    return c == 0x2022 or --  Bullet
        c == 0x2023 or --  Triangular bullet
        c == 0x25a0 or --  Black square
        c == 0x25cb or --  White circle
        c == 0x25cf or --  Black circle
        c == 0x25e6 or --  White bullet
        c == 0x2043 or --  Hyphen bullet
        c == 0x2219 or --  Bullet operator
        c == 149 or --  Ascii bullet
        c == C'*'
end

local function skip_starting_bullet(line)
    local ch = line.first_char
    local found_bullet = false

    while ch ~= nil do
        if is_unicode_bullet(ch.c) then
            found_bullet = true
        elseif not is_unicode_wspace(ch.c) then
            break
        end

        ch = ch.next
    end

    if found_bullet then
        return ch
    else
        return line.first_char
    end
end

--[[
get the text of the given page

will return text in a Lua table that is modeled after
djvu.c creates this table.

note that the definition of "line" is somewhat arbitrary
here (for now)

MuPDFs API provides text as single char information
that is collected in "spans". we use a span as a "line"
in Lua output and segment spans into words by looking
for space characters.

will return an empty table if we have no text
--]]
function page_mt.__index:getPageText()
    -- first, we run the page through a special device, the text_device
    local text_page = self.ctx:fz_new_stext_page_from_page(self.page, nil)

    -- now we analyze the data returned by the device and bring it
    -- into the format we want to return
    local lines = {}

    local block = text_page.first_block
    while block ~= nil do
        if block.type == M.FZ_STEXT_BLOCK_TEXT then
            -- a block contains lines, which is our primary return datum
            local mupdf_line = block.u.t.first_line
            while mupdf_line ~= nil do
                local line = {}
                local line_bbox = ffi.new("fz_rect")

                local first_char = skip_starting_bullet( mupdf_line )
                local ch = first_char
                local ch_len = 0
                while ch ~= nil do
                    ch = ch.next
                    ch_len = ch_len + 1
                end

                if ch_len > 0 then
                    -- here we will collect UTF-8 chars before making them
                    -- a Lua string:
                    local textbuf = ffi.new("char[?]", ch_len * 4)

                    ch = first_char
                    while ch ~= nil do
                        local textlen = 0
                        local word_bbox = ffi.new("fz_rect")
                        while ch ~= nil do
                            if is_unicode_wspace(ch.c) then
                                -- ignore and end word
                                break
                            end
                            textlen = textlen + M.fz_runetochar(textbuf + textlen, ch.c)
                            local bbox = M.fz_rect_from_quad(ch.quad)
                            word_bbox = M.fz_union_rect(word_bbox, bbox)
                            line_bbox = M.fz_union_rect(line_bbox, bbox)
                            if ch.c >= 0x4e00 and ch.c <= 0x9FFF or -- CJK Unified Ideographs
                                ch.c >= 0x2000 and ch.c <= 0x206F or -- General Punctuation
                                ch.c >= 0x3000 and ch.c <= 0x303F or -- CJK Symbols and Punctuation
                                ch.c >= 0x3400 and ch.c <= 0x4DBF or -- CJK Unified Ideographs Extension A
                                ch.c >= 0xF900 and ch.c <= 0xFAFF or -- CJK Compatibility Ideographs
                                ch.c >= 0xFF01 and ch.c <= 0xFFEE or -- Halfwidth and Fullwidth Forms
                                ch.c >= 0x20000 and ch.c <= 0x2A6DF  -- CJK Unified Ideographs Extension B
                            then
                                -- end word
                                break
                            end
                            ch = ch.next
                        end
                        -- add word to line
                        table.insert(line, {
                            word = ffi.string(textbuf, textlen),
                            x0 = word_bbox.x0, y0 = word_bbox.y0,
                            x1 = word_bbox.x1, y1 = word_bbox.y1,
                        })

                        if ch == nil then
                            break
                        end

                        ch = ch.next
                    end

                    line.x0, line.y0 = line_bbox.x0, line_bbox.y0
                    line.x1, line.y1 = line_bbox.x1, line_bbox.y1

                    table.insert(lines, line)
                end

                mupdf_line = mupdf_line.next
            end
        end

        block = block.next
    end

    self.ctx:fz_drop_stext_page(text_page)

    return lines
end

--[[
Get a list of the Hyperlinks on a page
--]]
function page_mt.__index:getPageLinks()
    local page_links = self.ctx:fz_load_links(self.page)
    -- do not error out when page_links == NULL, since there might
    -- simply be no links present.

    local links = {}

    local link = page_links
    while link ~= nil do
        local data = {
            x0 = link.rect.x0, y0 = link.rect.y0,
            x1 = link.rect.x1, y1 = link.rect.y1,
        }
        local resolved_link = self.ctx:fz_resolve_link(link.doc, link.uri, nil, nil)
        if resolved_link.page >= 0 then
            data.page = resolved_link.page -- FIXME page+1?
            data.chapter = resolved_link.chapter -- can be of some used for faster seek eventually
        else
            data.uri = ffi.string(link.uri)
        end
        table.insert(links, data)
        link = link.next
    end

    self.ctx:fz_drop_link(page_links)

    return links
end

local function run_page(page, pixmap, ctm)
    page.ctx:fz_clear_pixmap_with_value(pixmap, 0xff)

    local dev = page.ctx:fz_new_draw_device(M.fz_identity, pixmap)

    local ok, err = pcall(function()
       return page.ctx:fz_run_page(page.page, dev, ctm, nil)
    end)
    page.ctx:fz_close_device(dev)
    page.ctx:fz_drop_device(dev)
    if not ok then error(err) end
end
--[[
render page to blitbuffer

old interface: expects a blitbuffer to render to
--]]
function page_mt.__index:draw(draw_context, blitbuffer, offset_x, offset_y)
    local buffer = self:draw_new(draw_context, blitbuffer:getWidth(), blitbuffer:getHeight(), offset_x, offset_y)
    blitbuffer:blitFrom(buffer)
    buffer:free()
end
--[[
render page to blitbuffer

new interface: creates the blitbuffer with the rendered data and returns that
TODO: make this the used interface
--]]
function page_mt.__index:draw_new(draw_context, width, height, offset_x, offset_y)
    local ctm = M.fz_scale(draw_context.zoom, draw_context.zoom)
    ctm = M.fz_pre_rotate(ctm, draw_context.rotate)
    ctm = M.fz_pre_translate(ctm, draw_context.offset_x, draw_context.offset_y)

    local bbox = ffi.new("fz_irect")
    bbox.x0 = offset_x
    bbox.y0 = offset_y
    bbox.x1 = offset_x + width
    bbox.y1 = offset_y + height

    local bb = BlitBuffer.new(width, height, mupdf.color and BlitBuffer.TYPE_BBRGB32 or BlitBuffer.TYPE_BB8)

    local colorspace = mupdf.color and self.ctx:fz_device_rgb()
        or self.ctx:fz_device_gray()
    if mupdf.bgr and mupdf.color then
        colorspace = self.ctx:fz_device_bgr()
    end
    local pix = self.ctx:fz_new_pixmap_with_bbox_and_data(
        colorspace, bbox, nil, mupdf.color and 1 or 0, ffi.cast("unsigned char*", bb.data))

    run_page(self, pix, ctm)

    if draw_context.gamma >= 0.0 then
        self.ctx:fz_gamma_pixmap(pix, draw_context.gamma)
    end

    self.ctx:fz_drop_pixmap(pix)

    return bb
end

function page_mt.__index:addMarkupAnnotation(points, n, type)
    local color = ffi.new("float[3]")
    local alpha = 1.0
    if type == M.PDF_ANNOT_HIGHLIGHT then
        color[0] = 1.0
        color[1] = 1.0
        color[2] = 0.0
        alpha = 0.5
    elseif type == M.PDF_ANNOT_UNDERLINE then
        color[0] = 0.0
        color[1] = 0.0
        color[2] = 1.0
    elseif type == M.PDF_ANNOT_STRIKE_OUT then
        color[0] = 1.0
        color[1] = 0.0
        color[2] = 0.0
    else
        return
    end

    local doc = M.pdf_specifics(context(), self.doc.doc)
    if doc == nil then merror("could not get pdf_specifics") end

    local annot = W.mupdf_pdf_create_annot(context(), ffi.cast("pdf_page*", self.page), type)
    if annot == nil then merror("could not create annotation") end

    local ok = W.mupdf_pdf_set_annot_quad_points(context(), annot, n, points)
    if ok == nil then merror("could not set markup annot quadpoints") end

    ok = W.mupdf_pdf_set_markup_appearance(context(), doc, annot, color, alpha, line_thickness, line_height)
    if ok == nil then merror("could not set markup appearance") end

    -- Fetch back MuPDF's stored coordinates of all quadpoints, as they may have been modified/rounded
    -- (we need the exact ones that were saved if we want to be able to find them for deletion/update)
    for i = 0, n-1 do
        W.mupdf_pdf_annot_quad_point(context(), annot, i, points+i*8)
    end
end

function page_mt.__index:deleteMarkupAnnotation(annot)
    local ok = W.mupdf_pdf_delete_annot(context(), ffi.cast("pdf_page*", self.page), annot)
    if ok == nil then merror("could not delete markup annotation") end
end

function page_mt.__index:getMarkupAnnotation(points, n)
    local doc = M.pdf_specifics(context(), self.doc.doc)
    if doc == nil then merror("could not get pdf_specifics") end

    local annot = W.mupdf_pdf_first_annot(context(), ffi.cast("pdf_page*", self.page))
    while annot ~= nil do
        local n2 = W.mupdf_pdf_annot_quad_point_count(context(), annot)
        if n == n2 then
            local quadpoint = ffi.new("float[?]", 8)
            local match = true
            for i = 0, n-1 do
                W.mupdf_pdf_annot_quad_point(context(), annot, i, quadpoint)
                for k = 0, 7 do
                    if points[i*8 + k] ~= quadpoint[k] then
                        match = false
                        break
                    end
                end
                if not match then break end
            end
            if match then return annot end
        end
        annot = W.mupdf_pdf_next_annot(context(), annot)
    end
    return nil
end

function page_mt.__index:updateMarkupAnnotation(annot, contents)
    local doc = M.pdf_specifics(context(), self.doc.doc)
    if doc == nil then merror("could not get pdf_specifics") end
    local ok = W.mupdf_pdf_set_annot_contents(context(), annot, contents)
    if ok == nil then merror("could not update markup annot contents") end
end

-- image loading via MuPDF:

local function doRenderImage(image, width, height)
    local ctx = context()
    local ok, pixmap = pcall(function()
        return ctx:fz_get_pixmap_from_image(image, nil, nil, nil, nil)
    end)
    ctx:fz_drop_image(image)
    if not ok then error(pixmap) end

    local p_width = pixmap.w
    local p_height = pixmap.h
    -- mupdf_get_pixmap_from_image() may not scale image to the
    -- width and height provided, so check and scale it if needed
    if width and height then
        -- Ensure we pass integer values for width & height to fz_scale_pixmap(),
        -- because it enforces an alpha channel otherwise...
        width = math.floor(width)
        height = math.floor(height)
        if p_width ~= width or p_height ~= height then
            local ok2, scaled_pixmap = pcall(function()
                return ctx:fz_scale_pixmap(pixmap, 0, 0, width, height, nil)
            end)
            ctx:fz_drop_pixmap(pixmap)
            if not ok2 then error(scaled_pixmap) end
            pixmap = scaled_pixmap
            p_width = pixmap.w
            p_height = pixmap.h
        end
    end
    local bbtype
    local ncomp = pixmap.n
    if ncomp == 1 then bbtype = BlitBuffer.TYPE_BB8
    elseif ncomp == 2 then bbtype = BlitBuffer.TYPE_BB8A
    elseif ncomp == 3 then bbtype = BlitBuffer.TYPE_BBRGB24
    elseif ncomp == 4 then bbtype = BlitBuffer.TYPE_BBRGB32
    else error("unsupported number of color components")
    end
    -- Handle RGB->BGR conversion for Kobos when needed
    local bb
    if mupdf.bgr and ncomp >= 3 then
        local ok2, bgr_pixmap = pcall(function()
            return ctx:fz_convert_pixmap(pixmap, ctx:fz_device_bgr(), nil, nil, M.fz_default_color_params, (ncomp == 4 and 1 or 0))
        end)
        ctx:fz_drop_pixmap(pixmap)
        if not ok2 then error(bgr_pixmap) end

        local p = bgr_pixmap.samples
        bb = BlitBuffer.new(p_width, p_height, bbtype, p):copy()
        ctx:fz_drop_pixmap(bgr_pixmap)
    else
        -- TODO: For large pixmaps, avoid this copy by extending BB_mt.__index:free to allow for registered destructors
        local p = pixmap.samples
        bb = BlitBuffer.new(p_width, p_height, bbtype, p):copy()
        ctx:fz_drop_pixmap(pixmap)
    end
    return bb
end

--[[--
Renders image data.
--]]
function mupdf.renderImage(data, size, width, height)
    local ctx = context()
    local buffer = ctx:fz_new_buffer_from_shared_data(ffi.cast("unsigned char*", data), size)
    local ok, image = pcall(function()
        return ctx:fz_new_image_from_buffer(buffer)
    end)
    ctx:fz_drop_buffer(buffer)
    if not ok then error(image) end
    return doRenderImage(image)
end

--- Renders image file.
function mupdf.renderImageFile(filename, width, height)
    return doRenderImage(context():fz_new_image_from_file(filename), width, height)
end

--[[--
Scales a blitbuffer.

Quality of scaling done by MuPDF is better than the one done in blitbuffer.lua
(see fz_scale_pixmap_cached() in mupdf/source/fitz/draw-scale-simple.c).
Same arguments as BlitBuffer:scale() for easy replacement.
--]]
function mupdf.scaleBlitBuffer(bb, width, height)
    local ctx = context()
    -- We need first to convert our BlitBuffer to a pixmap
    local orig_w, orig_h = bb:getWidth(), bb:getHeight()
    local bbtype = bb:getType()
    local colorspace
    local converted_bb
    local alpha
    local stride = bb.stride
    -- MuPDF should know how to handle *most* of our BB types,
    -- special snowflakes excluded (4bpp & RGB565),
    -- in which case we feed it a temporary copy in the closest format it'll understand.
    if bbtype == BlitBuffer.TYPE_BB8 then
        colorspace = ctx:fz_device_gray()
        alpha = 0
    elseif bbtype == BlitBuffer.TYPE_BB8A then
        colorspace = ctx:fz_device_gray()
        alpha = 1
    elseif bbtype == BlitBuffer.TYPE_BBRGB24 then
        if mupdf.bgr then
            colorspace = ctx:fz_device_bgr()
        else
            colorspace = ctx:fz_device_rgb()
        end
        alpha = 0
    elseif bbtype == BlitBuffer.TYPE_BBRGB32 then
        if mupdf.bgr then
            colorspace = ctx:fz_device_bgr()
        else
            colorspace = ctx:fz_device_rgb()
        end
        alpha = 1
    elseif bbtype == BlitBuffer.TYPE_BB4 then
        converted_bb = BlitBuffer.new(orig_w, orig_h, BlitBuffer.TYPE_BB8)
        converted_bb:blitFrom(bb, 0, 0, 0, 0, orig_w, orig_h)
        bb = converted_bb -- we don't free() the provided bb, but we'll have to free our converted_bb
        colorspace = ctx:fz_device_gray()
        alpha = 0
        stride = orig_w
    else
        converted_bb = BlitBuffer.new(orig_w, orig_h, BlitBuffer.TYPE_BBRGB32)
        converted_bb:blitFrom(bb, 0, 0, 0, 0, orig_w, orig_h)
        bb = converted_bb -- we don't free() the provided bb, but we'll have to free our converted_bb
        if mupdf.bgr then
            colorspace = ctx:fz_device_bgr()
        else
            colorspace = ctx:fz_device_rgb()
        end
        alpha = 1
    end
    -- We can now create a pixmap from this bb of correct type
    local pixmap = ctx:fz_new_pixmap_with_data(colorspace,
                    orig_w, orig_h, nil, alpha, stride, ffi.cast("unsigned char*", bb.data))
    -- We can now scale the pixmap
    -- Better to ensure we give integer width and height, to avoid a black 1-pixel line at right and bottom of image.
    -- Also, fz_scale_pixmap enforces an alpha channel if w or h are floats...
    local scaled_pixmap = ctx:fz_scale_pixmap(pixmap, 0, 0, math.floor(width), math.floor(height), nil)
    ctx:fz_drop_pixmap(pixmap) -- free our original pixmap
    if scaled_pixmap == nil then
        if converted_bb then converted_bb:free() end -- free our home made bb
        error("could not create scaled pixmap from pixmap")
    end
    local p_width = scaled_pixmap.w
    local p_height = scaled_pixmap.h
    -- And convert the pixmap back to a BlitBuffer
    bbtype = nil
    local ncomp = scaled_pixmap.n
    if ncomp == 1 then bbtype = BlitBuffer.TYPE_BB8
    elseif ncomp == 2 then bbtype = BlitBuffer.TYPE_BB8A
    elseif ncomp == 3 then bbtype = BlitBuffer.TYPE_BBRGB24
    elseif ncomp == 4 then bbtype = BlitBuffer.TYPE_BBRGB32
    else
        if converted_bb then converted_bb:free() end -- free our home made bb
        error("unsupported number of color components")
    end
    local p = scaled_pixmap.samples
    bb = BlitBuffer.new(p_width, p_height, bbtype, p):copy()
    ctx:fz_drop_pixmap(scaled_pixmap)
    if converted_bb then converted_bb:free() end -- free our home made bb
    return bb
end

-- k2pdfopt interfacing

-- will lazily load ffi/koptcontext.lua in order to interface k2pdfopt
local cached_k2pdfopt
local function get_k2pdfopt()
    if cached_k2pdfopt then return cached_k2pdfopt end

    local koptcontext = require("ffi/koptcontext")
    cached_k2pdfopt = koptcontext.k2pdfopt
    return cached_k2pdfopt
end

-- lazily load libpthread
local cached_pthread
local function get_pthread()
    if cached_pthread then return cached_pthread end

    local util = require("ffi/util")

    require("ffi/pthread_h")

    local ok
    if ffi.os == "Windows" then
        return ffi.load("libwinpthread-1.dll")
    elseif util.isAndroid() then
        -- pthread directives are in Bionic library on Android
        ok, cached_pthread = pcall(ffi.load, "libc.so")
        if ok then return cached_pthread end
    else
        -- Kobo devices strangely have no libpthread.so in LD_LIBRARY_PATH
        -- so we hardcode the libpthread.so.0 here just for Kobo.
        for _, libname in ipairs({"pthread", "libpthread.so.0"}) do
            ok, cached_pthread = pcall(ffi.load, libname)
            if ok then return cached_pthread end
        end
    end
end

--[[
the following function is a reimplementation of what can be found
in libk2pdfopt/willuslib/bmpmupdf.c
k2pdfopt supports only 8bit and 24bit "bitmaps" - and mupdf will give
only 8bit+8bit alpha or 24bit+8bit alpha pixmaps. So we need to convert
what we get from mupdf.
--]]
local function bmpmupdf_pixmap_to_bmp(bmp, pixmap)
    local k2pdfopt = get_k2pdfopt()

    bmp.width = pixmap.w
    bmp.height = pixmap.h
    local ncomp = pixmap.n
    local p = pixmap.samples
    if ncomp == 2 or ncomp == 4 then
        k2pdfopt.pixmap_to_bmp(bmp, p, ncomp)
    else
        error("unsupported pixmap format for conversion to bmp")
    end
end

local function render_for_kopt(bmp, page, scale, bounds)
    local k2pdfopt = get_k2pdfopt()

    local ctm = M.fz_scale(scale, scale)
    bounds = M.fz_transform_rect(bounds, ctm)
    local bbox = M.fz_round_rect(bounds)

    local ctx = page.ctx
    local colorspace = mupdf.color and ctx:fz_device_rgb() or ctx:fz_device_gray()
    if mupdf.bgr and mupdf.color then
        colorspace = ctx:fz_device_bgr()
    end
    local pix = ctx:fz_new_pixmap_with_bbox(colorspace, bbox, nil, 1)

    run_page(page, pix, ctm)

    k2pdfopt.bmp_init(bmp)

    bmpmupdf_pixmap_to_bmp(bmp, pix)

    ctx:fz_drop_pixmap(pix)
end

function page_mt.__index:reflow(kopt_context)
    local k2pdfopt = get_k2pdfopt()

    local bounds = ffi.new("fz_rect")
    bounds.x0 = kopt_context.bbox.x0
    bounds.y0 = kopt_context.bbox.y0
    bounds.x1 = kopt_context.bbox.x1
    bounds.y1 = kopt_context.bbox.y1
    -- probe scale
    local zoom = kopt_context.zoom * kopt_context.quality
    bounds = M.fz_transform_rect(bounds, M.fz_identity) --??
    local scale = (1.5 * zoom * kopt_context.dev_width) / bounds.x1
    -- store zoom
    kopt_context.zoom = scale
    -- do real scale
    mupdf.debug(string.format("reading page:%d,%d,%d,%d scale:%.2f",bounds.x0,bounds.y0,bounds.x1,bounds.y1,scale))
    render_for_kopt(kopt_context.src, self, scale, bounds)

    if kopt_context.precache ~= 0 then
        local pthread = get_pthread()
        local rf_thread = ffi.new("pthread_t[1]")
        local attr = ffi.new("pthread_attr_t[1]")
        pthread.pthread_attr_init(attr)
        pthread.pthread_attr_setdetachstate(attr, pthread.PTHREAD_CREATE_DETACHED)
        pthread.pthread_create(rf_thread, attr, k2pdfopt.k2pdfopt_reflow_bmp, ffi.cast("void*", kopt_context))
        pthread.pthread_attr_destroy(attr)
    else
        k2pdfopt.k2pdfopt_reflow_bmp(kopt_context)
    end
end

function page_mt.__index:getPagePix(kopt_context)
    local bounds = ffi.new("fz_rect")
    bounds.x0 = kopt_context.bbox.x0
    bounds.y0 = kopt_context.bbox.y0
    bounds.x1 = kopt_context.bbox.x1
    bounds.y1 = kopt_context.bbox.y1

    render_for_kopt(kopt_context.src, self, kopt_context.zoom, bounds)

    kopt_context.page_width = kopt_context.src.width
    kopt_context.page_height = kopt_context.src.height
end

function page_mt.__index:toBmp(bmp, dpi, color)
    local color_save = mupdf.color
    mupdf.color = color and true or false

    local bounds = self.ctx:fz_bound_page(self.page)

    render_for_kopt(bmp, self, dpi/72, bounds)

    mupdf.color = color_save
end

return mupdf
