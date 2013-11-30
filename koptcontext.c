/*
    KindlePDFViewer: a KOPTContext abstraction
    Copyright (C) 2012 Huang Xin <chrox.huang@gmail.com>

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

#include <assert.h>
#include "koptcontext.h"

static int newKOPTContext(lua_State *L) {
	int trim = 1;
	int wrap = 1;
	int indent = 1;
	int rotate = 0;
	int columns = 2;
	int offset_x = 0;
	int offset_y = 0;
	int dev_dpi = 167;
	int dev_width = 600;
	int dev_height = 800;
	int page_width = 600;
	int page_height = 800;
	int straighten = 0;
	int justification = -1;
	int read_max_width = 3000;
	int read_max_height = 4000;

	double zoom = 1.0;
	double margin = 0.06;
	double quality = 1.0;
	double contrast = 1.0;
	double defect_size = 1.0;
	double line_spacing = 1.2;
	double word_spacing = 1.375;
	double shrink_factor = 0.9;

	BBox bbox = {0, 0, 0, 0};
	int precache = 0;
	int debug = 0;
	int cjkchar = 0;

	KOPTContext *kc = (KOPTContext*) lua_newuserdata(L, sizeof(KOPTContext));

	kc->trim = trim;
	kc->wrap = wrap;
	kc->indent = indent;
	kc->rotate = rotate;
	kc->columns = columns;
	kc->offset_x = offset_x;
	kc->offset_y = offset_y;
	kc->dev_dpi = dev_dpi;
	kc->dev_width = dev_width;
	kc->dev_height = dev_height;
	kc->page_width = page_width;
	kc->page_height = page_height;
	kc->straighten = straighten;
	kc->justification = justification;
	kc->read_max_width = read_max_width;
	kc->read_max_height = read_max_height;

	kc->zoom = zoom;
	kc->margin = margin;
	kc->quality = quality;
	kc->contrast = contrast;
	kc->defect_size = defect_size;
	kc->line_spacing = line_spacing;
	kc->word_spacing = word_spacing;
	kc->shrink_factor = shrink_factor;

	kc->bbox = bbox;
	kc->precache = precache;
	kc->debug = debug;
	kc->cjkchar = cjkchar;

	kc->rboxa = NULL;
	kc->rnai = NULL;
	kc->nboxa = NULL;
	kc->nnai = NULL;

	kc->language = NULL;

	bmp_init(&kc->src);
	bmp_init(&kc->dst);
	wrectmaps_init(&kc->rectmaps);

	luaL_getmetatable(L, "koptcontext");
	lua_setmetatable(L, -2);

	return 1;
}

static int kcFreeContext(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	/* Don't worry about the src bitmap in context. It's freed as soon as it's
	 * been used in either reflow or autocrop. But we should take care of dst
	 * bitmap since the usage of dst bitmap is delayed most of the times.
	 */
	bmp_free(&kc->dst);
	boxaDestroy(&kc->rboxa);
	numaDestroy(&kc->rnai);
	boxaDestroy(&kc->nboxa);
	numaDestroy(&kc->nnai);
	wrectmaps_free(&kc->rectmaps);
	return 0;
}

static int kcFreeOCREngine(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	k2pdfopt_tocr_end();
	return 0;
}

static int kcSetBBox(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->bbox.x0 = luaL_checknumber(L, 2);
	kc->bbox.y0 = luaL_checknumber(L, 3);
	kc->bbox.x1 = luaL_checknumber(L, 4);
	kc->bbox.y1 = luaL_checknumber(L, 5);
	return 0;
}

static int kcSetTrim(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->trim = luaL_checkint(L, 2);
	return 0;
}

static int kcGetTrim(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	lua_pushinteger(L, kc->trim);
	return 1;
}

static int kcSetWrap(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->wrap = luaL_checkint(L, 2);
	return 0;
}

static int kcSetIndent(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->indent = luaL_checkint(L, 2);
	return 0;
}

static int kcSetRotate(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->rotate = luaL_checkint(L, 2);
	return 0;
}

static int kcSetColumns(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->columns = luaL_checkint(L, 2);
	return 0;
}

static int kcSetOffset(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->offset_x = luaL_checkint(L, 2);
	kc->offset_y = luaL_checkint(L, 3);
	return 0;
}

static int kcGetOffset(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	lua_pushinteger(L, kc->offset_x);
	lua_pushinteger(L, kc->offset_y);
	return 2;
}

static int kcSetDeviceDPI(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->dev_dpi = luaL_checkint(L, 2);
	return 0;
}

static int kcSetDeviceDim(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->dev_width = luaL_checkint(L, 2);
	kc->dev_height = luaL_checkint(L, 3);
	return 0;
}

static int kcGetPageDim(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	lua_pushinteger(L, kc->page_width);
	lua_pushinteger(L, kc->page_height);
	return 2;
}

static int kcSetStraighten(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->straighten = luaL_checkint(L, 2);
	return 0;
}

static int kcSetJustification(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->justification = luaL_checkint(L, 2);
	return 0;
}

static int kcSetZoom(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->zoom = luaL_checknumber(L, 2);
	return 0;
}

static int kcGetZoom(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	lua_pushnumber(L, kc->zoom);
	return 1;
}

static int kcSetMargin(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->margin = luaL_checknumber(L, 2);
	return 0;
}

static int kcSetQuality(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->quality = luaL_checknumber(L, 2);
	return 0;
}

static int kcSetContrast(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->contrast = luaL_checknumber(L, 2);
	return 0;
}

static int kcSetDefectSize(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->defect_size = luaL_checknumber(L, 2);
	return 0;
}

static int kcSetLineSpacing(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->line_spacing = luaL_checknumber(L, 2);
	return 0;
}

static int kcSetWordSpacing(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->word_spacing = luaL_checknumber(L, 2);
	return 0;
}

static int kcSetPreCache(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->precache = 1;
	return 0;
}

static int kcIsPreCache(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	lua_pushinteger(L, kc->precache);
	return 1;
}

static int kcSetDebug(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->debug = 1;
	return 0;
}

static int kcSetCJKChar(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->cjkchar = 1;
	return 0;
}

static int kcSetLanguage(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	kc->language = luaL_checkstring(L, 2);
	return 0;
}

static int kcGetLanguage(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	lua_pushstring(L, k2pdfopt_tocr_get_language());
	return 1;
}

static int kcCopyDestBMP(lua_State *L) {
    KOPTContext *kc_dst = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
    KOPTContext *kc_src = (KOPTContext*) luaL_checkudata(L, 2, "koptcontext");
    bmp_copy(&kc_dst->dst, &kc_src->dst);
    return 0;
}

int kcGetWordBoxes(lua_State *L, int box_type) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	int x = luaL_checkint(L, 2);
	int y = luaL_checkint(L, 3);
	int w = luaL_checkint(L, 4);
	int h = luaL_checkint(L, 5);
	BOX *box;
	BOXA *boxa;
	NUMA *nai;
	l_float32 max_val;
	int nr_line, last_index, nr_word, current_line;
	int counter_l, counter_w, counter_cw;
	int l_x0, l_y0, l_x1, l_y1;

	if (box_type == 0) {
	    k2pdfopt_get_reflowed_word_boxes(kc, &kc->dst, x, y, w, h);
	    boxa = kc->rboxa;
	    nai = kc->rnai;
	} else if (box_type == 1) {
	    k2pdfopt_get_native_word_boxes(kc, &kc->dst, x, y, w, h);
	    boxa = kc->nboxa;
	    nai = kc->nnai;
	}

	/* get number of lines in this area */
	numaGetMax(nai, &max_val, &last_index);
	nr_line = (int) max_val;
	/* get number of lines in this area */
	nr_word = boxaGetCount(boxa);
	assert(nr_word == numaGetCount(nai));
	/* table that contains all the words */
	lua_newtable(L);
	lua_pushstring(L, "box_only");
	lua_pushnumber(L, 1);
	lua_settable(L, -3);
	for (counter_w = 0; counter_w < nr_word; counter_w++) {
		numaGetIValue(nai, counter_w, &counter_l);
		current_line = counter_l;
		/* subtable that contains words in a line */
		lua_pushnumber(L, counter_l+1);
		lua_newtable(L);
		counter_cw = 0;
		l_y0 = l_x0 = 9999;
		l_x1 = l_y1 = 0;
		while (current_line == counter_l && counter_w < nr_word) {
			box = boxaGetBox(boxa, counter_w, L_CLONE);
			/* create table that contains box for a word */
			lua_pushnumber(L, counter_cw+1);
			lua_newtable(L);
			counter_w++;
			counter_cw++;

			/* update line box */
			l_x0 = box->x < l_x0 ? box->x : l_x0;
			l_y0 = box->y < l_y0 ? box->y : l_y0;
			l_x1 = box->x + box->w > l_x1 ? box->x + box->w : l_x1;
			l_y1 = box->y + box->h > l_y1 ? box->y + box->h : l_y1;

			/* set word box */
			lua_pushstring(L, "x0");
			lua_pushnumber(L, box->x);
			lua_settable(L, -3);

			lua_pushstring(L, "y0");
			lua_pushnumber(L, box->y);
			lua_settable(L, -3);

			lua_pushstring(L, "x1");
			lua_pushnumber(L, box->x + box->w);
			lua_settable(L, -3);

			lua_pushstring(L, "y1");
			lua_pushnumber(L, box->y + box->h);
			lua_settable(L, -3);

			//printf("box %d:%d,%d,%d,%d\n",counter_w,box->x,box->y,box->w,box->h);
			/* set word entry to line subtable */
			lua_settable(L, -3);
			if (counter_w < nr_word)
				numaGetIValue(nai, counter_w, &counter_l);
		} /* end of while */
		if (current_line != counter_l) counter_w--;
		/* box for a whole line */
		lua_pushstring(L, "x0");
		lua_pushnumber(L, l_x0);
		lua_settable(L, -3);
		lua_pushstring(L, "y0");
		lua_pushnumber(L, l_y0);
		lua_settable(L, -3);
		lua_pushstring(L, "x1");
		lua_pushnumber(L, l_x1);
		lua_settable(L, -3);
		lua_pushstring(L, "y1");
		lua_pushnumber(L, l_y1);
		lua_settable(L, -3);
		/* set line entry to box table */
		lua_settable(L, -3);
	} /* end of for */

	return 1;
}

static int kcGetReflowedWordBoxes(lua_State *L) {
    return kcGetWordBoxes(L, 0);
}

static int kcGetNativeWordBoxes(lua_State *L) {
    return kcGetWordBoxes(L, 1);
}

static int kcReflowToNativePosTransform(lua_State *L) {
    KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
    int xc = luaL_checknumber(L, 2);
    int yc = luaL_checknumber(L, 3);
    float wr = luaL_checknumber(L, 4);
    float hr = luaL_checknumber(L, 5);
    int i;
    float x, y, w, h;
    for (i = 0; i < kc->rectmaps.n; i++) {
        WRECTMAP * rectmap = &kc->rectmaps.wrectmap[i];
        if (wrectmap_inside(rectmap, xc, yc)) {
            x = rectmap->coords[0].x*kc->dev_dpi*kc->quality/rectmap->srcdpiw;
            y = rectmap->coords[0].y*kc->dev_dpi*kc->quality/rectmap->srcdpih;
            w = rectmap->coords[2].x*kc->dev_dpi*kc->quality/rectmap->srcdpiw;
            h = rectmap->coords[2].y*kc->dev_dpi*kc->quality/rectmap->srcdpih;
            lua_pushnumber(L, (x + w*wr)/kc->zoom + kc->bbox.x0);
            lua_pushnumber(L, (y + h*hr)/kc->zoom + kc->bbox.y0);
            return 2;
        }
    }
    return 0;
}

int wrectmap_native_inside(WRECTMAP *wrmap, int xc, int yc) {
    return(wrmap->coords[0].x <= xc && wrmap->coords[0].y <= yc
            && wrmap->coords[0].x + wrmap->coords[2].x >= xc
            && wrmap->coords[0].y + wrmap->coords[2].y >= yc);
}

static int kcNativeToReflowPosTransform(lua_State *L) {
    KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
    int x = luaL_checknumber(L, 2);
    int y = luaL_checknumber(L, 3);
    int i, x0, y0;
    x = (x - kc->bbox.x0) * kc->zoom;
    y = (y - kc->bbox.y0) * kc->zoom;
    for (i = 0; i < kc->rectmaps.n; i++) {
        WRECTMAP * rectmap = &kc->rectmaps.wrectmap[i];
        if (wrectmap_native_inside(rectmap, x, y)) {
            x0 = rectmap->coords[1].x + rectmap->coords[2].x/2;
            y0 = rectmap->coords[1].y + rectmap->coords[2].y/2;
            lua_pushinteger(L, x0);
            lua_pushinteger(L, y0);
            return 2;
        }
    }
    return 0;
}

static int kcGetTOCRWord(lua_State *L) {
	KOPTContext *kc = (KOPTContext*) luaL_checkudata(L, 1, "koptcontext");
	int x = luaL_checkint(L, 2);
	int y = luaL_checkint(L, 3);
	int w = luaL_checkint(L, 4);
	int h = luaL_checkint(L, 5);
	const char *datadir = luaL_checkstring(L, 6);
	const char *lang = luaL_checkstring(L, 7);
	const int ocr_type = luaL_checkint(L, 8);
	const int allow_spaces = luaL_checkint(L, 9);
	const int std_proc = luaL_checkint(L, 10);
	char word[256];

	k2pdfopt_tocr_single_word(&kc->dst,
		x, y, w, h,
		word, 255,
		datadir, lang, ocr_type, allow_spaces, std_proc);

	lua_pushstring(L, word);
	return 1;
}

static const struct luaL_Reg koptcontext_meth[] = {
	{"setBBox", kcSetBBox},
	{"setTrim", kcSetTrim},
	{"getTrim", kcGetTrim},
	{"setWrap", kcSetWrap},
	{"setIndent", kcSetIndent},
	{"setRotate", kcSetRotate},
	{"setColumns", kcSetColumns},
	{"setOffset", kcSetOffset},
	{"getOffset", kcGetOffset},
	{"setDeviceDim", kcSetDeviceDim},
	{"setDeviceDPI", kcSetDeviceDPI},
	{"getPageDim", kcGetPageDim},
	{"setStraighten", kcSetStraighten},
	{"setJustification", kcSetJustification},

	{"setZoom", kcSetZoom},
	{"getZoom", kcGetZoom},
	{"setMargin", kcSetMargin},
	{"setQuality", kcSetQuality},
	{"setContrast", kcSetContrast},
	{"setDefectSize", kcSetDefectSize},
	{"setLineSpacing", kcSetLineSpacing},
	{"setWordSpacing", kcSetWordSpacing},

	{"setPreCache", kcSetPreCache},
	{"isPreCache", kcIsPreCache},
	{"setDebug", kcSetDebug},
	{"setCJKChar", kcSetCJKChar},
	{"setLanguage",kcSetLanguage},
	{"getLanguage", kcGetLanguage},

	{"copyDestBMP", kcCopyDestBMP},
	{"getReflowedWordBoxes", kcGetReflowedWordBoxes},
	{"getNativeWordBoxes", kcGetNativeWordBoxes},
	{"reflowToNativePosTransform", kcReflowToNativePosTransform},
	{"nativeToReflowPosTransform", kcNativeToReflowPosTransform},
	{"getTOCRWord", kcGetTOCRWord},

	{"freeOCR", kcFreeOCREngine},
	{"free", kcFreeContext},
	{"__gc", kcFreeContext},
	{NULL, NULL}
};

static const struct luaL_Reg koptcontext_func[] = {
	{"new", newKOPTContext},
	{NULL, NULL}
};

int luaopen_koptcontext(lua_State *L) {
	luaL_newmetatable(L, "koptcontext");
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);
	lua_settable(L, -3);
	luaL_register(L, NULL, koptcontext_meth);
	lua_pop(L, 1);
	luaL_register(L, "KOPTContext", koptcontext_func);
	return 1;
}
