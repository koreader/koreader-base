--[[--
MuPDF API

This is a FFI wrapper for what was a Lua-based API in the past
Some kind of C wrapper is needed for muPDF since muPDF uses
a setjmp/longjmp based approach to error/exception handling.
That's one of the very few things we can't deal with using
LuaJIT's FFI.

@module ffi.mupdf
--]]

local ffi = require("ffi")
require("ffi/mupdf_h")
require("ffi/posix_h") -- for malloc

local BlitBuffer = require("ffi/blitbuffer")

local C = ffi.C
local W = ffi.loadlib("wrap-mupdf")
local M = W

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
}
-- this cannot get adapted by the cdecl file because it is a
-- string constant. Must match the actual mupdf API:
local FZ_VERSION = "1.26.3"

local document_mt = { __index = {} }
local page_mt = { __index = {} }

mupdf.debug = function() --[[ no debugging by default ]] end

local function drop_context(ctx)
    local refcount = ffi.cast("int *", M.fz_user_context(ctx))
    refcount[0] = refcount[0] - 1
    if refcount[0] == 0 then
        M.fz_drop_context(ctx)
        C.free(refcount)
    end
end

local function keep_context(ctx)
    local refcount = ffi.cast("int *", M.fz_user_context(ctx))
    refcount[0] = refcount[0] + 1
    return ctx
end

local save_ctx = setmetatable({}, {__mode="kv"})

-- provides an fz_context for mupdf
local function context()
    local ctx = save_ctx[1]
    if ctx then return ctx end

    ctx = M.fz_new_context_imp(
        mupdf.debug_memory and W.mupdf_get_my_alloc_context() or nil,
        nil,
        mupdf.cache_size, FZ_VERSION)

    if ctx == nil then
        error("cannot create fz_context for MuPDF")
    end

    local refcount = ffi.cast("int *", C.malloc(ffi.sizeof("int")))
    M.fz_set_user_context(ctx, refcount)
    refcount[0] = 1

    -- ctx is a cdata<fz_context *>, attach a finalizer to it to release ressources on garbage collection
    ctx = ffi.gc(ctx, drop_context)

    M.fz_install_external_font_funcs(ctx)
    M.fz_register_document_handlers(ctx)

    save_ctx[1] = ctx
    return ctx
end

-- a wrapper for mupdf exception error messages
local function merror(ctx, message)
    error(string.format("%s: %s (%d)", message,
        ffi.string(W.mupdf_error_message(ctx)),
        W.mupdf_error_code(ctx)))
end

local function drop_document(ctx, doc)
    -- Clear the cdata finalizer to avoid a double-free
    ffi.gc(doc, nil)
    M.fz_drop_document(ctx, doc)
    drop_context(ctx)
end

local function drop_page(ctx, page)
    -- Clear the cdata finalizer to avoid a double-free
    ffi.gc(page, nil)
    M.fz_drop_page(ctx, page)
    drop_context(ctx)
end

--[[--
Opens a document.
--]]
function mupdf.openDocument(filename)
    local ctx = context()
    local mupdf_doc = {
        doc = W.mupdf_open_document(ctx, filename),
        filename = filename,
    }

    if mupdf_doc.doc == nil then
        merror(ctx, "MuPDF cannot open file.")
    end

    -- doc is a cdata<fz_document *>, attach a finalizer to it to release ressources on garbage collection
    mupdf_doc.doc = ffi.gc(mupdf_doc.doc, function(doc) drop_document(ctx, doc) end)
    mupdf_doc.ctx = keep_context(ctx)

    setmetatable(mupdf_doc, document_mt)

    if mupdf_doc:getPages() <= 0 then
        merror(ctx, "MuPDF found no pages in file.")
    end

    return mupdf_doc
end

function mupdf.openDocumentFromText(text, magic, html_resource_directory)
    local ctx = context()
    local stream = W.mupdf_open_memory(ctx, ffi.cast("const unsigned char*", text), #text)

    local archive = nil
    if html_resource_directory ~= nil then
        archive = W.mupdf_open_directory(ctx, html_resource_directory)
    end

    local mupdf_doc = {
        doc = W.mupdf_open_document_with_stream_and_dir(ctx, magic, stream, archive),
    }
    W.mupdf_drop_stream(ctx, stream)

    if archive ~= nil then
        W.mupdf_drop_archive(ctx, archive)
    end

    if mupdf_doc.doc == nil then
        merror(ctx, "MuPDF cannot open document from text")
    end

    -- doc is a cdata<fz_document *>, attach a finalizer to it to release ressources on garbage collection
    mupdf_doc.doc = ffi.gc(mupdf_doc.doc, function(doc) drop_document(ctx, doc) end)
    mupdf_doc.ctx = keep_context(ctx)

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
        drop_document(self.ctx, self.doc)
        self.doc = nil
        self.ctx = nil
    end
end

--[[
check if the document needs a password for access
--]]
function document_mt.__index:needsPassword()
    return M.fz_needs_password(self.ctx, self.doc) ~= 0
end

--[[
try to authenticate with a password
--]]
function document_mt.__index:authenticatePassword(password)
    if M.fz_authenticate_password(self.ctx, self.doc, password) == 0 then
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

    local pages = W.mupdf_count_pages(self.ctx, self.doc)
    if pages == -1 then
        merror(self.ctx, "cannot access page tree")
    end

    self.number_of_pages = pages

    return pages
end

function document_mt.__index:isDocumentReflowable()
    if self.is_reflowable then return self.is_reflowable end
    self.is_reflowable = M.fz_is_document_reflowable(self.ctx, self.doc) == 1
    return self.is_reflowable
end

function document_mt.__index:layoutDocument(width, height, em)
    -- Reset the cache.
    self.number_of_pages = nil

    W.mupdf_layout_document(self.ctx, self.doc, width, height, em)
end

function document_mt.__index:setColorRendering(color)
    self.color = color
end

local function toc_walker(toc, outline, depth)
    while outline ~= nil do
        table.insert(toc, {
            page = outline.page.page + 1,
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
    local outline = W.mupdf_load_outline(self.ctx, self.doc)
    if outline ~= nil then
        toc_walker(toc, outline, 1)
        M.fz_drop_outline(self.ctx, outline)
    end
    return toc
end

--[[
open a page, return page object
--]]
function document_mt.__index:openPage(number)
    local ctx = self.ctx
    local mupdf_page = {
        page = W.mupdf_load_page(ctx, self.doc, number-1),
        number = number,
        doc = self,
    }

    if mupdf_page.page == nil then
        merror(ctx, "cannot open page #" .. number)
    end

    -- page is a cdata<fz_page *>, attach a finalizer to it to release ressources on garbage collection
    mupdf_page.page = ffi.gc(mupdf_page.page, function(page) drop_page(ctx, page) end)
    mupdf_page.ctx = keep_context(ctx)

    setmetatable(mupdf_page, page_mt)

    return mupdf_page
end

local function getMetadataInfo(ctx, doc, info)
    local bufsize = 255
    local buf = ffi.new("char[?]", bufsize)
    -- `fz_lookup_metadata` return the number of bytes needed
    -- to store the string, **including** the null terminator.
    local res = M.fz_lookup_metadata(ctx, doc, info, buf, bufsize)
    if res > bufsize then
        -- Buffer was too small.
        bufsize = res
        buf = ffi.new("char[?]", bufsize)
        res = M.fz_lookup_metadata(ctx, doc, info, buf, bufsize)
    end
    if res > 1 then
        -- Note: strip the null terminator.
        return ffi.string(buf, res - 1)
    end
    -- Empty string or error (-1).
    return ""
end


--[[
Get metadata, return object
--]]
function document_mt.__index:getMetadata()
    local metadata = {
        title = getMetadataInfo(self.ctx, self.doc, "info:Title"),
        author = getMetadataInfo(self.ctx, self.doc, "info:Author"),
        subject = getMetadataInfo(self.ctx, self.doc, "info:Subject"),
        keywords = getMetadataInfo(self.ctx, self.doc, "info:Keywords"),
        creator = getMetadataInfo(self.ctx, self.doc, "info:Creator"),
        producer = getMetadataInfo(self.ctx, self.doc, "info:Producer"),
        creationDate = getMetadataInfo(self.ctx, self.doc, "info:CreationDate"),
        modDate = getMetadataInfo(self.ctx, self.doc, "info:ModDate")
    }

    return metadata
end

--[[
return currently claimed memory by MuPDF

This will return sensible values only when the debug_memory flag is set
--]]
function document_mt.__index:getCacheSize()
    if mupdf.debug_memory then
        return W.mupdf_get_cache_size()
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
    local ok = W.mupdf_pdf_save_document(self.ctx, ffi.cast("pdf_document*", self.doc), filename, opts)
    if ok == nil then merror(self.ctx, "could not write document") end
end


-- Page functions:

--[[
explicitly close the page object

this is done implicitly by garbage collection, too.
--]]
function page_mt.__index:close()
    if self.page ~= nil then
        drop_page(self.ctx, self.page)
        self.page = nil
        self.ctx = nil
    end
end

--[[
calculate page size after applying DrawContext
--]]
function page_mt.__index:getSize(draw_context)
    local bounds = ffi.new("fz_rect")
    local ctm = ffi.new("fz_matrix")

    W.mupdf_fz_scale(ctm, draw_context.zoom, draw_context.zoom)
    W.mupdf_fz_pre_rotate(ctm, draw_context.rotate)

    W.mupdf_fz_bound_page(self.ctx, self.page, bounds)
    W.mupdf_fz_transform_rect(bounds, ctm)

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

    return bounds.x1 - bounds.x0, bounds.y1 - bounds.y0
end

--[[
check which part of the page actually contains content
--]]
function page_mt.__index:getUsedBBox()
    local result = ffi.new("fz_rect")

    local dev = W.mupdf_new_bbox_device(self.ctx, result)
    if dev == nil then merror(self.ctx, "cannot allocate bbox_device") end
    local ok = W.mupdf_run_page(self.ctx, self.page, dev, M.fz_identity, nil)
    M.fz_close_device(self.ctx, dev)
    M.fz_drop_device(self.ctx, dev)
    if ok == nil then merror(self.ctx, "cannot calculate bbox for page") end

    return result.x0, result.y0, result.x1, result.y1
end

local B = string.byte
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
        c == B'*'
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
    local text_page = W.mupdf_new_stext_page_from_page(self.ctx, self.page, nil)
    if text_page == nil then merror(self.ctx, "cannot alloc text_page") end

    -- now we analyze the data returned by the device and bring it
    -- into the format we want to return
    local lines = {}
    local size = 0

    local block = text_page.first_block
    while block ~= nil do
        if block.type == M.FZ_STEXT_BLOCK_TEXT then
            -- a block contains lines, which is our primary return datum
            local mupdf_line = block.u.t.first_line
            while mupdf_line ~= nil do
                local line = {}
                local line_bbox = ffi.new("fz_rect", M.fz_empty_rect)

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
                        local word_bbox = ffi.new("fz_rect", M.fz_empty_rect)
                        while ch ~= nil do
                            if is_unicode_wspace(ch.c) then
                                -- ignore and end word
                                break
                            end
                            textlen = textlen + M.fz_runetochar(textbuf + textlen, ch.c)
                            local char_bbox = ffi.new("fz_rect")
                            W.mupdf_fz_rect_from_quad(char_bbox, ch.quad)
                            W.mupdf_fz_union_rect(word_bbox, char_bbox)
                            W.mupdf_fz_union_rect(line_bbox, char_bbox)
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
                        if word_bbox.x0 < word_bbox.x1 and word_bbox.y0 < word_bbox.y1 then
                            table.insert(line, {
                                word = ffi.string(textbuf, textlen),
                                x0 = word_bbox.x0, y0 = word_bbox.y0,
                                x1 = word_bbox.x1, y1 = word_bbox.y1,
                            })
                            size = size + 5 * 8 + textlen
                        end

                        if ch == nil then
                            break
                        end

                        ch = ch.next
                    end

                    if line_bbox.x0 < line_bbox.x1 and line_bbox.y0 < line_bbox.y1 then
                        line.x0, line.y0 = line_bbox.x0, line_bbox.y0
                        line.x1, line.y1 = line_bbox.x1, line_bbox.y1
                        size = size + 5 * 8
                        table.insert(lines, line)
                    end
                end

                mupdf_line = mupdf_line.next
            end
        end

        block = block.next
    end

    -- Rough approximation of size for caching
    lines.size = size

    M.fz_drop_stext_page(self.ctx, text_page)

    return lines
end

--[[
Get a list of the Hyperlinks on a page
--]]
function page_mt.__index:getPageLinks()
    local page_links = W.mupdf_load_links(self.ctx, self.page)
    -- do not error out when page_links == NULL, since there might
    -- simply be no links present.

    local links = {}

    local link = page_links
    while link ~= nil do
        local data = {
            x0 = link.rect.x0, y0 = link.rect.y0,
            x1 = link.rect.x1, y1 = link.rect.y1,
        }
        local pos = ffi.new("float[2]")
        local location = ffi.new("fz_location")
        W.mupdf_fz_resolve_link(self.ctx, self.doc.doc, link.uri, pos, pos+1, location)
        -- `fz_resolve_link` return a location of (-1, -1) for external links.
        if location.chapter == -1 and location.page == -1 then
            data.uri = ffi.string(link.uri)
        else
            data.page = W.mupdf_fz_page_number_from_location(self.ctx, self.doc.doc, location)
        end
        data.pos = {
            x = pos[0], y = pos[1],
        }
        table.insert(links, data)
        link = link.next
    end

    M.fz_drop_link(self.ctx, page_links)

    return links
end

local function run_page(page, pixmap, ctm)
    M.fz_clear_pixmap_with_value(page.ctx, pixmap, 0xff)

    local dev = W.mupdf_new_draw_device(page.ctx, nil, pixmap)
    if dev == nil then merror(page.ctx, "cannot create draw device") end

    local ok = W.mupdf_run_page(page.ctx, page.page, dev, ctm, nil)
    M.fz_close_device(page.ctx, dev)
    M.fz_drop_device(page.ctx, dev)
    if ok == nil then merror(page.ctx, "could not run page") end
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
    local ctm = ffi.new("fz_matrix")

    W.mupdf_fz_scale(ctm, draw_context.zoom, draw_context.zoom)
    W.mupdf_fz_pre_rotate(ctm, draw_context.rotate)
    W.mupdf_fz_pre_translate(ctm, draw_context.offset_x, draw_context.offset_y)

    local bbox = ffi.new("fz_irect", offset_x, offset_y, offset_x + width, offset_y + height)

    local bb = BlitBuffer.new(width, height, self.doc.color and BlitBuffer.TYPE_BBRGB32 or BlitBuffer.TYPE_BB8)

    local colorspace = self.doc.color and M.fz_device_rgb(self.ctx)
        or M.fz_device_gray(self.ctx)
    if mupdf.bgr and self.doc.color then
        colorspace = M.fz_device_bgr(self.ctx)
    end
    local pix = W.mupdf_new_pixmap_with_bbox_and_data(
        self.ctx, colorspace, bbox, nil, self.doc.color and 1 or 0, ffi.cast("unsigned char*", bb.data))
    if pix == nil then merror(self.ctx, "cannot allocate pixmap") end

    run_page(self, pix, ctm)

    if draw_context.gamma >= 0.0 then
        M.fz_gamma_pixmap(self.ctx, pix, draw_context.gamma)
    end

    M.fz_drop_pixmap(self.ctx, pix)

    return bb
end

mupdf.STRIKE_HEIGHT = 0.375
mupdf.UNDERLINE_HEIGHT = 0
mupdf.LINE_THICKNESS = 0.05
mupdf.HIGHLIGHT_COLOR = {1.0, 1.0, 0.0}
mupdf.UNDERLINE_COLOR = {0.0, 0.0, 1.0}
mupdf.STRIKE_OUT_COLOR = {1.0, 0.0, 0.0}

function page_mt.__index:addMarkupAnnotation(points, n, type, bb_color)
    local color = ffi.new("float[3]")
    local alpha = 1.0
    if type == M.PDF_ANNOT_HIGHLIGHT then
        if bb_color then
            color[0] = bb_color.r / 255
            color[1] = bb_color.g / 255
            color[2] = bb_color.b / 255
        else
            color[0] = mupdf.HIGHLIGHT_COLOR[1]
            color[1] = mupdf.HIGHLIGHT_COLOR[2]
            color[2] = mupdf.HIGHLIGHT_COLOR[3]
        end
        alpha = 0.5
    elseif type == M.PDF_ANNOT_UNDERLINE then
        if bb_color then
            color[0] = bb_color.r / 255
            color[1] = bb_color.g / 255
            color[2] = bb_color.b / 255
        else
            color[0] = mupdf.UNDERLINE_COLOR[1]
            color[1] = mupdf.UNDERLINE_COLOR[2]
            color[2] = mupdf.UNDERLINE_COLOR[3]
        end
    elseif type == M.PDF_ANNOT_STRIKE_OUT then
        if bb_color then
            color[0] = bb_color.r / 255
            color[1] = bb_color.g / 255
            color[2] = bb_color.b / 255
        else
            color[0] = mupdf.STRIKE_OUT_COLOR[1]
            color[1] = mupdf.STRIKE_OUT_COLOR[2]
            color[2] = mupdf.STRIKE_OUT_COLOR[3]
        end
    else
        return
    end

    local annot = W.mupdf_pdf_create_annot(self.ctx, ffi.cast("pdf_page*", self.page), type)
    if annot == nil then merror(self.ctx, "could not create annotation") end

    local ok = W.mupdf_pdf_set_annot_quad_points(self.ctx, annot, n, points)
    if ok == nil then merror(self.ctx, "could not set annotation quadpoints") end

    ok = W.mupdf_pdf_set_annot_color(self.ctx, annot, 3, color)
    if ok == nil then merror(self.ctx, "could not set annotation color") end

    ok = W.mupdf_pdf_set_annot_opacity(self.ctx, annot, alpha)
    if ok == nil then merror(self.ctx, "could not set annotation opacity") end

    -- Fetch back MuPDF's stored coordinates of all quadpoints, as they may have been modified/rounded
    -- (we need the exact ones that were saved if we want to be able to find them for deletion/update)
    for i = 0, n-1 do
        W.mupdf_pdf_annot_quad_point(self.ctx, annot, i, points+i)
    end
end

function page_mt.__index:deleteMarkupAnnotation(annot)
    local ok = W.mupdf_pdf_delete_annot(self.ctx, ffi.cast("pdf_page*", self.page), annot)
    if ok == nil then merror(self.ctx, "could not delete markup annotation") end
end

function page_mt.__index:getMarkupAnnotation(points, n)
    local annot = W.mupdf_pdf_first_annot(self.ctx, ffi.cast("pdf_page*", self.page))
    while annot ~= nil do
        local n2 = W.mupdf_pdf_annot_quad_point_count(self.ctx, annot)
        if n == n2 then
            local quadpoint = ffi.new("fz_quad[1]")
            local match = true
            for i = 0, n-1 do
                W.mupdf_pdf_annot_quad_point(self.ctx, annot, i, quadpoint)
                if (points[i].ul.x ~= quadpoint[0].ul.x or
                    points[i].ul.y ~= quadpoint[0].ul.y or
                    points[i].ur.x ~= quadpoint[0].ur.x or
                    points[i].ur.y ~= quadpoint[0].ur.y or
                    points[i].ll.x ~= quadpoint[0].ll.x or
                    points[i].ll.y ~= quadpoint[0].ll.y or
                    points[i].lr.x ~= quadpoint[0].lr.x or
                    points[i].lr.y ~= quadpoint[0].lr.y) then
                    match = false
                    break
                end
            end
            if match then return annot end
        end
        annot = W.mupdf_pdf_next_annot(self.ctx, annot)
    end
    return nil
end

function page_mt.__index:updateMarkupAnnotation(annot, contents)
    local ok = W.mupdf_pdf_set_annot_contents(self.ctx, annot, contents)
    if ok == nil then merror(self.ctx, "could not update markup annot contents") end
end

-- image loading via MuPDF:

--[[--
Renders image data.
--]]
function mupdf.renderImage(data, size, width, height)
    local ctx = context()
    local buffer = W.mupdf_new_buffer_from_shared_data(ctx,
                     ffi.cast("unsigned char*", data), size)
    local image = W.mupdf_new_image_from_buffer(ctx, buffer)
    W.mupdf_drop_buffer(ctx, buffer)
    if image == nil then merror(ctx, "could not load image data") end
    local pixmap = W.mupdf_get_pixmap_from_image(ctx,
                    image, nil, nil, nil, nil)
    M.fz_drop_image(ctx, image)
    if pixmap == nil then
        merror(ctx, "could not create pixmap from image")
    end

    local p_width = M.fz_pixmap_width(ctx, pixmap)
    local p_height = M.fz_pixmap_height(ctx, pixmap)
    -- mupdf_get_pixmap_from_image() may not scale image to the
    -- width and height provided, so check and scale it if needed
    if width and height then
        -- Ensure we pass integer values for width & height to fz_scale_pixmap(),
        -- because it enforces an alpha channel otherwise...
        width = math.floor(width)
        height = math.floor(height)
        if p_width ~= width or p_height ~= height then
            local scaled_pixmap = M.fz_scale_pixmap(ctx, pixmap, 0, 0, width, height, nil)
            M.fz_drop_pixmap(ctx, pixmap)
            if scaled_pixmap == nil then
                merror(ctx, "could not create scaled pixmap from pixmap")
            end
            pixmap = scaled_pixmap
            p_width = M.fz_pixmap_width(ctx, pixmap)
            p_height = M.fz_pixmap_height(ctx, pixmap)
        end
    end
    local bbtype
    local ncomp = M.fz_pixmap_components(ctx, pixmap)
    if ncomp == 1 then bbtype = BlitBuffer.TYPE_BB8
    elseif ncomp == 2 then bbtype = BlitBuffer.TYPE_BB8A
    elseif ncomp == 3 then bbtype = BlitBuffer.TYPE_BBRGB24
    elseif ncomp == 4 then bbtype = BlitBuffer.TYPE_BBRGB32
    else error("unsupported number of color components")
    end
    -- Handle RGB->BGR conversion for Kobos when needed
    local bb
    if mupdf.bgr and ncomp >= 3 then
        local bgr_pixmap = W.mupdf_convert_pixmap(ctx, pixmap, M.fz_device_bgr(ctx), nil, nil, M.fz_default_color_params, (ncomp == 4 and 1 or 0))
        if pixmap == nil then
            merror(ctx, "could not convert pixmap to BGR")
        end
        M.fz_drop_pixmap(ctx, pixmap)

        local p = M.fz_pixmap_samples(ctx, bgr_pixmap)
        bb = BlitBuffer.new(p_width, p_height, bbtype, p):copy()
        M.fz_drop_pixmap(ctx, bgr_pixmap)
    else
        local p = M.fz_pixmap_samples(ctx, pixmap)
        bb = BlitBuffer.new(p_width, p_height, bbtype, p):copy()
        M.fz_drop_pixmap(ctx, pixmap)
    end
    return bb
end

--- Renders image file.
function mupdf.renderImageFile(filename, width, height)
    local file = io.open(filename, "rb")
    if not file then error("could not open image file") end
    local data = file:read("*a")
    file:close()
    return mupdf.renderImage(data, #data, width, height)
end

--[[--
Scales a blitbuffer.

MµPDF's scaling is of much better quality than the very naive implementation in blitbuffer.lua.
(see fz_scale_pixmap_cached() in mupdf/source/fitz/draw-scale-simple.c).
Same arguments as BlitBuffer:scale() for easy replacement.

Unlike BlitBuffer:scale(), this *ignores* the blitbuffer's rotation
(i.e., where possible, we simply wrap the BlitBuffer's data in a fitz pixmap,
with no data copy, so the buffer's *native* memory layout is followed).
If you actually want to preserve the rotation, you'll have to fudge
with the width & height arguments and tweak the returned buffer's rotation flag,
or go through a temporary copy to ensure that the buffer's memory is laid out accordingly.
--]]
function mupdf.scaleBlitBuffer(bb, width, height)
    -- We need first to convert our BlitBuffer to a pixmap
    local bbtype = bb:getType()
    local colorspace
    local converted_bb
    local alpha
    local stride = bb.stride
    local ctx = context()
    -- MuPDF should know how to handle *most* of our BB types,
    -- special snowflakes excluded (4bpp & RGB565),
    -- in which case we feed it a temporary copy in the closest format it'll understand.
    if bbtype == BlitBuffer.TYPE_BB8 then
        colorspace = M.fz_device_gray(ctx)
        alpha = 0
    elseif bbtype == BlitBuffer.TYPE_BB8A then
        colorspace = M.fz_device_gray(ctx)
        alpha = 1
    elseif bbtype == BlitBuffer.TYPE_BBRGB24 then
        if mupdf.bgr then
            colorspace = M.fz_device_bgr(ctx)
        else
            colorspace = M.fz_device_rgb(ctx)
        end
        alpha = 0
    elseif bbtype == BlitBuffer.TYPE_BBRGB32 then
        if mupdf.bgr then
            colorspace = M.fz_device_bgr(ctx)
        else
            colorspace = M.fz_device_rgb(ctx)
        end
        alpha = 1
    elseif bbtype == BlitBuffer.TYPE_BB4 then
        converted_bb = BlitBuffer.new(bb.w, bb.h, BlitBuffer.TYPE_BB8)
        converted_bb:blitFrom(bb, 0, 0, 0, 0, bb.w, bb.h)
        bb = converted_bb -- we don't free() the provided bb, but we'll have to free our converted_bb
        colorspace = M.fz_device_gray(ctx)
        alpha = 0
        stride = bb.w
    else
        converted_bb = BlitBuffer.new(bb.w, bb.h, BlitBuffer.TYPE_BBRGB32)
        converted_bb:blitFrom(bb, 0, 0, 0, 0, bb.w, bb.h)
        bb = converted_bb -- we don't free() the provided bb, but we'll have to free our converted_bb
        if mupdf.bgr then
            colorspace = M.fz_device_bgr(ctx)
        else
            colorspace = M.fz_device_rgb(ctx)
        end
        alpha = 1
    end
    -- We can now create a pixmap from this bb of correct type
    local pixmap = W.mupdf_new_pixmap_with_data(ctx, colorspace,
                    bb.w, bb.h, nil, alpha, stride, ffi.cast("unsigned char*", bb.data))
    if pixmap == nil then
        if converted_bb then converted_bb:free() end -- free our home made bb
        merror(ctx, "could not create pixmap from blitbuffer")
    end
    -- We can now scale the pixmap
    -- Better to ensure we give integer width and height, to avoid a black 1-pixel line at right and bottom of image.
    -- Also, fz_scale_pixmap enforces an alpha channel if w or h are floats...
    local scaled_pixmap = M.fz_scale_pixmap(ctx, pixmap, 0, 0, math.floor(width), math.floor(height), nil)
    M.fz_drop_pixmap(ctx, pixmap) -- free our original pixmap
    if scaled_pixmap == nil then
        if converted_bb then converted_bb:free() end -- free our home made bb
        merror(ctx, "could not create scaled pixmap from pixmap")
    end
    local p_width = M.fz_pixmap_width(ctx, scaled_pixmap)
    local p_height = M.fz_pixmap_height(ctx, scaled_pixmap)
    -- And convert the pixmap back to a BlitBuffer
    bbtype = nil
    local ncomp = M.fz_pixmap_components(ctx, scaled_pixmap)
    if ncomp == 1 then bbtype = BlitBuffer.TYPE_BB8
    elseif ncomp == 2 then bbtype = BlitBuffer.TYPE_BB8A
    elseif ncomp == 3 then bbtype = BlitBuffer.TYPE_BBRGB24
    elseif ncomp == 4 then bbtype = BlitBuffer.TYPE_BBRGB32
    else
        if converted_bb then converted_bb:free() end -- free our home made bb
        error("unsupported number of color components")
    end
    local p = M.fz_pixmap_samples(ctx, scaled_pixmap)
    bb = BlitBuffer.new(p_width, p_height, bbtype, p):copy()
    M.fz_drop_pixmap(ctx, scaled_pixmap) -- free our scaled pixmap
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

--[[
the following function is a reimplementation of what can be found
in libk2pdfopt/willuslib/bmpmupdf.c
k2pdfopt supports only 8bit and 24bit "bitmaps" - and mupdf will give
only 8bit+8bit alpha or 24bit+8bit alpha pixmaps. So we need to convert
what we get from mupdf.
--]]
local function bmpmupdf_pixmap_to_bmp(bmp, pixmap)
    local k2pdfopt = get_k2pdfopt()
    local ctx = context()

    bmp.width = M.fz_pixmap_width(ctx, pixmap)
    bmp.height = M.fz_pixmap_height(ctx, pixmap)
    local ncomp = M.fz_pixmap_components(ctx, pixmap)
    local p = M.fz_pixmap_samples(ctx, pixmap)
    if ncomp == 2 or ncomp == 4 then
        k2pdfopt.pixmap_to_bmp(bmp, p, ncomp)
    else
        error("unsupported pixmap format for conversion to bmp")
    end
end

local function render_for_kopt(bmp, page, scale, bounds)
    local k2pdfopt = get_k2pdfopt()

    local bbox = ffi.new("fz_irect")
    local ctm = ffi.new("fz_matrix")
    W.mupdf_fz_scale(ctm, scale, scale)
    W.mupdf_fz_transform_rect(bounds, ctm)
    W.mupdf_fz_round_rect(bbox, bounds)

    local colorspace = page.doc.color and M.fz_device_rgb(page.ctx)
        or M.fz_device_gray(page.ctx)
    if mupdf.bgr and page.doc.color then
        colorspace = M.fz_device_bgr(page.ctx)
    end
    local pix = W.mupdf_new_pixmap_with_bbox(page.ctx, colorspace, bbox, nil, 1)
    if pix == nil then merror(page.ctx, "could not allocate pixmap") end

    run_page(page, pix, ctm)

    k2pdfopt.bmp_init(bmp)

    bmpmupdf_pixmap_to_bmp(bmp, pix)

    M.fz_drop_pixmap(page.ctx, pix)
end

function page_mt.__index:getPagePix(kopt_context)
    local bounds = ffi.new("fz_rect", kopt_context.bbox.x0, kopt_context.bbox.y0, kopt_context.bbox.x1, kopt_context.bbox.y1)

    render_for_kopt(kopt_context.src, self, kopt_context.zoom, bounds)

    kopt_context.page_width = kopt_context.src.width
    kopt_context.page_height = kopt_context.src.height
end

function page_mt.__index:toBmp(bmp, dpi)
    local bounds = ffi.new("fz_rect")
    W.mupdf_fz_bound_page(self.ctx, self.page, bounds)
    render_for_kopt(bmp, self, dpi/72, bounds)
end

return mupdf
