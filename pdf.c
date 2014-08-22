/*
    KindlePDFViewer: MuPDF abstraction for Lua
    Copyright (C) 2011 Hans-Werner Hilse <hilse@web.de>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <stdio.h>
#include <math.h>
#include <stddef.h>
#include <pthread.h>
#include <assert.h>
#include <mupdf/fitz.h>
#include <mupdf/pdf.h>

#include "blitbuffer.h"
#include "drawcontext.h"
#include "koptcontext.h"
#include "k2pdfopt.h"
#include "koptreflow.h"
#include "koptcrop.h"
#include "pdf.h"

typedef struct PdfDocument {
	fz_document *xref;
	fz_context *context;
} PdfDocument;

typedef struct PdfPage {
	int num;
#ifdef USE_DISPLAY_LIST
	fz_display_list *list;
#endif
	fz_page *page;
	PdfDocument *doc;
} PdfPage;


static double LOG_TRESHOLD_PERC = 0.05; // 5%

enum {
    MAGIC = 0x3795d42b,
};

typedef struct header {
    int magic;
    size_t sz;
} header;

static size_t msize=0;
static size_t msize_prev;
static size_t msize_max;
static size_t msize_min;
static size_t msize_iniz;
static int is_realloc=0;

#if 0
char* readable_fs(double size/*in bytes*/, char *buf) {
    int i = 0;
    const char* units[] = {"B", "kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"};
    while (size > 1024) {
        size /= 1024;
        i++;
    }
    sprintf(buf, "%.*f %s", i, size, units[i]);
    return buf;
}
#endif

static void resetMsize(){
	msize_iniz = msize;
	msize_prev = 0;
	msize_max = 0;
	msize_min = (size_t)-1;
}

static void showMsize(){
	char buf[15],buf2[15],buf3[15],buf4[15];
	//printf("§§§ now: %s was: %s - min: %s - max: %s\n",readable_fs(msize,buf),readable_fs(msize_iniz,buf2),readable_fs(msize_min,buf3),readable_fs(msize_max,buf4));
	resetMsize();
}

static void log_size(char *funcName){
	if(msize_max < msize)
		msize_max = msize;
	if(msize_min > msize)
		msize_min = msize;
	if(1==0 && abs(msize-msize_prev)>msize_prev*LOG_TRESHOLD_PERC){
		char buf[15],buf2[15];
		//printf("§§§ %s - total: %s (was %s)\n",funcName, readable_fs(msize,buf),readable_fs(msize_prev,buf2));
		msize_prev = msize;
	}
}

static void *
my_malloc_default(void *opaque, unsigned int size)
{
    struct header * h = malloc(size + sizeof(header));
    if (h == NULL)
         return NULL;

    h -> magic = MAGIC;
    h -> sz = size;
    msize += size + sizeof(struct header);
    if(is_realloc!=1)
	    log_size("alloc");
    return (void *)(h + 1);
}

static void
my_free_default(void *opaque, void *ptr)
{
   if (ptr != NULL) {
        struct header * h = ((struct header *)ptr) - 1;
        if (h -> magic != MAGIC) { /* Not allocated by us */
        } else {
            msize -= h -> sz + sizeof(struct header);
            free(h);
        }
   }
   if(is_realloc!=1)
	   log_size("free");
}

static void *
my_realloc_default(void *opaque, void *old, unsigned int size)
{
	void * newp;
    if (old==NULL) { //practically, it's a malloc
    	newp = my_malloc_default(opaque, size);
    } else {
    	struct header * h = ((struct header *)old) - 1;
		if (h -> magic != MAGIC) { // Not allocated by my_malloc_default
			//printf("§§§ warn: not allocated by my_malloc_default, new size: %i\n",size);
			newp = realloc(old,size);
		} else { // malloc + free
			is_realloc = 1;
			size_t oldsize = h -> sz;
			//printf("realloc %i -> %i\n",oldsize,size);
			newp = my_malloc_default(opaque, size);
			if (NULL != newp) {
				memcpy(newp, old, oldsize<size?oldsize:size);
				my_free_default(opaque, old);
			}
			log_size("realloc");
			is_realloc = 0;
		}
	}

	return(newp);
}

fz_alloc_context my_alloc_default =
{
	NULL,
	my_malloc_default,
	my_realloc_default,
	my_free_default
};



static int openDocument(lua_State *L) {
	char *filename = strdup(luaL_checkstring(L, 1));
	int cache_size = luaL_optint(L, 2, 64 << 20); // 64 MB limit default
	char buf[15];
	//printf("## cache_size: %s\n",readable_fs(cache_size,buf));

	PdfDocument *doc = (PdfDocument*) lua_newuserdata(L, sizeof(PdfDocument));

	luaL_getmetatable(L, "pdfdocument");
	lua_setmetatable(L, -2);

	doc->context = fz_new_context(&my_alloc_default, NULL, cache_size);

	fz_register_document_handlers(doc->context);

	fz_try(doc->context) {
		doc->xref = fz_open_document(doc->context, filename);
	}
	fz_catch(doc->context) {
		free(filename);
		return luaL_error(L, "cannot open PDF file");
	}

	free(filename);
	return 1;
}

static int needsPassword(lua_State *L) {
	PdfDocument *doc = (PdfDocument*) luaL_checkudata(L, 1, "pdfdocument");
	lua_pushboolean(L, fz_needs_password(doc->xref));
	return 1;
}

static int authenticatePassword(lua_State *L) {
	PdfDocument *doc = (PdfDocument*) luaL_checkudata(L, 1, "pdfdocument");
	char *password = strdup(luaL_checkstring(L, 2));

	if (!fz_authenticate_password(doc->xref, password)) {
		lua_pushboolean(L, 0);
	} else {
		lua_pushboolean(L, 1);
	}
	free(password);
	return 1;
}

static int closeDocument(lua_State *L) {
	PdfDocument *doc = (PdfDocument*) luaL_checkudata(L, 1, "pdfdocument");

	// should be save if called twice
	if(doc->xref != NULL) {
		fz_close_document(doc->xref);
		doc->xref = NULL;
	}
	if(doc->context != NULL) {
		fz_free_context(doc->context);
		doc->context = NULL;
	}

	return 0;
}

static int getNumberOfPages(lua_State *L) {
	PdfDocument *doc = (PdfDocument*) luaL_checkudata(L, 1, "pdfdocument");
	fz_try(doc->context) {
		lua_pushinteger(L, fz_count_pages(doc->xref));
	}
	fz_catch(doc->context) {
		return luaL_error(L, "cannot access page tree");
	}
	return 1;
}

/*
 * helper function for getTableOfContent()
 */
static int walkTableOfContent(lua_State *L, fz_outline* ol, int *count, int depth) {
	depth++;
	while(ol) {
		lua_pushnumber(L, *count);

		/* set subtable */
		lua_newtable(L);
		lua_pushstring(L, "page");
		lua_pushnumber(L, ol->dest.ld.gotor.page + 1);
		lua_settable(L, -3);

		lua_pushstring(L, "depth");
		lua_pushnumber(L, depth);
		lua_settable(L, -3);

		lua_pushstring(L, "title");
		lua_pushstring(L, ol->title);
		lua_settable(L, -3);


		lua_settable(L, -3);
		(*count)++;
		if (ol->down) {
			walkTableOfContent(L, ol->down, count, depth);
		}
		ol = ol->next;
	}
	return 0;
}

/*
 * Return a table like this:
 * {
 *		{page=12, depth=1, title="chapter1"},
 *		{page=54, depth=1, title="chapter2"},
 * }
 */
static int getTableOfContent(lua_State *L) {
	fz_outline *ol;
	int count = 1;

	PdfDocument *doc = (PdfDocument*) luaL_checkudata(L, 1, "pdfdocument");
	ol = fz_load_outline(doc->xref);

	lua_newtable(L);
	walkTableOfContent(L, ol, &count, 0);
	return 1;
}

static int openPage(lua_State *L) {
	fz_device *dev;

	PdfDocument *doc = (PdfDocument*) luaL_checkudata(L, 1, "pdfdocument");

	int pageno = luaL_checkint(L, 2);

	fz_try(doc->context) {
		if(pageno < 1 || pageno > fz_count_pages(doc->xref)) {
			return luaL_error(L, "cannot open page #%d, out of range (1-%d)",
					pageno, fz_count_pages(doc->xref));
		}

		PdfPage *page = (PdfPage*) lua_newuserdata(L, sizeof(PdfPage));

		luaL_getmetatable(L, "pdfpage");
		lua_setmetatable(L, -2);

		page->page = fz_load_page(doc->xref, pageno - 1);

		page->doc = doc;
	}
	fz_catch(doc->context) {
		return luaL_error(L, "cannot open page #%d", pageno);
	}
	showMsize();
	return 1;
}

static inline int is_unicode_wspace(int c)
{
	return (c == 9 || /* TAB */
		c == 0x0a || /* HT */
		c == 0x0b || /* LF */
		c == 0x0c || /* VT */
		c == 0x0d || /* FF */
		c == 0x20 || /* CR */
		c == 0x85 || /* NEL */
		c == 0xA0 || /* No break space */
		c == 0x1680 || /* Ogham space mark */
		c == 0x180E || /* Mongolian Vowel Separator */
		c == 0x2000 || /* En quad */
		c == 0x2001 || /* Em quad */
		c == 0x2002 || /* En space */
		c == 0x2003 || /* Em space */
		c == 0x2004 || /* Three-per-Em space */
		c == 0x2005 || /* Four-per-Em space */
		c == 0x2006 || /* Five-per-Em space */
		c == 0x2007 || /* Figure space */
		c == 0x2008 || /* Punctuation space */
		c == 0x2009 || /* Thin space */
		c == 0x200A || /* Hair space */
		c == 0x2028 || /* Line separator */
		c == 0x2029 || /* Paragraph separator */
		c == 0x202F || /* Narrow no-break space */
		c == 0x205F || /* Medium mathematical space */
		c == 0x3000); /* Ideographic space */
}

static inline int
is_unicode_bullet(int c)
{
	/* The last 2 aren't strictly bullets, but will do for our usage here */
	return (c == 0x2022 || /* Bullet */
		c == 0x2023 || /* Triangular bullet */
		c == 0x25e6 || /* White bullet */
		c == 0x2043 || /* Hyphen bullet */
		c == 0x2219 || /* Bullet operator */
		c == 149 || /* Ascii bullet */
		c == '*');
}

static inline int
is_number(int c)
{
	return ((c >= '0' && c <= '9') ||
		(c == '.'));
}

static inline int
is_latin_char(int c)
{
	return ((c >= 'A' && c <= 'Z') ||
		(c >= 'a' && c <= 'z'));
}

static inline int
is_roman(int c)
{
	return (c == 'i' || c == 'I' ||
		c == 'v' || c == 'V' ||
		c == 'x' || c == 'X' ||
		c == 'l' || c == 'L' ||
		c == 'c' || c == 'C' ||
		c == 'm' || c == 'M');
}

static int
is_list_entry(fz_text_line *line, fz_text_span *span, int *char_num_ptr)
{
	int char_num;
	fz_text_char *chr;

	/* First, skip over any whitespace */
	for (char_num = 0; char_num < span->len; char_num++)
	{
		chr = &span->text[char_num];
		if (!is_unicode_wspace(chr->c))
			break;
	}
	*char_num_ptr = char_num;

	if (span != line->first_span || char_num >= span->len)
		return 0;

	/* Now we check for various special cases, which we consider to mean
	 * that this is probably a list entry and therefore should always count
	 * as a separate paragraph (and hence not be entered in the line height
	 * table). */
	chr = &span->text[char_num];

	/* Is the first char on the line, a bullet point? */
	if (is_unicode_bullet(chr->c))
		return 1;

#ifdef SPOT_LINE_NUMBERS
	/* Is the entire first span a number? Or does it start with a number
	 * followed by ) or : ? Allow to involve single latin chars too. */
	if (is_number(chr->c) || is_latin_char(chr->c))
	{
		int cn = char_num;
		int met_char = is_latin_char(chr->c);
		for (cn = char_num+1; cn < span->len; cn++)
		{
			fz_text_char *chr2 = &span->text[cn];

			if (is_latin_char(chr2->c) && !met_char)
			{
				met_char = 1;
				continue;
			}
			met_char = 0;
			if (!is_number(chr2->c) && !is_unicode_wspace(chr2->c))
				break;
			else if (chr2->c == ')' || chr2->c == ':')
			{
				cn = span->len;
				break;
			}
		}
		if (cn == span->len)
			return 1;
	}

	/* Is the entire first span a roman numeral? Or does it start with
	 * a roman numeral followed by ) or : ? */
	if (is_roman(chr->c))
	{
		int cn = char_num;
		for (cn = char_num+1; cn < span->len; cn++)
		{
			fz_text_char *chr2 = &span->text[cn];

			if (!is_roman(chr2->c) && !is_unicode_wspace(chr2->c))
				break;
			else if (chr2->c == ')' || chr2->c == ':')
			{
				cn = span->len;
				break;
			}
		}
		if (cn == span->len)
			return 1;
	}
#endif
	return 0;
}

static void load_lua_text_page(lua_State *L, fz_text_page *page)
{
	fz_text_line *aline;
	fz_text_span *span;

	fz_rect bbox, linebbox, tmpbox;
	int i;
	int word, line, block_num;
	int len, c;
	int start;
	char chars[4]; // max length of UTF-8 encoded rune
	luaL_Buffer textbuf;

	/* table that contains all the lines */
	lua_newtable(L);

	line = 1;

	for (block_num = 0; block_num < page->len; block_num++)
	{
		fz_text_block *block;

		if (page->blocks[block_num].type != FZ_PAGE_BLOCK_TEXT)
			continue;
		block = page->blocks[block_num].u.text;

		for (aline = block->lines; aline < block->lines + block->len; aline++)
		{
			linebbox = fz_empty_rect;
			/* will hold information about a line: */
			lua_newtable(L);

			word = 1;

			for (span = aline->first_span; span; span = span->next)
			{
				if (is_list_entry(aline, span, &i))
					continue;

				for(i = 0; i < span->len; )
				{
					/* will hold information about a word: */
					lua_newtable(L);

					luaL_buffinit(L, &textbuf);
					fz_text_char_bbox(&bbox, span, i); // start with sensible default
					for(; i < span->len; i++) {
						/* check for space characters */
						if (is_unicode_wspace(span->text[i].c)) {
							// ignore and end word
							i++;
							break;
						}
						len = fz_runetochar(chars, span->text[i].c);
						for(c = 0; c < len; c++) {
							luaL_addchar(&textbuf, chars[c]);
						}
						fz_union_rect(&bbox, fz_text_char_bbox(&tmpbox, span, i));
						fz_union_rect(&linebbox, fz_text_char_bbox(&tmpbox, span, i));
						/* check for punctuations and CJK characters */
						if ((span->text[i].c >= 0x4e00 && span->text[i].c <= 0x9FFF) || // CJK Unified Ideographs
							(span->text[i].c >= 0x2000 && span->text[i].c <= 0x206F) || // General Punctuation
							(span->text[i].c >= 0x3000 && span->text[i].c <= 0x303F) || // CJK Symbols and Punctuation
							(span->text[i].c >= 0x3400 && span->text[i].c <= 0x4DBF) || // CJK Unified Ideographs Extension A
							(span->text[i].c >= 0xF900 && span->text[i].c <= 0xFAFF) || // CJK Compatibility Ideographs
							(span->text[i].c >= 0xFF01 && span->text[i].c <= 0xFFEE) || // Halfwidth and Fullwidth Forms
							(span->text[i].c >= 0x20000 && span->text[i].c <= 0x2A6DF)  // CJK Unified Ideographs Extension B
							) {
							i++;
							break;
						}
					}
					lua_pushstring(L, "word");
					luaL_pushresult(&textbuf);
					lua_settable(L, -3);

					/* bbox for a word: */
					lua_pushstring(L, "x0");
					lua_pushinteger(L, bbox.x0);
					lua_settable(L, -3);
					lua_pushstring(L, "y0");
					lua_pushinteger(L, bbox.y0);
					lua_settable(L, -3);
					lua_pushstring(L, "x1");
					lua_pushinteger(L, bbox.x1);
					lua_settable(L, -3);
					lua_pushstring(L, "y1");
					lua_pushinteger(L, bbox.y1);
					lua_settable(L, -3);

					lua_rawseti(L, -2, word++);
				}
			}
			/* bbox for a whole line */
			lua_pushstring(L, "x0");
			lua_pushinteger(L, linebbox.x0);
			lua_settable(L, -3);
			lua_pushstring(L, "y0");
			lua_pushinteger(L, linebbox.y0);
			lua_settable(L, -3);
			lua_pushstring(L, "x1");
			lua_pushinteger(L, linebbox.x1);
			lua_settable(L, -3);
			lua_pushstring(L, "y1");
			lua_pushinteger(L, linebbox.y1);
			lua_settable(L, -3);

			lua_rawseti(L, -2, line++);
		}
	}
}

/* get the text of the given page
 *
 * will return text in a Lua table that is modeled after
 * djvu.c creates this table.
 *
 * note that the definition of "line" is somewhat arbitrary
 * here (for now)
 *
 * MuPDFs API provides text as single char information
 * that is collected in "spans". we use a span as a "line"
 * in Lua output and segment spans into words by looking
 * for space characters.
 *
 * will return an empty table if we have no text
 */
static int getPageText(lua_State *L) {
	fz_text_page *text_page;
	fz_text_sheet *text_sheet;
	fz_device *tdev;

	PdfPage *page = (PdfPage*) luaL_checkudata(L, 1, "pdfpage");

	text_page = fz_new_text_page(page->doc->context);
	text_sheet = fz_new_text_sheet(page->doc->context);
	tdev = fz_new_text_device(page->doc->context, text_sheet, text_page);
	fz_run_page(page->doc->xref, page->page, tdev, &fz_identity, NULL);
	fz_free_device(tdev);
	tdev = NULL;

	load_lua_text_page(L, text_page);

	fz_free_text_page(page->doc->context, text_page);
	fz_free_text_sheet(page->doc->context, text_sheet);

	return 1;
}

static int getPageSize(lua_State *L) {
	fz_matrix ctm, tmp1, tmp2;
	fz_rect bounds;
	fz_irect bbox;
	PdfPage *page = (PdfPage*) luaL_checkudata(L, 1, "pdfpage");
	DrawContext *dc = (DrawContext*) lua_topointer(L, 2);

	fz_bound_page(page->doc->xref, page->page, &bounds);
	fz_scale(&tmp1, dc->zoom, dc->zoom);
	fz_concat(&ctm, &tmp1, fz_rotate(&tmp2, dc->rotate));
	fz_transform_rect(&bounds, &ctm);
	fz_round_rect(&bbox, &bounds);

	lua_pushnumber(L, bbox.x1-bbox.x0);
	lua_pushnumber(L, bbox.y1-bbox.y0);

	return 2;
}

static int getUsedBBox(lua_State *L) {
	fz_rect result;
	fz_matrix ctm;
	fz_device *dev;
	PdfPage *page = (PdfPage*) luaL_checkudata(L, 1, "pdfpage");

	/* returned BBox is in centi-point (n * 0.01 pt) */
	fz_scale(&ctm, 1.0, 1.0);

	fz_try(page->doc->context) {
		dev = fz_new_bbox_device(page->doc->context, &result);
		fz_run_page(page->doc->xref, page->page, dev, &ctm, NULL);
	}
	fz_always(page->doc->context) {
		fz_free_device(dev);
	}
	fz_catch(page->doc->context) {
		return luaL_error(L, "cannot calculate bbox for page");
	}

	lua_pushnumber(L, result.x0);
	lua_pushnumber(L, result.y0);
	lua_pushnumber(L, result.x1);
	lua_pushnumber(L, result.y1);

	return 4;
}

static int closePage(lua_State *L) {
	PdfPage *page = (PdfPage*) luaL_checkudata(L, 1, "pdfpage");
	if(page->page != NULL) {
		fz_free_page(page->doc->xref, page->page);
		page->page = NULL;
	}
	return 0;
}

/* bmpmupdf.c from willuslib */
static int bmpmupdf_pixmap_to_bmp(WILLUSBITMAP *bmp, fz_context *ctx, fz_pixmap *pixmap) {
	unsigned char *p;
	int ncomp, i, row, col;

	bmp->width = fz_pixmap_width(ctx, pixmap);
	bmp->height = fz_pixmap_height(ctx, pixmap);
	ncomp = fz_pixmap_components(ctx, pixmap);
	/* Has to be 8-bit or RGB */
	if (ncomp != 2 && ncomp != 4)
		return (-1);
	bmp->bpp = (ncomp == 2) ? 8 : 24;
	bmp_alloc(bmp);
	if (ncomp == 2)
		for (i = 0; i < 256; i++)
			bmp->red[i] = bmp->green[i] = bmp->blue[i] = i;
	p = fz_pixmap_samples(ctx, pixmap);
	if (ncomp == 1)
		for (row = 0; row < bmp->height; row++) {
			unsigned char *dest;
			dest = bmp_rowptr_from_top(bmp, row);
			memcpy(dest, p, bmp->width);
			p += bmp->width;
		}
	else if (ncomp == 2)
		for (row = 0; row < bmp->height; row++) {
			unsigned char *dest;
			dest = bmp_rowptr_from_top(bmp, row);
			for (col = 0; col < bmp->width; col++, dest++, p += 2)
				dest[0] = p[0];
		}
	else
		for (row = 0; row < bmp->height; row++) {
			unsigned char *dest;
			dest = bmp_rowptr_from_top(bmp, row);
			for (col = 0; col < bmp->width;
					col++, dest += ncomp - 1, p += ncomp)
				memcpy(dest, p, ncomp - 1);
		}
	return (0);
}

// store page pix in src bmp in koptcontext for later processing
static int getPagePix(lua_State *L) {
	PdfPage *page = (PdfPage*) luaL_checkudata(L, 1, "pdfpage");
	KOPTContext *kctx = (KOPTContext*) lua_topointer(L, 2);
	fz_device *dev;
	fz_pixmap *pix;
	fz_matrix ctm;
	fz_rect bounds;
	fz_irect bbox;

	pix = NULL;
	fz_var(pix);
	bounds.x0 = kctx->bbox.x0;
    bounds.y0 = kctx->bbox.y0;
    bounds.x1 = kctx->bbox.x1;
    bounds.y1 = kctx->bbox.y1;

    fz_scale(&ctm, kctx->zoom, kctx->zoom);
    fz_transform_rect(&bounds, &ctm);
    fz_round_rect(&bbox, &bounds);

	fz_try(page->doc->context) {
		pix = fz_new_pixmap_with_bbox(page->doc->context, fz_device_gray(page->doc->context), &bbox);
		fz_clear_pixmap_with_value(page->doc->context, pix, 0xff);
		dev = fz_new_draw_device(page->doc->context, pix);
		fz_run_page_contents(page->doc->xref, page->page, dev, &ctm, NULL);
	}
	fz_always(page->doc->context) {
		fz_free_device(dev);
	}
	fz_catch(page->doc->context) {
		return luaL_error(L, "cannot calculate bbox for page");
	}

	WILLUSBITMAP *dst = &kctx->src;
	bmp_init(dst);

	bmpmupdf_pixmap_to_bmp(dst, page->doc->context, pix);

	kctx->page_width = dst->width;
	kctx->page_height = dst->height;

	fz_drop_pixmap(page->doc->context, pix);

	return 0;
}

static int reflowPage(lua_State *L) {
	PdfPage *page = (PdfPage*) luaL_checkudata(L, 1, "pdfpage");
	KOPTContext *kctx = (KOPTContext*) lua_topointer(L, 2);
	fz_device *dev;
	fz_pixmap *pix;
	fz_matrix ctm;
	fz_rect bounds;
	fz_irect bbox;

	pix = NULL;
	fz_var(pix);
	bounds.x0 = kctx->bbox.x0;
	bounds.y0 = kctx->bbox.y0;
	bounds.x1 = kctx->bbox.x1;
	bounds.y1 = kctx->bbox.y1;

	// probe scale
	double zoom = kctx->zoom*kctx->quality;
	float scale = 1.0;
	fz_scale(&ctm, scale, scale);
	fz_transform_rect(&bounds, &ctm);
	fz_round_rect(&bbox, &bounds);
	scale /= ((double)bbox.x1 / (2*zoom*kctx->dev_width) + \
			  (double)bbox.y1 / (2*zoom*kctx->dev_height))/2;
	// store zoom
	kctx->zoom = scale;
	// do real scale
	fz_scale(&ctm, scale, scale);
	fz_transform_rect(&bounds, &ctm);
	fz_round_rect(&bbox, &bounds);
	printf("reading page:%d,%d,%d,%d scale:%.2f\n",bbox.x0,bbox.y0,bbox.x1,bbox.y1,scale);

	pix = fz_new_pixmap_with_bbox(page->doc->context, fz_device_gray(page->doc->context), &bbox);
	fz_clear_pixmap_with_value(page->doc->context, pix, 0xff);
	dev = fz_new_draw_device(page->doc->context, pix);

#ifdef MUPDF_TRACE
	fz_device *tdev;
	fz_try(page->doc->context) {
		tdev = fz_new_trace_device(page->doc->context);
		fz_run_page(page->doc->xref, page->page, tdev, &ctm, NULL);
	}
	fz_always(page->doc->context) {
		fz_free_device(tdev);
	}
#endif

	fz_run_page_contents(page->doc->xref, page->page, dev, &ctm, NULL);
	fz_free_device(dev);

	WILLUSBITMAP *src = &kctx->src;
	bmp_init(src);

	int status = bmpmupdf_pixmap_to_bmp(src, page->doc->context, pix);
	fz_drop_pixmap(page->doc->context, pix);

	if (kctx->precache) {
		pthread_t rf_thread;
		pthread_attr_t attr;
		pthread_attr_init(&attr);
		pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
		pthread_create( &rf_thread, &attr, k2pdfopt_reflow_bmp, (void*) kctx);
		pthread_attr_destroy(&attr);
	} else {
		k2pdfopt_reflow_bmp(kctx);
	}

	return 0;
}

static int drawPage(lua_State *L) {
	fz_pixmap *pix;
	fz_device *dev;
	fz_matrix ctm, tmp1, tmp2, tmp3;
	fz_irect bbox;

	PdfPage *page = (PdfPage*) luaL_checkudata(L, 1, "pdfpage");
	DrawContext *dc = (DrawContext*) lua_topointer(L, 2);
	BlitBuffer *bb = (BlitBuffer*) lua_topointer(L, 3);
	bbox.x0 = luaL_checkint(L, 4);
	bbox.y0 = luaL_checkint(L, 5);
	bbox.x1 = bbox.x0 + bb->w;
	bbox.y1 = bbox.y0 + bb->h;
	pix = fz_new_pixmap_with_bbox(page->doc->context, fz_device_gray(page->doc->context), &bbox);
	fz_clear_pixmap_with_value(page->doc->context, pix, 0xff);

	fz_scale(&tmp1, dc->zoom, dc->zoom);
	fz_concat(&tmp3, &tmp1, fz_rotate(&tmp2, dc->rotate));
	fz_concat(&ctm, &tmp3, fz_translate(&tmp1, dc->offset_x, dc->offset_y));
	dev = fz_new_draw_device(page->doc->context, pix);
#ifdef MUPDF_TRACE
	fz_device *tdev;
	fz_try(page->doc->context) {
		tdev = fz_new_trace_device(page->doc->context);
		fz_run_page(page->doc->xref, page->page, tdev, &ctm, NULL);
	}
	fz_always(page->doc->context) {
		fz_free_device(tdev);
	}
#endif
	fz_run_page(page->doc->xref, page->page, dev, &ctm, NULL);
	fz_free_device(dev);

	if(dc->gamma >= 0.0) {
		fz_gamma_pixmap(page->doc->context, pix, dc->gamma);
	}

	uint8_t *bbptr = (uint8_t*)bb->data;
	uint16_t *pmptr = (uint16_t*)pix->samples;
	int x, y;

	for(y = 0; y < bb->h; y++) {
		for(x = 0; x < (bb->w / 2); x++) {
			bbptr[x] = (((pmptr[x*2 + 1] & 0xF0) >> 4) | (pmptr[x*2] & 0xF0)) ^ 0xFF;
		}
		if(bb->w & 1) {
			bbptr[x] = (pmptr[x*2] & 0xF0) ^ 0xF0;
		}
		bbptr += bb->pitch;
		pmptr += bb->w;
	}

	fz_drop_pixmap(page->doc->context, pix);

	return 0;
}

static int getCacheSize(lua_State *L) {
	//printf("## mupdf getCacheSize = %zu\n", msize);
	lua_pushnumber(L, msize);
	return 1;
}

static int cleanCache(lua_State *L) {
	//printf("## mupdf cleanCache NOP\n");
	return 0;
}


static int getPageLinks(lua_State *L) {
	fz_link *page_links;
	fz_link *link;

	int link_count;

	PdfPage *page = (PdfPage*) luaL_checkudata(L, 1, "pdfpage");

	page_links = fz_load_links(page->doc->xref, page->page); // page->doc->xref?

	lua_newtable(L); // all links

	link_count = 0;

	for (link = page_links; link; link = link->next) {
		lua_newtable(L); // new link

		lua_pushstring(L, "x0");
		lua_pushinteger(L, link->rect.x0);
		lua_settable(L, -3);
		lua_pushstring(L, "y0");
		lua_pushinteger(L, link->rect.y0);
		lua_settable(L, -3);
		lua_pushstring(L, "x1");
		lua_pushinteger(L, link->rect.x1);
		lua_settable(L, -3);
		lua_pushstring(L, "y1");
		lua_pushinteger(L, link->rect.y1);
		lua_settable(L, -3);

		if (link->dest.kind == FZ_LINK_URI) {
			lua_pushstring(L, "uri");
			lua_pushstring(L, link->dest.ld.uri.uri);
			lua_settable(L, -3);
		} else if (link->dest.kind == FZ_LINK_GOTO) {
			lua_pushstring(L, "page");
			lua_pushinteger(L, link->dest.ld.gotor.page); // FIXME page+1?
			lua_settable(L, -3);
		} else {
			printf("ERROR: unkown link kind: %x", link->dest.kind);
		}

		lua_rawseti(L, -2, ++link_count);
    }

	//printf("## getPageLinks found %d links in document\n", link_count);

	fz_drop_link(page->doc->context, page_links);

	return 1;
}

#define STRIKE_HEIGHT (0.375f)
#define UNDERLINE_HEIGHT (0.075f)
#define LINE_THICKNESS (0.07f)

static int addMarkupAnnotation(lua_State *L) {
	PdfPage *page = (PdfPage*) luaL_checkudata(L, 1, "pdfpage");
	fz_context *ctx = page->doc->context;
	fz_point *pts = (fz_point*) lua_topointer(L, 2);
	int n = luaL_checkint(L, 3);
	fz_annot_type type = luaL_checkint(L, 4);

	float color[3];
	float alpha;
	float line_height;
	float line_thickness;
	switch (type) {
		case FZ_ANNOT_HIGHLIGHT:
			color[0] = 1.0;
			color[1] = 1.0;
			color[2] = 0.0;
			alpha = 0.5;
			line_thickness = 1.0;
			line_height = 0.5;
			break;
		case FZ_ANNOT_UNDERLINE:
			color[0] = 0.0;
			color[1] = 0.0;
			color[2] = 1.0;
			alpha = 1.0;
			line_thickness = LINE_THICKNESS;
			line_height = UNDERLINE_HEIGHT;
			break;
		case FZ_ANNOT_STRIKEOUT:
			color[0] = 1.0;
			color[1] = 0.0;
			color[2] = 0.0;
			alpha = 1.0;
			line_thickness = LINE_THICKNESS;
			line_height = STRIKE_HEIGHT;
			break;
		default:
			return 0;
	}

	pdf_document * doc = pdf_specifics(page->doc->xref);
	fz_try(ctx) {
		fz_annot *annot = pdf_create_annot(doc, (pdf_page *)page->page, type);
		pdf_set_markup_annot_quadpoints(doc, (pdf_annot *)annot, pts, n);
		pdf_set_markup_appearance(doc, (pdf_annot *)annot, color, alpha, line_thickness, line_height);
	} fz_catch(ctx) {
		printf("addMarkupAnnotation: %s failed\n", ctx->error->message);
	}

	return 1;
}

static int writeDocument(lua_State *L) {
	PdfDocument *doc = (PdfDocument*) luaL_checkudata(L, 1, "pdfdocument");
	char *file = luaL_checkstring(L, 2);
	fz_write_options opts;
	opts.do_incremental = 1;
	opts.do_ascii = 0;
	opts.do_expand = 0;
	opts.do_garbage = 0;
	opts.do_linear = 0;
	opts.continue_on_error = 1;
	fz_write_document(doc->xref, file, &opts);

	return 1;
}

static const struct luaL_Reg pdf_func[] = {
	{"openDocument", openDocument},
	{NULL, NULL}
};

static const struct luaL_Reg pdfdocument_meth[] = {
	{"needsPassword", needsPassword},
	{"authenticatePassword", authenticatePassword},
	{"openPage", openPage},
	{"getPages", getNumberOfPages},
	{"getToc", getTableOfContent},
	{"close", closeDocument},
	{"getCacheSize", getCacheSize},
	{"cleanCache", cleanCache},
	{"writeDocument", writeDocument},
	{"__gc", closeDocument},
	{NULL, NULL}
};

static const struct luaL_Reg pdfpage_meth[] = {
	{"getSize", getPageSize},
	{"getUsedBBox", getUsedBBox},
	{"getPagePix", getPagePix},
	{"getPageText", getPageText},
	{"getPageLinks", getPageLinks},
	{"addMarkupAnnotation", addMarkupAnnotation},
	{"close", closePage},
	{"__gc", closePage},
	{"reflow", reflowPage},
	{"draw", drawPage},
	{NULL, NULL}
};

int luaopen_pdf(lua_State *L) {
	luaL_newmetatable(L, "pdfdocument");
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);
	lua_settable(L, -3);
	luaL_register(L, NULL, pdfdocument_meth);
	lua_pop(L, 1);
	luaL_newmetatable(L, "pdfpage");
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);
	lua_settable(L, -3);
	luaL_register(L, NULL, pdfpage_meth);
	lua_pop(L, 1);
	luaL_register(L, "pdf", pdf_func);
	return 1;
}
