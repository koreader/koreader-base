--[[
MuPDF API

This is a FFI wrapper for what was a Lua-based API in the past
Some kind of C wrapper is needed for muPDF since muPDF uses
a setjmp/longjmp based approach to error/exception handling.
That's one of the very few things we can't deal with using
LuaJIT's FFI.
--]]

local ffi = require("ffi")
require("ffi/mupdf_h")
require("ffi/posix_h") -- for malloc

local BlitBuffer = require("ffi/blitbuffer")

local M
if ffi.os == "Windows" then
    M = ffi.load("libs/libmupdf.dll")
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
local FZ_VERSION = "1.7"

local document_mt = { __index = {} }
local page_mt = { __index = {} }
local mupdf_mt = {}

mupdf.debug = function() --[[ no debugging by default ]] end

local save_ctx = nil
-- provides an fz_context for mupdf
local function context()
    if save_ctx ~= nil then return save_ctx end

    local context = M.fz_new_context_imp(
        mupdf.debug_memory and W.mupdf_get_my_alloc_context() or nil,
        nil,
        mupdf.cache_size, FZ_VERSION)

    if context == nil then
        error("cannot create fz_context for MuPDF")
    end

    save_ctx = context
    return context
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

--[[
open a document
--]]
function mupdf.openDocument(filename, cache_size)
    M.fz_register_document_handlers(context())

    local mupdf_doc = {
        doc = W.mupdf_open_document(context(), filename),
        filename = filename,
    }

    if mupdf_doc.doc == nil then
		merror("cannot open PDF file")
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
    return M.fz_needs_password(self.doc) ~= 0
end

--[[
try to authenticate with a password
--]]
function document_mt.__index:authenticatePassword(password)
    if M.fz_authenticate_password(self.doc, password) == 0 then
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

local function toc_walker(toc, outline, depth)
    while outline ~= nil do
        table.insert(toc, {
            page = outline.dest.ld.gotor.page + 1,
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
    -- the API takes a char*, not a const char*,
    -- so we claim memory - and never free it. Too bad.
    -- TODO: free on closing document?
    local filename_str = ffi.C.malloc(#filename + 1)
    if filename == nil then error("could not allocate memory for filename") end
    ffi.copy(filename_str, filename)
	local opts = ffi.new("fz_write_options[1]")
	opts[0].do_incremental = (filename == self.filename ) and 1 or 0
	opts[0].do_ascii = 0
	opts[0].do_expand = 0
	opts[0].do_garbage = 0
	opts[0].do_linear = 0
	opts[0].continue_on_error = 1
	local ok = W.mupdf_write_document(context(), self.doc, filename_str, opts)
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

	M.fz_bound_page(self.doc.doc, self.page, bounds)
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
	-- The last 2 aren't strictly bullets, but will do for our usage here
	return c == 0x2022 or --  Bullet
		c == 0x2023 or --  Triangular bullet
		c == 0x25e6 or --  White bullet
		c == 0x2043 or --  Hyphen bullet
		c == 0x2219 or --  Bullet operator
		c == 149 or --  Ascii bullet
		c == C'*'
end
-- this function had (disabled) functionality to check for lines
-- starting with a span that contained numbers, roman numbers or
-- latin literals, optionally followed by ":" or ")" for which
-- it would also return true. Since the implementation looked dubious
-- and was disabled anyway, it was left out when porting to Lua/FFI API
local function is_list_entry(span)
    local len = span.len
    local text = span.text
    for n = 0, len - 1 do
        local c = text[n].c
        if is_unicode_wspace(c) then
            -- skip whitespace at the beginning
        elseif is_unicode_bullet(c) then
            -- return true for all lines starting with bullets
            return true
        else
            return false
        end
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
    local text_page = W.mupdf_new_text_page(context())
    if text_page == nil then merror("cannot alloc text_page") end
    local text_sheet = W.mupdf_new_text_sheet(context())
    if text_sheet == nil then
        M.fz_drop_text_page(context(), text_page)
        merror("cannot alloc text_sheet")
    end
    local tdev = W.mupdf_new_text_device(context(), text_sheet, text_page)
    if tdev == nil then
        M.fz_drop_text_page(context(), text_page)
        M.fz_drop_text_sheet(context(), text_sheet)
        merror("cannot alloc text device")
    end

    if W.mupdf_run_page(context(), self.page, tdev, M.fz_identity, nil) == nil then
        M.fz_drop_text_page(context(), text_page)
        M.fz_drop_text_sheet(context(), text_sheet)
        M.fz_drop_device(context(), tdev)
        merror("cannot run page through text device")
    end

    -- now we analyze the data returned by the device and bring it
    -- into the format we want to return
    local lines = {}
    local char_bbox = ffi.new("fz_rect[1]")

    for block_num = 0, text_page.len - 1 do
        if text_page.blocks[block_num].type == M.FZ_PAGE_BLOCK_TEXT then
            local block = text_page.blocks[block_num].u.text

            -- a block contains lines, which is our primary return datum
            for line_num = 0, block.len - 1 do
                local line = {}
                local word = 1
                local line_bbox = ffi.new("fz_rect[1]")

                -- a line consists of spans, which can contain words
                local span = block.lines[line_num].first_span
                if span and is_list_entry(span) then
                    -- skip list bullets & co
                    span = span.next
                end
                while span ~= nil do
                    -- here we will collect UTF-8 chars before making them
                    -- a Lua string:
                    local textbuf = ffi.new("char[?]", span.len * 4)

                    local i = 0
                    while i < span.len do
                        local word = {}
                        local textlen = 0
                        local word_bbox = ffi.new("fz_rect[1]")
                        while i < span.len do
                            if is_unicode_wspace(span.text[i].c) then
                                -- ignore and end word
                                break
                            end
						    textlen = textlen + M.fz_runetochar(textbuf + textlen, span.text[i].c)
						    M.fz_union_rect(word_bbox, M.fz_text_char_bbox(char_bbox, span, i))
						    M.fz_union_rect(line_bbox, char_bbox)
						    if span.text[i].c >= 0x4e00 and span.text[i].c <= 0x9FFF or -- CJK Unified Ideographs
							    span.text[i].c >= 0x2000 and span.text[i].c <= 0x206F or -- General Punctuation
							    span.text[i].c >= 0x3000 and span.text[i].c <= 0x303F or -- CJK Symbols and Punctuation
							    span.text[i].c >= 0x3400 and span.text[i].c <= 0x4DBF or -- CJK Unified Ideographs Extension A
							    span.text[i].c >= 0xF900 and span.text[i].c <= 0xFAFF or -- CJK Compatibility Ideographs
							    span.text[i].c >= 0xFF01 and span.text[i].c <= 0xFFEE or -- Halfwidth and Fullwidth Forms
							    span.text[i].c >= 0x20000 and span.text[i].c <= 0x2A6DF  -- CJK Unified Ideographs Extension B
						    then
                                -- end word
							    break
                            end
                            i = i + 1
                        end
                        -- add word to line
                        table.insert(line, {
                            word = ffi.string(textbuf, textlen),
                            x0 = word_bbox[0].x0, y0 = word_bbox[0].y0,
                            x1 = word_bbox[0].x1, y1 = word_bbox[0].y1,
                        })
                        i = i + 1
                    end
                    span = span.next
                end

                line.x0, line.y0 = line_bbox[0].x0, line_bbox[0].y0
                line.x1, line.y1 = line_bbox[0].x1, line_bbox[0].y1

                table.insert(lines, line)
            end
        end
    end

    M.fz_drop_device(context(), tdev)
    M.fz_drop_text_sheet(context(), text_sheet)
    M.fz_drop_text_page(context(), text_page)

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
        if link.dest.kind == M.FZ_LINK_URI then
            data.uri = ffi.string(link.dest.ld.uri.uri)
        elseif link.dest.kind == M.FZ_LINK_GOTO then
            data.page = link.dest.ld.gotor.page -- FIXME page+1?
        else
            mupdf.debug(string.format("ERROR: unknown link kind 0x%x", tonumber(link.dest.kind)))
        end
        table.insert(links, data)
        link = link.next
    end

	M.fz_drop_link(context(), page_links)

    return links
end

local function run_page(page, pixmap, ctm)
	M.fz_clear_pixmap_with_value(context(), pixmap, 0xff)

	local dev = W.mupdf_new_draw_device(context(), pixmap)
    if dev == nil then merror("cannot create draw device") end

	local ok = W.mupdf_run_page(context(), page.page, dev, ctm, nil)
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

    local bb = BlitBuffer.new(width, height, mupdf.color and BlitBuffer.TYPE_RGB32 or BlitBuffer.TYPE_BB8A)

    local colorspace = mupdf.color and M.fz_device_rgb(context())
        or M.fz_device_gray(context())
	local pix = W.mupdf_new_pixmap_with_bbox_and_data(
        context(), colorspace, bbox, ffi.cast("unsigned char*", bb.data))
    if pix == nil then merror("cannot allocate pixmap") end

    run_page(self, pix, ctm)

	if draw_context.gamma >= 0.0 then
		M.fz_gamma_pixmap(context(), pix, draw_context.gamma)
	end

    M.fz_drop_pixmap(context(), pixmap)

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
    if type == M.FZ_ANNOT_HIGHLIGHT then
        color[0] = 1.0
		color[1] = 1.0
		color[2] = 0.0
		alpha = 0.5
    elseif type == M.FZ_ANNOT_UNDERLINE then
		color[0] = 0.0
		color[1] = 0.0
		color[2] = 1.0
		line_thickness = mupdf.LINE_THICKNESS
		line_height = mupdf.UNDERLINE_HEIGHT
	elseif type == M.FZ_ANNOT_STRIKEOUT then
		color[0] = 1.0
		color[1] = 0.0
		color[2] = 0.0
		line_thickness = mupdf.LINE_THICKNESS
		line_height = mupdf.STRIKE_HEIGHT
    else
        return
    end

	local doc = M.pdf_specifics(self.doc.doc)
    if doc == nil then merror("could not get pdf_specifics") end

    local annot = W.mupdf_pdf_create_annot(context(), doc, ffi.cast("pdf_page*", self.page), type)
    if annot == nil then merror("could not create annotation") end

    local ok = W.mupdf_pdf_set_markup_annot_quadpoints(context(), doc, annot, points, n)
    if ok == nil then merror("could not set markup annot quadpoints") end

    local ok = W.mupdf_pdf_set_markup_appearance(context(), doc, annot, color, alpha, line_thickness, line_height)
    if ok == nil then merror("could not set markup appearance") end
end


-- image loading via MuPDF:

--[[
render image data
--]]
function mupdf.renderImage(data, size, width, height)
    local image = W.mupdf_new_image_from_data(context(),
                    ffi.cast("unsigned char*", data), size)
    if image == nil then merror("could not load image data") end
    M.fz_keep_image(context(), image)
    local pixmap = W.mupdf_new_pixmap_from_image(context(),
                    image, width or -1, height or -1)
    if pixmap == nil then
        M.fz_drop_image(context(), image)
        merror("could not create pixmap from image")
    end

    local p_width = M.fz_pixmap_width(context(), pixmap)
    local p_height = M.fz_pixmap_height(context(), pixmap)
    local bbtype
    local ncomp = M.fz_pixmap_components(context(), pixmap)
    if ncomp == 2 then bbtype = BlitBuffer.TYPE_BB8A
    elseif ncomp == 4 then bbtype = BlitBuffer.TYPE_BBRGB32
    else error("unsupported number of color components")
    end
    local p = M.fz_pixmap_samples(context(), pixmap)
    local bb = BlitBuffer.new(p_width, p_height, bbtype, p):copy()
    M.fz_drop_pixmap(context(), pixmap)
    M.fz_drop_image(context(), image)
    return bb
end

function mupdf.renderImageFile(filename, width, height)
    local file = io.open(filename, "rb")
    if not file then error("could not open image file") end
    local data = file:read("*a")
    file:close()
    return mupdf.renderImage(data, #data, width, height)
end

-- k2pdfopt interfacing

-- will lazily load ffi/koptcontext.lua in order to interface k2pdfopt
local k2pdfopt
local function get_k2pdfopt()
    if k2pdfopt then return k2pdfopt end

    local koptcontext = require("ffi/koptcontext")
    k2pdfopt = koptcontext.k2pdfopt
    return k2pdfopt
end

-- lazily load libpthread
local pthread
local function get_pthread()
    if pthread then return pthread end

    local util = require("ffi/util")

    require("ffi/pthread_h")

    if ffi.os == "Windows" then
        return ffi.load("libwinpthread-1.dll")
    elseif util.isAndroid() then
        -- pthread directives are in the default namespace on Android
        return ffi.C
    else
        -- Kobo devices strangely have no libpthread.so in LD_LIBRARY_PATH
        -- so we hardcode the libpthread.so.0 here just for Kobo.
        for _, libname in ipairs({"libpthread.so", "libpthread.so.0"}) do
            local ok, pthread = pcall(ffi.load, libname)
            if ok then return pthread end
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
    local hook, mask, count = debug.gethook()
    debug.sethook()
    local k2pdfopt = get_k2pdfopt()

    bmp.width = M.fz_pixmap_width(context(), pixmap)
    bmp.height = M.fz_pixmap_height(context(), pixmap)
    local ncomp = M.fz_pixmap_components(context(), pixmap)
    local p = M.fz_pixmap_samples(context(), pixmap)
    if ncomp == 2 then
        -- 8bit grayscale (and 8 bit alpha)
        bmp.bpp = 8
	    k2pdfopt.bmp_alloc(bmp)
        -- set palette
        for i = 0, 255 do
            bmp.red[i] = i
            bmp.green[i] = i
            bmp.blue[i] = i
        end
        -- copy color values (and skip alpha)
        for row = 0, bmp.height - 1 do
            local dest = k2pdfopt.bmp_rowptr_from_top(bmp, row)
            local p_max = p + 2*bmp.width
            while p < p_max do
                dest[0] = p[0]
                dest = dest + 1
                p = p + 2
            end
        end
    elseif ncomp == 4 then
        -- 32bit RGBA
        bmp.bpp = 24
	    k2pdfopt.bmp_alloc(bmp)
        -- copy color values (and skip alpha)
        for row = 0, bmp.height - 1 do
            local dest = k2pdfopt.bmp_rowptr_from_top(bmp, row)
            local p_max = p + 4*bmp.width
            while p < p_max do
                dest[0] = p[0]
                dest[1] = p[1]
                dest[2] = p[2]
                dest = dest + 3
                p = p + 4
            end
        end
    else
        debug.sethook(hook, mask)
        error("unsupported pixmap format for conversion to bmp")
    end
    debug.sethook(hook, mask)
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
	local pix = W.mupdf_new_pixmap_with_bbox(context(), colorspace, bbox)
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
	local scale = 1.0 / ((
                bounds[0].x1 / (2 * zoom * kopt_context.dev_width) +
			    bounds[0].y1 / (2 * zoom * kopt_context.dev_height)
            ) / 2 )
	-- store zoom
	kopt_context.zoom = scale
	-- do real scale
	mupdf.debug(string.format("reading page:%d,%d,%d,%d scale:%.2f",bounds[0].x0,bounds[0].y0,bounds[0].x1,bounds[0].y1,scale))
    render_for_kopt(kopt_context.src, self, scale, bounds)

	if kopt_context.precache ~= 0 then
        local pthread = get_pthread()
        local rf_thread = ffi.new("pthread_t[1]")
        local attr = ffi.new("pthread_attr_t")
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
	M.fz_bound_page(self.doc.doc, self.page, bounds)

    render_for_kopt(bmp, self, dpi/72, bounds)

    mupdf.color = color_save
end

setmetatable(mupdf, mupdf_mt)

return mupdf
