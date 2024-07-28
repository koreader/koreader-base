/*
    KindlePDFViewer: DjvuLibre abstraction for Lua
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

#include <stdint.h>
#include <math.h>
#include <string.h>
#include <errno.h>
#include <pthread.h>
#include <assert.h>
#include <libdjvu/miniexp.h>
#include <libdjvu/ddjvuapi.h>

#include "blitbuffer.h"
#include "drawcontext.h"
#include "koptcontext.h"
#include "k2pdfopt.h"
#include "koptreflow.h"
#include "koptcrop.h"
#include "djvu.h"

#define ABS(x) ((x<0)?(-x):(x))

#define MIN(a, b)      ((a) < (b) ? (a) : (b))
#define MAX(a, b)      ((a) > (b) ? (a) : (b))

#define LUA_SETTABLE_STACK_TOP   ((int)-3)
#define lua_setkeyval(L, type, key, val) do { \
	lua_pushstring(L, key); \
	lua_push##type(L, val); \
	lua_rawset(L, LUA_SETTABLE_STACK_TOP); \
} while(0)


typedef struct DjvuDocument {
	ddjvu_context_t *context;
	ddjvu_document_t *doc_ref;
	ddjvu_format_t *pixelformat;
	int pixelsize;
} DjvuDocument;

typedef struct DjvuPage {
	int num;
	ddjvu_page_t *page_ref;
	ddjvu_pageinfo_t info;
	DjvuDocument *doc;
} DjvuPage;


typedef enum DjvuZoneId {
	ZI_PAGE,
	ZI_COLUMN,
	ZI_REGION,
	ZI_PARA,
	ZI_LINE,
	ZI_WORD,
	ZI_CHAR,
	N_ZI
} DjvuZoneId;

typedef enum DjvuZoneSexpIdx {
	SI_ZONE_NAME,
	SI_ZONE_XMIN,
	SI_ZONE_YMIN,
	SI_ZONE_XMAX,
	SI_ZONE_YMAX,
	SI_ZONE_DATA,
	N_SI_ZONE
} DjvuZoneSexpIdx;

static const char *djvuZoneLuaKey[N_SI_ZONE] = {
	NULL,
	"x0",
	"y1",
	"x1",
	"y0",
	NULL
};


int int_from_miniexp_nth(int n, miniexp_t sexp) {
	miniexp_t s = miniexp_nth(n, sexp);
	return (miniexp_numberp(s) ? miniexp_to_int(s) : ((int)0));
}

#ifdef DEBUG

static const char *render_mode_str(ddjvu_render_mode_t mode) {
    switch (mode) {
    case DDJVU_RENDER_COLOR:
        return "color";
    case DDJVU_RENDER_BLACK:
        return "black";
    case DDJVU_RENDER_COLORONLY:
        return "coloronly";
    case DDJVU_RENDER_MASKONLY:
        return "maskonly";
    case DDJVU_RENDER_BACKGROUND:
        return "background";
    case DDJVU_RENDER_FOREGROUND:
        return "foreground";
    default:
        return "???";
    }
}

#endif

static int handle(lua_State *L, ddjvu_context_t *ctx, int wait)
{
	const ddjvu_message_t *msg;
	if (!ctx)
		return -1;
	if (wait)
		ddjvu_message_wait(ctx);
	while ((msg = ddjvu_message_peek(ctx)))
	{
	  switch(msg->m_any.tag)
		{
		case DDJVU_ERROR:
			if (msg->m_error.filename) {
				return luaL_error(L, "ddjvu: %s\nddjvu: '%s:%d'\n",
					msg->m_error.message, msg->m_error.filename,
					msg->m_error.lineno);
			} else {
				return luaL_error(L, "ddjvu: %s\n", msg->m_error.message);
			}
		default:
		  break;
		}
	  ddjvu_message_pop(ctx);
	}

	return 0;
}

static int openDocument(lua_State *L) {
	const char *filename = luaL_checkstring(L, 1);
	int color = lua_toboolean(L, 2);
	int cache_size = luaL_optint(L, 3, 10 << 20);

	DjvuDocument *doc = (DjvuDocument*) lua_newuserdata(L, sizeof(DjvuDocument));
	luaL_getmetatable(L, "djvudocument");
	lua_setmetatable(L, -2);

	doc->context = ddjvu_context_create("kindlepdfviewer");
	if (! doc->context) {
		return luaL_error(L, "cannot create context");
	}

	//printf("## cache_size = %d\n", cache_size);
	ddjvu_cache_set_size(doc->context, (unsigned long)cache_size);

	doc->doc_ref = ddjvu_document_create_by_filename_utf8(doc->context, filename, TRUE);
	if (! doc->doc_ref) {
		int res = handle(L, doc->context, FALSE);
		if (res != 0) return res;
		// in case we didn't get a more detailed error message
		return luaL_error(L, "cannot open DjVu file <%s>", filename);
	}
	while (! ddjvu_document_decoding_done(doc->doc_ref))
		handle(L, doc->context, True);

	if (color) {
		doc->pixelsize = 3;
		doc->pixelformat = ddjvu_format_create(DDJVU_FORMAT_RGB24, 0, NULL);
	}
	else {
		doc->pixelsize = 1;
		doc->pixelformat = ddjvu_format_create(DDJVU_FORMAT_GREY8, 0, NULL);
	}
	if (! doc->pixelformat) {
		return luaL_error(L, "cannot create DjVu pixelformat for <%s>", filename);
	}
	ddjvu_format_set_row_order(doc->pixelformat, 1);
	ddjvu_format_set_y_direction(doc->pixelformat, 1);
	/* dithering bits <8 are ignored by djvulibre */
	/* ddjvu_format_set_ditherbits(doc->pixelformat, 4); */

	return 1;
}

static int closeDocument(lua_State *L) {
	DjvuDocument *doc = (DjvuDocument*) luaL_checkudata(L, 1, "djvudocument");

	// should be safe if called twice
	if (doc->doc_ref != NULL) {
		ddjvu_document_release(doc->doc_ref);
		doc->doc_ref = NULL;
	}
	if (doc->context != NULL) {
		ddjvu_context_release(doc->context);
		doc->context = NULL;
	}
	if (doc->pixelformat != NULL) {
		ddjvu_format_release(doc->pixelformat);
		doc->pixelformat = NULL;
	}
	return 0;
}

static int setColorRendering(lua_State *L) {
	DjvuDocument *doc = (DjvuDocument*) luaL_checkudata(L, 1, "djvudocument");
	int color = lua_toboolean(L, 2);
#ifdef DEBUG
	printf("%s: %s\n", __func__, color ? "color" : "grey");
#endif
	if (doc->pixelformat != NULL) {
		ddjvu_format_release(doc->pixelformat);
		doc->pixelformat = NULL;
	}
	if (color) {
		doc->pixelsize = 3;
		doc->pixelformat = ddjvu_format_create(DDJVU_FORMAT_RGB24, 0, NULL);
	}
	else {
		doc->pixelsize = 1;
		doc->pixelformat = ddjvu_format_create(DDJVU_FORMAT_GREY8, 0, NULL);
	}
	ddjvu_format_set_row_order(doc->pixelformat, 1);
	ddjvu_format_set_y_direction(doc->pixelformat, 1);
	return 0;
}

static int getMetadata(lua_State *L) {
	DjvuDocument *doc = (DjvuDocument*) luaL_checkudata(L, 1, "djvudocument");
	miniexp_t anno = ddjvu_document_get_anno(doc->doc_ref, 1);
	miniexp_t *keys = ddjvu_anno_get_metadata_keys(anno);

	// `keys` can be null if there's an error. In that case,
	// we have the choice of returning either `nil` or
	// the empty table back to lua.  Here we prefer the latter.
	lua_newtable(L);
	if (!keys) return 1;

	int i;
	for (i = 0; keys[i] != miniexp_nil; i++) {
		const char *value = ddjvu_anno_get_metadata(anno, keys[i]);

		if (value) {
			lua_pushstring(L, miniexp_to_name(keys[i]));
			lua_pushstring(L, value);
			lua_rawset(L, -3);
		}
	}

	if (keys) free(keys);
	return 1;
}

static int getNumberOfPages(lua_State *L) {
	DjvuDocument *doc = (DjvuDocument*) luaL_checkudata(L, 1, "djvudocument");
	lua_pushinteger(L, ddjvu_document_get_pagenum(doc->doc_ref));
	return 1;
}

static void walkTableOfContent(lua_State *L, miniexp_t r, int *count, int depth) {
	depth++;

	miniexp_t lista = miniexp_cdr(r); // go inside bookmarks in the list

	int length = miniexp_length(r) - 1; // Minus the sentinel NUL
	int counter = 0;
	while (counter < length) {
		lua_createtable(L, 0, 3);

		lua_pushstring(L, "page");
		const char* page_name = miniexp_to_str(miniexp_car(miniexp_cdr(miniexp_nth(counter, lista))));
		if (page_name != NULL && page_name[0] == '#') {
			errno = 0;
			uint32_t page_name_num_idx = 1U;  /* skip leading # */
			while (page_name[page_name_num_idx] && !isdigit(page_name[page_name_num_idx])) {
				page_name_num_idx++;
			}
			int page_number = (int) strtol(page_name+page_name_num_idx, NULL, 10);
			if (!errno) {
				lua_pushinteger(L, page_number);
			} else {
				/* we can not parse this as a number, TODO: parse page names */
				lua_pushinteger(L, -1);
			}
		} else {
			/* something we did not expect here */
			lua_pushinteger(L, -1);
		}
		lua_rawset(L, -3);

		lua_pushstring(L, "depth");
		lua_pushinteger(L, depth);
		lua_rawset(L, -3);

		lua_pushstring(L, "title");
		lua_pushstring(L, miniexp_to_str(miniexp_car(miniexp_nth(counter, lista))));
		lua_rawset(L, -3);

		lua_rawseti(L, -2, (*count)++);

		if (miniexp_length(miniexp_cdr(miniexp_nth(counter, lista))) > 1) {
			walkTableOfContent(L, miniexp_cdr(miniexp_nth(counter, lista)), count, depth);
		}
		counter++;
	}
}

static int getTableOfContent(lua_State *L) {
	DjvuDocument *doc = (DjvuDocument*) luaL_checkudata(L, 1, "djvudocument");
	lua_settop(L, 0); // Pop function arg

	miniexp_t r;
	while ((r=ddjvu_document_get_outline(doc->doc_ref))==miniexp_dummy)
		handle(L, doc->context, True);

	//printf("lista: %s\n", miniexp_to_str(miniexp_car(miniexp_nth(1, miniexp_cdr(r)))));

	lua_createtable(L, miniexp_length(r) - 1, 0); // pre-alloc for top-level elements, at least
	int count = 1;
	walkTableOfContent(L, r, &count, 0);

	return 1;
}

static int openPage(lua_State *L) {
	ddjvu_status_t r;
	DjvuDocument *doc = (DjvuDocument*) luaL_checkudata(L, 1, "djvudocument");
	int pageno = luaL_checkint(L, 2);

	if (pageno < 1 || pageno > ddjvu_document_get_pagenum(doc->doc_ref)) {
		return luaL_error(L, "cannot open page #%d, out of range (1-%d)", pageno, ddjvu_document_get_pagenum(doc->doc_ref));
	}

	DjvuPage *page = (DjvuPage*) lua_newuserdata(L, sizeof(DjvuPage));
	luaL_getmetatable(L, "djvupage");
	lua_setmetatable(L, -2);

	/* djvulibre counts page starts from 0 */
	page->page_ref = ddjvu_page_create_by_pageno(doc->doc_ref, pageno - 1);
	if (! page->page_ref)
		return luaL_error(L, "cannot open page #%d", pageno);
	while (! ddjvu_page_decoding_done(page->page_ref))
		handle(L, doc->context, TRUE);

	page->doc = doc;
	page->num = pageno;

	/* djvulibre counts page starts from 0 */
	while((r=ddjvu_document_get_pageinfo(doc->doc_ref, pageno - 1,
										&(page->info)))<DDJVU_JOB_OK)
		handle(L, doc->context, TRUE);
	if (r>=DDJVU_JOB_FAILED)
		return luaL_error(L, "cannot get page #%d information", pageno);

	return 1;
}

/* get page size after zoomed */
static int getPageSize(lua_State *L) {
	DjvuPage *page = (DjvuPage*) luaL_checkudata(L, 1, "djvupage");
	DrawContext *dc = (DrawContext*) lua_topointer(L, 2);

	lua_pushnumber(L, dc->zoom * page->info.width);
	lua_pushnumber(L, dc->zoom * page->info.height);

	return 2;
}

/* unsupported so fake it */
static int getUsedBBox(lua_State *L) {
	lua_pushnumber(L, (double)0.01);
	lua_pushnumber(L, (double)0.01);
	lua_pushnumber(L, (double)-0.01);
	lua_pushnumber(L, (double)-0.01);
	return 4;
}

static int getOriginalPageSize(lua_State *L) {
	DjvuDocument *doc = (DjvuDocument*) luaL_checkudata(L, 1, "djvudocument");
	int pageno = luaL_checkint(L, 2);

	ddjvu_status_t r;
	ddjvu_pageinfo_t info;

	while ((r=ddjvu_document_get_pageinfo(
				   doc->doc_ref, pageno-1, &info))<DDJVU_JOB_OK) {
		handle(L, doc->context, TRUE);
	}

	lua_pushinteger(L, info.width);
	lua_pushinteger(L, info.height);

	return 2;
}

static int getPageInfo(lua_State *L) {
	DjvuDocument *doc = (DjvuDocument*) luaL_checkudata(L, 1, "djvudocument");
	int pageno = luaL_checkint(L, 2);

	ddjvu_page_t *djvu_page = ddjvu_page_create_by_pageno(doc->doc_ref, pageno - 1);
	if (! djvu_page)
		return luaL_error(L, "cannot create djvu_page #%d", pageno);

	while (! ddjvu_page_decoding_done(djvu_page))
		handle(L, doc->context, TRUE);

	int page_width = ddjvu_page_get_width(djvu_page);
	lua_pushinteger(L, page_width);

	int page_height = ddjvu_page_get_height(djvu_page);
	lua_pushinteger(L, page_height);

	int page_dpi = ddjvu_page_get_resolution(djvu_page);
	lua_pushinteger(L, page_dpi);

	double page_gamma = ddjvu_page_get_gamma(djvu_page);
	lua_pushnumber(L, page_gamma);

	const char *page_type_str;
	ddjvu_page_type_t page_type = ddjvu_page_get_type(djvu_page);
	switch (page_type) {
		case DDJVU_PAGETYPE_UNKNOWN:
			page_type_str = "UNKNOWN";
			break;

		case DDJVU_PAGETYPE_BITONAL:
			page_type_str = "BITONAL";
			break;

		case DDJVU_PAGETYPE_PHOTO:
			page_type_str = "PHOTO";
			break;

		case DDJVU_PAGETYPE_COMPOUND:
			page_type_str = "COMPOUND";
			break;

		default:
			page_type_str = "INVALID";
			break;
	}
	lua_pushstring(L, page_type_str);

	ddjvu_page_release(djvu_page);

	return 5;
}

/** Fill Lua table with DjVu text annotations
 *
 * This simply maps the S-expression structure of `anno` into a Lua table, @see
 * djvused(1) for details.
 *
 * @param L        Lua state. Table to be filled should exist at top of stack.
 * @param yheight  Page height. DjVu zones are origined at the bottom-left, but
 *                   koptinterface convention origins at top-left.
 */
void lua_settable_djvu_anno(lua_State *L, miniexp_t anno, int yheight) {
	if (!L) {
		return;
	}
	if (!miniexp_consp(anno)) {
		return;
	}

	miniexp_t anno_type = miniexp_nth(SI_ZONE_NAME, anno);
	if (!miniexp_symbolp(anno_type)) {
		return;
	}

	int xmin = int_from_miniexp_nth(SI_ZONE_XMIN, anno);
	int ymin = int_from_miniexp_nth(SI_ZONE_YMIN, anno);
	int xmax = int_from_miniexp_nth(SI_ZONE_XMAX, anno);
	int ymax = int_from_miniexp_nth(SI_ZONE_YMAX, anno);

	lua_setkeyval(L, integer, djvuZoneLuaKey[SI_ZONE_XMIN], xmin);
	lua_setkeyval(L, integer, djvuZoneLuaKey[SI_ZONE_YMIN], yheight - ymin);
	lua_setkeyval(L, integer, djvuZoneLuaKey[SI_ZONE_XMAX], xmax);
	lua_setkeyval(L, integer, djvuZoneLuaKey[SI_ZONE_YMAX], yheight - ymax);

	for (int i = SI_ZONE_DATA; i < miniexp_length(anno); i++) {
		miniexp_t data = miniexp_nth(i, anno);
		int tindex = i - SI_ZONE_DATA + 1; // Lua tables are 1-indexed

		if (miniexp_stringp(data)) {
			const char *zname = miniexp_to_name(anno_type);
			const char *txt = miniexp_to_str(data);
			lua_setkeyval(L, string, zname, txt);
		} else {
			// New line or word!
			lua_createtable(L, miniexp_length(data) - SI_ZONE_DATA, 4); // line/word = {}; pre-allocated to the correct amount of elements and its own box
			lua_settable_djvu_anno(L, data, yheight);
			// We're done with it, insert it in the page/line array
			lua_rawseti(L, -2, tindex);
		}
	}
}

static int getPageText(lua_State *L) {
	DjvuDocument *doc = (DjvuDocument*) luaL_checkudata(L, 1, "djvudocument");
	int pageno = luaL_checkint(L, 2);
	lua_settop(L, 0); // Pop function args

	/* get page height for coordinates transform */
	ddjvu_pageinfo_t info;
	ddjvu_status_t r;
	while ((r=ddjvu_document_get_pageinfo(
				   doc->doc_ref, pageno-1, &info))<DDJVU_JOB_OK) {
		handle(L, doc->context, TRUE);
	}
	if (r>=DDJVU_JOB_FAILED)
		return luaL_error(L, "cannot get page #%d information", pageno);

	/* start retrieving page text */
	miniexp_t sexp;

	while ((sexp = ddjvu_document_get_pagetext(doc->doc_ref, pageno-1, "word"))
				== miniexp_dummy) {
		handle(L, doc->context, True);
	}

	lua_createtable(L, miniexp_length(sexp) - SI_ZONE_DATA, 4); // page = {}; pre-allocated to the correct amount of lines and its page box
	lua_settable_djvu_anno(L, sexp, info.height);
	return 1;
}

static int closePage(lua_State *L) {
	DjvuPage *page = (DjvuPage*) luaL_checkudata(L, 1, "djvupage");

	// should be safe if called twice
	if (page->page_ref != NULL) {
		ddjvu_page_release(page->page_ref);
		page->page_ref = NULL;
	}
	return 0;
}

static int getPagePix(lua_State *L) {
	DjvuPage *page = (DjvuPage*) luaL_checkudata(L, 1, "djvupage");
	KOPTContext *kctx = (KOPTContext*) lua_topointer(L, 2);
	ddjvu_render_mode_t mode = (int) luaL_checkint(L, 3);
	ddjvu_rect_t prect;
	ddjvu_rect_t rrect;
	int px, py, pw, ph, rx, ry, rw, rh;

	px = 0;
    py = 0;
    pw = ddjvu_page_get_width(page->page_ref);
    ph = ddjvu_page_get_height(page->page_ref);
    prect.x = px;
    prect.y = py;

	rx = (int)kctx->bbox.x0;
    ry = (int)kctx->bbox.y0;
    rw = (int)(kctx->bbox.x1 - kctx->bbox.x0);
    rh = (int)(kctx->bbox.y1 - kctx->bbox.y0);

    float scale = kctx->zoom;

    prect.w = pw * scale;
    prect.h = ph * scale;
    rrect.x = rx * scale;
    rrect.y = ry * scale;
    rrect.w = rw * scale;
    rrect.h = rh * scale;
#ifdef DEBUG
    printf("%s: rendering page: %u (%d,%d,%d,%d) [%s:%s]\n", __func__, page->num,
           rrect.x, rrect.y, rrect.w, rrect.h,
           page->doc->pixelsize == 3 ? "color" : "grey", render_mode_str(mode));
#endif

	WILLUSBITMAP *dst = &kctx->src;
	bmp_init(dst);
	dst->width = rrect.w;
	dst->height = rrect.h;
	dst->bpp = 8*page->doc->pixelsize;
	bmp_alloc(dst);
	if (dst->bpp == 8) {
		int ii;
		for (ii = 0; ii < 256; ii++)
		dst->red[ii] = dst->blue[ii] = dst->green[ii] = ii;
	}

	ddjvu_format_set_row_order(page->doc->pixelformat, 1);
	ddjvu_page_render(page->page_ref, mode, &prect, &rrect, page->doc->pixelformat,
		bmp_bytewidth(dst), (char *) dst->data);

	kctx->page_width = dst->width;
	kctx->page_height = dst->height;

	return 0;
}

static int reflowPage(lua_State *L) {
	DjvuPage *page = (DjvuPage*) luaL_checkudata(L, 1, "djvupage");
	KOPTContext *kctx = (KOPTContext*) lua_topointer(L, 2);
	ddjvu_render_mode_t mode = (int) luaL_checkint(L, 3);
	ddjvu_rect_t prect;
	ddjvu_rect_t rrect;

	int px, py, pw, ph, rx, ry, rw, rh, status;

	px = 0;
	py = 0;
	pw = ddjvu_page_get_width(page->page_ref);
	ph = ddjvu_page_get_height(page->page_ref);
	prect.x = px;
	prect.y = py;

	rx = (int)kctx->bbox.x0;
	ry = (int)kctx->bbox.y0;
	rw = (int)(kctx->bbox.x1 - kctx->bbox.x0);
	rh = (int)(kctx->bbox.y1 - kctx->bbox.y0);

	double zoom = kctx->zoom*kctx->quality;
	float scale = (1.5*zoom*kctx->dev_width) / (double)pw;
	prect.w = pw * scale;
	prect.h = ph * scale;
	rrect.x = rx * scale;
	rrect.y = ry * scale;
	rrect.w = rw * scale;
	rrect.h = rh * scale;
#ifdef DEBUG
        printf("%s: rendering page: %u (%d,%d,%d,%d) [%s:%s]\n", __func__, page->num,
               rrect.x, rrect.y, rrect.w, rrect.h,
               page->doc->pixelsize == 3 ? "color" : "grey", render_mode_str(mode));
#endif
	kctx->zoom = scale;

	WILLUSBITMAP *src = &kctx->src;
	bmp_init(src);
	src->width = rrect.w;
	src->height = rrect.h;
	src->bpp = 8*page->doc->pixelsize;

	bmp_alloc(src);
	if (src->bpp == 8)
		for (int ii = 0; ii < 256; ii++)
			src->red[ii] = src->blue[ii] = src->green[ii] = ii;

	ddjvu_format_set_row_order(page->doc->pixelformat, 1);

	status = ddjvu_page_render(page->page_ref, mode, &prect, &rrect, page->doc->pixelformat,
			bmp_bytewidth(src), (char *) src->data);
	if (!status)
		return luaL_error(L, "%s: ddjvu_page_render failed", __func__);

	if (kctx->precache) {
		pthread_t rf_thread;
		pthread_attr_t attr;
		pthread_attr_init(&attr);
		pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
		pthread_create(&rf_thread, &attr, (void *)k2pdfopt_reflow_bmp, kctx);
		pthread_attr_destroy(&attr);
	} else {
		k2pdfopt_reflow_bmp(kctx);
	}

	return 0;
}

static int drawPage(lua_State *L) {
	DjvuPage *page = (DjvuPage*) luaL_checkudata(L, 1, "djvupage");
	DrawContext *dc = (DrawContext*) lua_topointer(L, 2);
	BlitBuffer *bb = (BlitBuffer*) lua_topointer(L, 3);
	ddjvu_render_mode_t djvu_render_mode = (int) luaL_checkint(L, 6);
	ddjvu_rect_t pagerect, renderrect;
	// map KOReader gamma to djvulibre gamma
	// djvulibre goes from 0.5 to 5.0
	double gamma = ABS(dc->gamma); // not sure why, but 1 is given as -1?
	if (gamma == 2) {
		// default
		gamma = 2.2;
	} else if (gamma < 2) {
		// with this function, 0.8 = 5, 2 = 2.2
		gamma = 6.86666 - 2.33333 * gamma;
		if (gamma > 5) {
			gamma = 5;
		}
	} else if (gamma > 2) {
		// with this function, 9 = 0.5, 2 = 2.2
		gamma = 2.68571 - 0.242856 * gamma;
		if (gamma < 0.5) {
			gamma = 0.5;
		}
	}
	ddjvu_format_set_gamma(page->doc->pixelformat, gamma);
	size_t bbsize = (bb->w)*(bb->h)*page->doc->pixelsize;
	uint8_t *imagebuffer = bb->data;

	/*printf("@page %d, @@zoom:%f, offset: (%d, %d)\n", page->num, dc->zoom, dc->offset_x, dc->offset_y);*/

	/* render full page into rectangle specified by pagerect */
	pagerect.x = 0;
	pagerect.y = 0;
	pagerect.w = page->info.width * dc->zoom;
	pagerect.h = page->info.height * dc->zoom;

	/*printf("--pagerect--- (x: %d, y: %d), w: %d, h: %d.\n", 0, 0, pagerect.w, pagerect.h);*/

	/* copy pixels area from pagerect specified by renderrect.
	 *
	 * ddjvulibre library does not support negative offset, positive offset
	 * means moving towards right and down.
	 *
	 * However, djvureader.lua handles offset differently. It uses negative
	 * offset to move right and down while positive offset to move left
	 * and up. So we need to handle positive offset manually when copying
	 * imagebuffer to blitbuffer (framebuffer).
	 */
	renderrect.x = MAX(-dc->offset_x, 0);
	renderrect.y = MAX(-dc->offset_y, 0);
	renderrect.w = MIN(pagerect.w - renderrect.x, bb->w);
	renderrect.h = MIN(pagerect.h - renderrect.y, bb->h);

	/*printf("--renderrect--- (%d, %d), w:%d, h:%d\n", renderrect.x, renderrect.y, renderrect.w, renderrect.h);*/

	/* ddjvulibre library only supports rotation of 0, 90, 180 and 270 degrees.
	 * These four kinds of rotations can already be achieved by native system.
	 * So we don't set rotation here.
	 */

	if (!ddjvu_page_render(page->page_ref, djvu_render_mode, &pagerect, &renderrect, page->doc->pixelformat, bb->w*page->doc->pixelsize, (void *)imagebuffer)) {
		// Clear to white on failure
		memset(imagebuffer, 0xFF, bbsize);
	}

	return 0;
}

static int getCacheSize(lua_State *L) {
	DjvuDocument *doc = (DjvuDocument*) luaL_checkudata(L, 1, "djvudocument");
	unsigned long size = ddjvu_cache_get_size(doc->context);
	//printf("## ddjvu_cache_get_size = %d\n", (int)size);
	lua_pushinteger(L, size);
	return 1;
}

static int cleanCache(lua_State *L) {
	DjvuDocument *doc = (DjvuDocument*) luaL_checkudata(L, 1, "djvudocument");
	//printf("## ddjvu_cache_clear\n");
	ddjvu_cache_clear(doc->context);
	return 0;
}

static const struct luaL_Reg djvu_func[] = {
	{"openDocument", openDocument},
	{NULL, NULL}
};

static const struct luaL_Reg djvudocument_meth[] = {
	{"openPage", openPage},
	{"getMetadata", getMetadata},
	{"getPages", getNumberOfPages},
	{"getToc", getTableOfContent},
	{"getPageText", getPageText},
	{"getOriginalPageSize", getOriginalPageSize},
	{"getPageInfo", getPageInfo},
	{"close", closeDocument},
	{"setColorRendering", setColorRendering},
	{"getCacheSize", getCacheSize},
	{"cleanCache", cleanCache},
	{"__gc", closeDocument},
	{NULL, NULL}
};

static const struct luaL_Reg djvupage_meth[] = {
	{"getSize", getPageSize},
	{"getUsedBBox", getUsedBBox},
	{"getPagePix", getPagePix},
	{"close", closePage},
	{"__gc", closePage},
	{"reflow", reflowPage},
	{"draw", drawPage},
	{NULL, NULL}
};

int luaopen_djvu(lua_State *L) {
	luaL_newmetatable(L, "djvudocument");
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);
	lua_settable(L, -3);
	luaL_register(L, NULL, djvudocument_meth);
	lua_pop(L, 1);

	luaL_newmetatable(L, "djvupage");
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);
	lua_settable(L, -3);
	luaL_register(L, NULL, djvupage_meth);
	lua_pop(L, 1);

	luaL_register(L, "djvu", djvu_func);
	return 1;
}
