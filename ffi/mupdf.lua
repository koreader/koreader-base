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

local M
if ffi.os == "Windows" then
    M = ffi.load("libs/libmupdf.dll")
elseif ffi.os == "OSX" then
    M = ffi.load("libs/libmupdf.dylib")
else
    M = ffi.load("libs/libmupdf.so")
end
local W = ffi.load("libs/libwrap-mupdf.so")

local mupdf = {
    debug_memory = false,
    cache_size = 8*1024*1024,
    color = false,
}
-- this cannot get adapted by the cdecl file because it is a
-- string constant. Must match the actual mupdf API:
local FZ_VERSION = "1.13.0"

local document_mt = { __index = {} }
local page_mt = { __index = {} }
local mupdf_mt = {}

mupdf.debug = function() --[[ no debugging by default ]] end

local save_ctx = nil
-- provides an fz_context for mupdf
local function context()
    if save_ctx ~= nil then return save_ctx end

    local ctx = M.fz_new_context_imp(
        mupdf.debug_memory and W.mupdf_get_my_alloc_context() or nil,
        nil,
        mupdf.cache_size, FZ_VERSION)

    if ctx == nil then
        error("cannot create fz_context for MuPDF")
    end

    M.fz_install_external_font_funcs(ctx);

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

function mupdf_mt.__gc()
    if save_ctx ~= nil then
        M.fz_drop_context(save_ctx)
        save_ctx = nil
    end
end

--[[--
Opens a document.
--]]
function mupdf.openDocument(filename, cache_size)
    M.fz_register_document_handlers(context())

    local mupdf_doc = {
        doc = W.mupdf_open_document(context(), filename),
        filename = filename,
    }

    if mupdf_doc.doc == nil then
        merror("MuPDF cannot open file.")
    end

    setmetatable(mupdf_doc, document_mt)

    if not (mupdf_doc:getPages() > 0) then
        merror("MuPDF found no pages in file.")
    end

    return mupdf_doc
end

function mupdf.openDocumentFromText(text, magic)
    M.fz_register_document_handlers(context())

    local stream = W.mupdf_open_memory(context(), ffi.cast("const unsigned char*", text), #text)
    local mupdf_doc = {
        doc = W.mupdf_open_document_with_stream(context(), magic, stream),
    }
    W.mupdf_drop_stream(context(), stream)

    if mupdf_doc.doc == nil then
        merror("MuPDF cannot open document from text")
    end

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
        self.doc = nil
    end
end
document_mt.__index.__gc = document_mt.__index.close

--[[
check if the document needs a password for access
--]]
function document_mt.__index:needsPassword()
    return M.fz_needs_password(context(), self.doc) ~= 0
end

--[[
try to authenticate with a password
--]]
function document_mt.__index:authenticatePassword(password)
    if M.fz_authenticate_password(context(), self.doc, password) == 0 then
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

    local pages = W.mupdf_count_pages(context(), self.doc)
    if pages == -1 then
        merror("cannot access page tree")
    end

    self.number_of_pages = pages

    return pages
end

function document_mt.__index:layoutDocument(width, height, em)
    -- Reset the cache.
    self.number_of_pages = nil

    W.mupdf_layout_document(context(), self.doc, width, height, em)
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
    local outline = W.mupdf_load_outline(context(), self.doc)
    if outline ~= nil then
        toc_walker(toc, outline, 1)
        M.fz_drop_outline(context(), outline)
    end
    return toc
end

--[[
open a page, return page object
--]]
function document_mt.__index:openPage(number)
    local mupdf_page = {
        page = W.mupdf_load_page(context(), self.doc, number-1),
        number = number,
        doc = self,
    }
    if mupdf_page.page == nil then
        merror("cannot open page #" .. number)
    end
    setmetatable(mupdf_page, page_mt)
    return mupdf_page
end

local function getMetadataInfo(doc, info)
    local buf = ffi.new("char[?]", 255)
    local res = M.fz_lookup_metadata(context(), doc, info, buf, 255)
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
        title = getMetadataInfo(self.doc, "info:Title"),
        author = getMetadataInfo(self.doc, "info:Author"),
        subject = getMetadataInfo(self.doc, "info:Subject"),
        keywords = getMetadataInfo(self.doc, "info:Keywords"),
        creator = getMetadataInfo(self.doc, "info:Creator"),
        producer = getMetadataInfo(self.doc, "info:Producer"),
        creationDate = getMetadataInfo(self.doc, "info:CreationDate"),
        modDate = getMetadataInfo(self.doc, "info:ModDate")
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
    opts[0].continue_on_error = 1
    local ok = W.mupdf_pdf_save_document(context(), ffi.cast("pdf_document*", self.doc), filename, opts)
    if ok == nil then merror("could not write document") end
end


-- Page functions:

--[[
explicitly close the page object

this is done implicitly by garbage collection, too.
--]]
function page_mt.__index:close()
    if self.page ~= nil then
        M.fz_drop_page(context(), self.page)
        self.page = nil
    end
end
page_mt.__index.__gc = page_mt.__index.close

--[[
calculate page size after applying DrawContext
--]]
function page_mt.__index:getSize(draw_context)
    local bounds = ffi.new("fz_rect[1]")
    local bbox = ffi.new("fz_irect[1]")
    local ctm = ffi.new("fz_matrix")

    M.fz_scale(ctm, draw_context.zoom, draw_context.zoom)
    M.fz_pre_rotate(ctm, draw_context.rotate)

    M.fz_bound_page(context(), self.page, bounds)
    M.fz_transform_rect(bounds, ctm)
    M.fz_round_rect(bbox, bounds)

    return bbox[0].x1-bbox[0].x0, bbox[0].y1-bbox[0].y0
end

--[[
check which part of the page actually contains content
--]]
function page_mt.__index:getUsedBBox()
    local result = ffi.new("fz_rect[1]")

    local dev = W.mupdf_new_bbox_device(context(), result)
    if dev == nil then merror("cannot allocate bbox_device") end
    local ok = W.mupdf_run_page(context(), self.page, dev, M.fz_identity, nil)
    M.fz_close_device(context(), dev)
    M.fz_drop_device(context(), dev)
    if ok == nil then merror("cannot calculate bbox for page") end

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
    local text_page = W.mupdf_new_stext_page_from_page(context(), self.page, nil)
    if text_page == nil then merror("cannot alloc text_page") end

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
                local line_bbox = ffi.new("fz_rect[1]")

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
                        local word_bbox = ffi.new("fz_rect[1]")
                        while ch ~= nil do
                            if is_unicode_wspace(ch.c) then
                                -- ignore and end word
                                break
                            end
                            textlen = textlen + M.fz_runetochar(textbuf + textlen, ch.c)
                            M.fz_union_rect(word_bbox, ch.bbox)
                            M.fz_union_rect(line_bbox, ch.bbox)
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
                            x0 = word_bbox[0].x0, y0 = word_bbox[0].y0,
                            x1 = word_bbox[0].x1, y1 = word_bbox[0].y1,
                        })

                        if ch == nil then
                            break
                        end

                        ch = ch.next
                    end

                    line.x0, line.y0 = line_bbox[0].x0, line_bbox[0].y0
                    line.x1, line.y1 = line_bbox[0].x1, line_bbox[0].y1

                    table.insert(lines, line)
                end

                mupdf_line = mupdf_line.next
            end
        end

        block = block.next
    end

    M.fz_drop_stext_page(context(), text_page)

    return lines
end

--[[
Get a list of the Hyperlinks on a page
--]]
function page_mt.__index:getPageLinks()
    local page_links = W.mupdf_load_links(context(), self.page)
    -- do not error out when page_links == NULL, since there might
    -- simply be no links present.

    local links = {}

    local link = page_links
    while link ~= nil do
        local data = {
            x0 = link.rect.x0, y0 = link.rect.y0,
            x1 = link.rect.x1, y1 = link.rect.y1,
        }
        local page = M.fz_resolve_link(context(), link.doc, link.uri, nil, nil)
        if page >= 0 then
            data.page = page -- FIXME page+1?
        else
            data.uri = ffi.string(link.uri)
        end
        table.insert(links, data)
        link = link.next
    end

    M.fz_drop_link(context(), page_links)

    return links
end

local function run_page(page, pixmap, ctm)
    M.fz_clear_pixmap_with_value(context(), pixmap, 0xff)

    local dev = W.mupdf_new_draw_device(context(), nil, pixmap)
    if dev == nil then merror("cannot create draw device") end

    local ok = W.mupdf_run_page(context(), page.page, dev, ctm, nil)
    M.fz_close_device(context(), dev)
    M.fz_drop_device(context(), dev)
    if ok == nil then merror("could not run page") end
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

    M.fz_scale(ctm, draw_context.zoom, draw_context.zoom)
    M.fz_pre_rotate(ctm, draw_context.rotate)
    M.fz_pre_translate(ctm, draw_context.offset_x, draw_context.offset_y)

    local bbox = ffi.new("fz_irect[1]")
    bbox[0].x0 = offset_x
    bbox[0].y0 = offset_y
    bbox[0].x1 = offset_x + width
    bbox[0].y1 = offset_y + height

    local bb = BlitBuffer.new(width, height, mupdf.color and BlitBuffer.TYPE_BBRGB32 or BlitBuffer.TYPE_BB8A)

    local colorspace = mupdf.color and M.fz_device_rgb(context())
        or M.fz_device_gray(context())
    if mupdf.bgr and mupdf.color then
        colorspace = M.fz_device_bgr(context())
    end
    local pix = W.mupdf_new_pixmap_with_bbox_and_data(
        context(), colorspace, bbox, nil, 1, ffi.cast("unsigned char*", bb.data))
    if pix == nil then merror("cannot allocate pixmap") end

    run_page(self, pix, ctm)

    if draw_context.gamma >= 0.0 then
        M.fz_gamma_pixmap(context(), pix, draw_context.gamma)
    end

    M.fz_drop_pixmap(context(), pix)

    return bb
end

mupdf.STRIKE_HEIGHT = 0.375
mupdf.UNDERLINE_HEIGHT = 0.075
mupdf.LINE_THICKNESS = 0.07

function page_mt.__index:addMarkupAnnotation(points, n, type)
    local color = ffi.new("float[3]")
    local alpha = 1.0
    local line_height = 0.5
    local line_thickness = 1.0
    if type == M.PDF_ANNOT_HIGHLIGHT then
        color[0] = 1.0
        color[1] = 1.0
        color[2] = 0.0
        alpha = 0.5
    elseif type == M.PDF_ANNOT_UNDERLINE then
        color[0] = 0.0
        color[1] = 0.0
        color[2] = 1.0
        line_thickness = mupdf.LINE_THICKNESS
        line_height = mupdf.UNDERLINE_HEIGHT
    elseif type == M.PDF_ANNOT_STRIKEOUT then
        color[0] = 1.0
        color[1] = 0.0
        color[2] = 0.0
        line_thickness = mupdf.LINE_THICKNESS
        line_height = mupdf.STRIKE_HEIGHT
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
end


-- image loading via MuPDF:

--[[--
Renders image data.
--]]
function mupdf.renderImage(data, size, width, height)
    local buffer = W.mupdf_new_buffer_from_shared_data(context(),
                     ffi.cast("unsigned char*", data), size)
    local image = W.mupdf_new_image_from_buffer(context(), buffer)
    W.mupdf_drop_buffer(context(), buffer)
    if image == nil then merror("could not load image data") end
    local pixmap = W.mupdf_get_pixmap_from_image(context(),
                    image, nil, nil, nil, nil)
    M.fz_drop_image(context(), image)
    if pixmap == nil then
        merror("could not create pixmap from image")
    end

    local p_width = M.fz_pixmap_width(context(), pixmap)
    local p_height = M.fz_pixmap_height(context(), pixmap)
    -- mupdf_get_pixmap_from_image() may not scale image to the
    -- width and height provided, so check and scale it if needed
    if width and height then
        -- MuPDF 1.12 fz_scale_pixmap() may behave strangely (on ARM only!)
        -- if it is given non-integer width and height, and returns a corrupted
        -- image with a different ncomp than original pixmap...)
        width = math.floor(width)
        height = math.floor(height)
        if p_width ~= width or p_height ~= height then
            local scaled_pixmap = M.fz_scale_pixmap(context(), pixmap, 0, 0, width, height, nil)
            M.fz_drop_pixmap(context(), pixmap)
            pixmap = scaled_pixmap
            p_width = M.fz_pixmap_width(context(), pixmap)
            p_height = M.fz_pixmap_height(context(), pixmap)
        end
    end
    local bbtype
    local ncomp = M.fz_pixmap_components(context(), pixmap)
    if ncomp == 1 then bbtype = BlitBuffer.TYPE_BB8
    elseif ncomp == 2 then bbtype = BlitBuffer.TYPE_BB8A
    elseif ncomp == 3 then bbtype = BlitBuffer.TYPE_BBRGB24
    elseif ncomp == 4 then bbtype = BlitBuffer.TYPE_BBRGB32
    else error("unsupported number of color components")
    end
    -- Handle RGB->BGR conversion for Kobos when needed
    local bb
    if mupdf.bgr and ncomp >= 3 then
        local bgr_pixmap = M.fz_convert_pixmap(context(), pixmap, M.fz_device_bgr(context()), nil, nil, M.fz_default_color_params(context()), (ncomp == 4 and 1 or 0))
        M.fz_drop_pixmap(context(), pixmap)

        local p = M.fz_pixmap_samples(context(), bgr_pixmap)
        bb = BlitBuffer.new(p_width, p_height, bbtype, p):copy()
        M.fz_drop_pixmap(context(), bgr_pixmap)
    else
        local p = M.fz_pixmap_samples(context(), pixmap)
        bb = BlitBuffer.new(p_width, p_height, bbtype, p):copy()
        M.fz_drop_pixmap(context(), pixmap)
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

Quality of scaling done by MuPDF is better than the one done in blitbuffer.lua
(see fz_scale_pixmap_cached() in mupdf/source/fitz/draw-scale-simple.c).
Same arguments as BlitBuffer:scale() for easy replacement.
--]]
function mupdf.scaleBlitBuffer(bb, width, height)
    -- We need first to convert our BlitBuffer to a pixmap
    local orig_w, orig_h = bb:getWidth(), bb:getHeight()
    local bbtype = bb:getType()
    -- bb types TYPE_BB8A and TYPE_BBRGB32 work as-is with MuPDF
    -- but the other types' bb.data give corrupted resulting pixmap.
    local colorspace
    local converted_bb
    local stride
    if bbtype == BlitBuffer.TYPE_BB8A then
        colorspace = M.fz_device_gray(context())
        stride = orig_w * 2
    elseif bbtype == BlitBuffer.TYPE_BBRGB32 then
        if mupdf.bgr then
            colorspace = M.fz_device_bgr(context())
        else
            colorspace = M.fz_device_rgb(context())
        end
        stride = orig_w * 4
    else
        -- We need to convert the other types to one of the working
        -- types, and TYPE_BBRGB32 is the only one that works with
        -- the following operation (greyscale TYPE_B48 and TYPE_BB8
        -- get corrupted if we blit them to a TYPE_BB8A, but are fine
        -- when blited to a TYPE_BBRGB32)
        converted_bb = BlitBuffer.new(orig_w, orig_h, BlitBuffer.TYPE_BBRGB32)
        converted_bb:blitFrom(bb, 0, 0, 0, 0, orig_w, orig_h)
        bb = converted_bb -- we don't free() the provided bb, but we'll have to free our converted_bb
        if mupdf.bgr then
            colorspace = M.fz_device_bgr(context())
        else
            colorspace = M.fz_device_rgb(context())
        end
        stride = orig_w * 4
    end
    -- We can now create a pixmap from this bb of correct type
    -- whose bb.data is valid for mupdf
    local pixmap = W.mupdf_new_pixmap_with_data(context(), colorspace,
                    orig_w, orig_h, nil, 1, stride, ffi.cast("unsigned char*", bb.data))
    if pixmap == nil then
        if converted_bb then converted_bb:free() end -- free our home made bb
        merror("could not create pixmap from blitbuffer")
    end
    -- We can now scale the pixmap
    -- Better to ensure we give integer width and height, to avoid a black 1-pixel line at right and bottom of image
    local scaled_pixmap = M.fz_scale_pixmap(context(), pixmap, 0, 0, math.floor(width), math.floor(height), nil)
    M.fz_drop_pixmap(context(), pixmap) -- free our original pixmap
    local p_width = M.fz_pixmap_width(context(), scaled_pixmap)
    local p_height = M.fz_pixmap_height(context(), scaled_pixmap)
    -- And convert the pixmap back to a BlitBuffer
    bbtype = nil
    local ncomp = M.fz_pixmap_components(context(), scaled_pixmap)
    if ncomp == 2 then bbtype = BlitBuffer.TYPE_BB8A
    elseif ncomp == 4 then bbtype = BlitBuffer.TYPE_BBRGB32
    else
        if converted_bb then converted_bb:free() end -- free our home made bb
        error("unsupported number of color components")
    end
    local p = M.fz_pixmap_samples(context(), scaled_pixmap)
    bb = BlitBuffer.new(p_width, p_height, bbtype, p):copy()
    M.fz_drop_pixmap(context(), scaled_pixmap) -- free our scaled pixmap
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

    bmp.width = M.fz_pixmap_width(context(), pixmap)
    bmp.height = M.fz_pixmap_height(context(), pixmap)
    local ncomp = M.fz_pixmap_components(context(), pixmap)
    local p = M.fz_pixmap_samples(context(), pixmap)
    if ncomp == 2 or ncomp == 4 then
        k2pdfopt.pixmap_to_bmp(bmp, p, ncomp)
    else
        error("unsupported pixmap format for conversion to bmp")
    end
end

local function render_for_kopt(bmp, page, scale, bounds)
    local k2pdfopt = get_k2pdfopt()

    local bbox = ffi.new("fz_irect[1]")
    local ctm = ffi.new("fz_matrix")
    M.fz_scale(ctm, scale, scale)
    M.fz_transform_rect(bounds, ctm)
    M.fz_round_rect(bbox, bounds)

    local colorspace = mupdf.color and M.fz_device_rgb(context())
        or M.fz_device_gray(context())
    if mupdf.bgr and mupdf.color then
        colorspace = M.fz_device_bgr(context())
    end
    local pix = W.mupdf_new_pixmap_with_bbox(context(), colorspace, bbox, nil, 1)
    if pix == nil then merror("could not allocate pixmap") end

    run_page(page, pix, ctm)

    k2pdfopt.bmp_init(bmp)

    bmpmupdf_pixmap_to_bmp(bmp, pix)

    M.fz_drop_pixmap(context(), pix)
end

function page_mt.__index:reflow(kopt_context)
    local k2pdfopt = get_k2pdfopt()

    local bounds = ffi.new("fz_rect[1]")
    bounds[0].x0 = kopt_context.bbox.x0
    bounds[0].y0 = kopt_context.bbox.y0
    bounds[0].x1 = kopt_context.bbox.x1
    bounds[0].y1 = kopt_context.bbox.y1
    -- probe scale
    local zoom = kopt_context.zoom * kopt_context.quality
    M.fz_transform_rect(bounds, M.fz_identity)
    local scale = (1.5 * zoom * kopt_context.dev_width) / bounds[0].x1
    -- store zoom
    kopt_context.zoom = scale
    -- do real scale
    mupdf.debug(string.format("reading page:%d,%d,%d,%d scale:%.2f",bounds[0].x0,bounds[0].y0,bounds[0].x1,bounds[0].y1,scale))
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
    local bounds = ffi.new("fz_rect[1]")
    bounds[0].x0 = kopt_context.bbox.x0
    bounds[0].y0 = kopt_context.bbox.y0
    bounds[0].x1 = kopt_context.bbox.x1
    bounds[0].y1 = kopt_context.bbox.y1

    render_for_kopt(kopt_context.src, self, kopt_context.zoom, bounds)

    kopt_context.page_width = kopt_context.src.width
    kopt_context.page_height = kopt_context.src.height
end

function page_mt.__index:toBmp(bmp, dpi, color)
    local color_save = mupdf.color
    mupdf.color = color and true or false

    local bounds = ffi.new("fz_rect[1]")
    M.fz_bound_page(context(), self.page, bounds)

    render_for_kopt(bmp, self, dpi/72, bounds)

    mupdf.color = color_save
end

setmetatable(mupdf, mupdf_mt)

return mupdf
