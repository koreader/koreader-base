/*
    KindlePDFViewer: CREngine abstraction for Lua
    Copyright (C) 2012 Hans-Werner Hilse <hilse@web.de>
                       Qingping Hou <qingping.hou@gmail.com>

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

#ifndef DEBUG_CRENGINE
#define DEBUG_CRENGINE 0
#endif

extern "C" {
#include "blitbuffer.h"
#include "drawcontext.h"
#include "cre.h"
}

#include "crengine.h"
#include "lvdocview.h"
#include "lvimg.h"

static void replaceColor( char * str, lUInt32 color ) {
	// in line like "0 c #80000000",
	// replace value of color
	for ( int i=0; i<8; i++ ) {
			str[i+5] = toHexDigit((color>>28) & 0xF);
			color <<= 4;
	}
}

/// set list of battery icons to display battery state
static LVRefVec<LVImageSource> getBatteryIcons(lUInt32 color) {
	CRLog::debug("Making list of Battery icon bitmats");

    lUInt32 cl1 = 0x00000000|(color&0xFFFFFF);
    lUInt32 cl2 = 0x40000000|(color&0xFFFFFF);
    lUInt32 cl3 = 0x80000000|(color&0xFFFFFF);
    lUInt32 cl4 = 0xF0000000|(color&0xFFFFFF);

    static char color1[] = "0 c #80000000";
    static char color2[] = "X c #80000000";
    static char color3[] = "o c #80AAAAAA";
    static char color4[] = ". c #80FFFFFF";
	#define BATTERY_HEADER \
			"28 15 5 1", \
			color1, \
			color2, \
			color3, \
			color4, \
			"  c None",

    static const char * battery8[] = {
        BATTERY_HEADER
        "   .........................",
        "   .00000000000000000000000.",
        "   .0.....................0.",
        "....0.XXXX.XXXX.XXXX.XXXX.0.",
        ".0000.XXXX.XXXX.XXXX.XXXX.0.",
        ".0..0.XXXX.XXXX.XXXX.XXXX.0.",
        ".0..0.XXXX.XXXX.XXXX.XXXX.0.",
        ".0..0.XXXX.XXXX.XXXX.XXXX.0.",
        ".0..0.XXXX.XXXX.XXXX.XXXX.0.",
        ".0..0.XXXX.XXXX.XXXX.XXXX.0.",
        ".0000.XXXX.XXXX.XXXX.XXXX.0.",
        "....0.XXXX.XXXX.XXXX.XXXX.0.",
        "   .0.....................0.",
        "   .00000000000000000000000.",
        "   .........................",
    };
    static const char * battery7[] = {
        BATTERY_HEADER
        "   .........................",
        "   .00000000000000000000000.",
        "   .0.....................0.",
        "....0.oooo.XXXX.XXXX.XXXX.0.",
        ".0000.oooo.XXXX.XXXX.XXXX.0.",
        ".0..0.oooo.XXXX.XXXX.XXXX.0.",
        ".0..0.oooo.XXXX.XXXX.XXXX.0.",
        ".0..0.oooo.XXXX.XXXX.XXXX.0.",
        ".0..0.oooo.XXXX.XXXX.XXXX.0.",
        ".0..0.oooo.XXXX.XXXX.XXXX.0.",
        ".0000.oooo.XXXX.XXXX.XXXX.0.",
        "....0.oooo.XXXX.XXXX.XXXX.0.",
        "   .0.....................0.",
        "   .00000000000000000000000.",
        "   .........................",
    };
    static const char * battery6[] = {
        BATTERY_HEADER
        "   .........................",
        "   .00000000000000000000000.",
        "   .0.....................0.",
        "....0......XXXX.XXXX.XXXX.0.",
        ".0000......XXXX.XXXX.XXXX.0.",
        ".0..0......XXXX.XXXX.XXXX.0.",
        ".0..0......XXXX.XXXX.XXXX.0.",
        ".0..0......XXXX.XXXX.XXXX.0.",
        ".0..0......XXXX.XXXX.XXXX.0.",
        ".0..0......XXXX.XXXX.XXXX.0.",
        ".0000......XXXX.XXXX.XXXX.0.",
        "....0......XXXX.XXXX.XXXX.0.",
        "   .0.....................0.",
        "   .00000000000000000000000.",
        "   .........................",
    };
    static const char * battery5[] = {
        BATTERY_HEADER
        "   .........................",
        "   .00000000000000000000000.",
        "   .0.....................0.",
        "....0......oooo.XXXX.XXXX.0.",
        ".0000......oooo.XXXX.XXXX.0.",
        ".0..0......oooo.XXXX.XXXX.0.",
        ".0..0......oooo.XXXX.XXXX.0.",
        ".0..0......oooo.XXXX.XXXX.0.",
        ".0..0......oooo.XXXX.XXXX.0.",
        ".0..0......oooo.XXXX.XXXX.0.",
        ".0000......oooo.XXXX.XXXX.0.",
        "....0......oooo.XXXX.XXXX.0.",
        "   .0.....................0.",
        "   .00000000000000000000000.",
        "   .........................",
    };
    static const char * battery4[] = {
        BATTERY_HEADER
        "   .........................",
        "   .00000000000000000000000.",
        "   .0.....................0.",
        "....0...........XXXX.XXXX.0.",
        ".0000...........XXXX.XXXX.0.",
        ".0..0...........XXXX.XXXX.0.",
        ".0..0...........XXXX.XXXX.0.",
        ".0..0...........XXXX.XXXX.0.",
        ".0..0...........XXXX.XXXX.0.",
        ".0..0...........XXXX.XXXX.0.",
        ".0000...........XXXX.XXXX.0.",
        "....0...........XXXX.XXXX.0.",
        "   .0.....................0.",
        "   .00000000000000000000000.",
        "   .........................",
    };
    static const char * battery3[] = {
        BATTERY_HEADER
        "   .........................",
        "   .00000000000000000000000.",
        "   .0.....................0.",
        "....0...........oooo.XXXX.0.",
        ".0000...........oooo.XXXX.0.",
        ".0..0...........oooo.XXXX.0.",
        ".0..0...........oooo.XXXX.0.",
        ".0..0...........oooo.XXXX.0.",
        ".0..0...........oooo.XXXX.0.",
        ".0..0...........oooo.XXXX.0.",
        ".0000...........oooo.XXXX.0.",
        "....0...........oooo.XXXX.0.",
        "   .0.....................0.",
        "   .00000000000000000000000.",
        "   .........................",
    };
    static const char * battery2[] = {
        BATTERY_HEADER
        "   .........................",
        "   .00000000000000000000000.",
        "   .0.....................0.",
        "....0................XXXX.0.",
        ".0000................XXXX.0.",
        ".0..0................XXXX.0.",
        ".0..0................XXXX.0.",
        ".0..0................XXXX.0.",
        ".0..0................XXXX.0.",
        ".0..0................XXXX.0.",
        ".0000................XXXX.0.",
        "....0................XXXX.0.",
        "   .0.....................0.",
        "   .00000000000000000000000.",
        "   .........................",
    };
    static const char * battery1[] = {
        BATTERY_HEADER
        "   .........................",
        "   .00000000000000000000000.",
        "   .0.....................0.",
        "   .0................oooo.0.",
        ".0000................oooo.0.",
        ".0..0................oooo.0.",
        ".0..0................oooo.0.",
        ".0..0................oooo.0.",
        ".0..0................oooo.0.",
        ".0..0................oooo.0.",
        ".0000................oooo.0.",
        "   .0................oooo.0.",
        "   .0.....................0.",
        "   .00000000000000000000000.",
        "   .........................",
    };
    static const char * battery0[] = {
        BATTERY_HEADER
        "   .........................",
        "   .00000000000000000000000.",
        "   .0.....................0.",
        "   .0.....................0.",
        ".0000.....................0.",
        ".0..0.....................0.",
        ".0..0.....................0.",
        ".0..0.....................0.",
        ".0..0.....................0.",
        ".0..0.....................0.",
        ".0000.....................0.",
        "....0.....................0.",
        "   .0.....................0.",
        "   .00000000000000000000000.",
        "   .........................",
    };
//#endif

    static const char * battery_charge[] = {
        BATTERY_HEADER
        "   .........................",
        "   .00000000000000000000000.",
        "   .0.....................0.",
        "....0.....................0.",
        ".0000............XX.......0.",
        ".0..0...........XXXX......0.",
        ".0..0..XX......XXXXXX.....0.",
        ".0..0...XXX...XXXX..XX....0.",
        ".0..0....XXX..XXXX...XX...0.",
        ".0..0.....XXXXXXX.....XX..0.",
        ".0000.......XXXX..........0.",
        "....0........XX...........0.",
        "   .0.....................0.",
        "   .00000000000000000000000.",
        "   .........................",
    };
    static const char * battery_frame[] = {
        BATTERY_HEADER
        "   .........................",
        "   .00000000000000000000000.",
        "   .0.....................0.",
        "....0.....................0.",
        ".0000.....................0.",
        ".0..0.....................0.",
        ".0..0.....................0.",
        ".0..0.....................0.",
        ".0..0.....................0.",
        ".0..0.....................0.",
        ".0000.....................0.",
        "....0.....................0.",
        "   .0.....................0.",
        "   .00000000000000000000000.",
        "   .........................",
    };

    const char * * icon_bpm[] = {
		battery_charge,
		battery0,
		battery1,
		battery2,
		battery3,
		battery4,
		battery5,
		battery6,
		battery7,
		battery8,
		battery_frame,
		NULL
    };

	replaceColor( color1, cl1 );
	replaceColor( color2, cl2 );
	replaceColor( color3, cl3 );
	replaceColor( color4, cl4 );

	LVRefVec<LVImageSource> icons;
	for ( int i=0; icon_bpm[i]; i++ ) {
		icons.add(LVCreateXPMImageSource( icon_bpm[i] ));
	}

	return icons;
}

typedef struct CreDocument {
	LVDocView *text_view;
	ldomDocument *dom_doc;
} CreDocument;

static int initCache(lua_State *L) {
    const char *cache_path = luaL_checkstring(L, 1);
    int cache_size = luaL_checkint(L, 2);
    bool compress_cached_data = true;
    if (lua_isboolean(L, 3)) {
        compress_cached_data = lua_toboolean(L, 3);
    }
    float storage_max_uncompressed_size_factor = (float)luaL_optnumber(L, 4, 1.0);

    // Setting this to false uses more disk space for cache,
    // but speed up rendering and page turns quite a bit
    compressCachedData(compress_cached_data);

    // Increase the 4 hardcoded TEXT_CACHE_UNPACKED_SPACE, ELEM_CACHE_UNPACKED_SPACE,
    // RECT_CACHE_UNPACKED_SPACE and STYLE_CACHE_UNPACKED_SPACE by this factor
    setStorageMaxUncompressedSizeFactor(storage_max_uncompressed_size_factor);

    ldomDocCache::init(lString16(cache_path), cache_size);

    return 0;
}

static int initHyphDict(lua_State *L) {
    const char *dict_path = luaL_checkstring(L, 1);

    HyphMan::initDictionaries(lString16(dict_path));

    return 0;
}

static int newDocView(lua_State *L) {
	int width = luaL_checkint(L, 1);
	int height = luaL_checkint(L, 2);
	LVDocViewMode view_mode = (LVDocViewMode)luaL_checkint(L, 3);

	CreDocument *doc = (CreDocument*) lua_newuserdata(L, sizeof(CreDocument));
	luaL_getmetatable(L, "credocument");
	lua_setmetatable(L, -2);

	doc->text_view = new LVDocView();
	//doc->text_view->setBackgroundColor(0xFFFFFF);
	//doc->text_view->setTextColor(0x000000);
	//doc->text_view->doCommand(DCMD_SET_DOC_FONTS, 1);
	//doc->text_view->doCommand(DCMD_SET_INTERNAL_STYLES, 1);
	doc->text_view->setViewMode(view_mode, -1);
	doc->text_view->Resize(width, height);
	doc->text_view->setPageHeaderInfo(PGHDR_AUTHOR|PGHDR_TITLE|PGHDR_PAGE_NUMBER|PGHDR_PAGE_COUNT|PGHDR_CHAPTER_MARKS|PGHDR_CLOCK);

	// it will overwrite all settings by values found in ./data/cr3.ini
	CRPropRef props = doc->text_view->propsGetCurrent();
	LVStreamRef stream = LVOpenFileStream("data/cr3.ini", LVOM_READ);
	if ( !stream.isNull() && props->loadFromStream(stream.get()) ) {
		doc->text_view->propsApply(props);
	} else {
		// Tweak the default settings to be slightly less random
		props->setString(PROP_FALLBACK_FONT_FACE, "Noto Sans CJK SC");
		props->setString(PROP_HYPHENATION_DICT, "English_US.pattern");
		props->setString(PROP_STATUS_FONT_FACE, "Noto Sans");
		props->setString(PROP_FONT_FACE, "Noto Serif");
		props->setInt(PROP_FONT_HINTING, 2);	// autohint, to be conservative (some ttf fonts' bytecode is truly crappy)
		props->setInt(PROP_FONT_KERNING_ENABLED, 1);
		props->setString("styles.pre.font-face", "font-family: \"Droid Sans Mono\"");

		stream = LVOpenFileStream("data/cr3.ini", LVOM_WRITE);
		props->saveToStream(stream.get());
	}

	doc->text_view->setBatteryIcons(getBatteryIcons(0x000000));

	return 1;
}

static int getLatestDomVersion(lua_State *L) {
    lua_pushnumber(L, gDOMVersionCurrent);
    return 1;
}

static int requestDomVersion(lua_State *L) {
    int version = luaL_checkint(L, 1);
    gDOMVersionRequested = version;
    return 0;
}

static int saveDefaults(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	CRPropRef props = doc->text_view->propsGetCurrent();
	LVStreamRef stream = LVOpenFileStream("data/cr3.ini", LVOM_WRITE);
	return props->saveToStream(stream.get());
}

static int getIntProperty(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char *propName = luaL_checkstring(L, 2);
    int value;
    CRPropRef props = doc->text_view->propsGetCurrent();
    props->getInt(propName, value);
    lua_pushinteger(L, value);
    return 1;
}

static int setIntProperty(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char *propName = luaL_checkstring(L, 2);
    int value = luaL_checkint(L, 3);
    CRPropRef props = LVCreatePropsContainer();
    props->setInt(propName, value);
    doc->text_view->propsApply(props);
    return 0;
}

static int getStringProperty(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char *propName = luaL_checkstring(L, 2);
    lString16 value;
    CRPropRef props = doc->text_view->propsGetCurrent();
    props->getString(propName, value);
    lua_pushstring(L, UnicodeToLocal(value).c_str());
    return 1;
}

static int setStringProperty(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char *propName = luaL_checkstring(L, 2);
    const char *value = luaL_checkstring(L, 3);
    CRPropRef props = LVCreatePropsContainer();
    props->setString(propName, value);
    doc->text_view->propsApply(props);
    return 0;
}

static int getGammaLevel(lua_State *L) {
    lua_pushnumber(L, fontMan->GetGamma());

    return 1;
}

static int getGammaIndex(lua_State *L) {
	lua_pushinteger(L, fontMan->GetGammaIndex());

	return 1;
}

static int setGammaIndex(lua_State *L) {
	int index = luaL_checkint(L, 1);

	fontMan->SetGammaIndex(index);

	return 0;
}

static int getHyphDictList(lua_State *L) {
	lua_newtable(L);
	HyphDictionaryList *list = HyphMan::getDictList();
	for(int i = 0; i < list->length(); i++) {
		lua_pushnumber(L, i+1);
		lua_pushstring(L, UnicodeToLocal(list->get(i)->getId()).c_str());
		lua_settable(L, -3);
	}
	return 1;
}

static int getSelectedHyphDict(lua_State *L) {
	lua_pushstring(L, UnicodeToLocal(HyphMan::getSelectedDictionary()->getId()).c_str());
	return 1;
}

static int setHyphDictionary(lua_State *L) {
	const char *id = luaL_checkstring(L, 1);
	HyphMan::getDictList()->activate((lString16)id);
	return 0;
}

static int loadDocument(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const char *file_name = luaL_checkstring(L, 2);
	bool only_metadata = false;
	if (lua_isboolean(L, 3)) {
		only_metadata = lua_toboolean(L, 3);
	}

	doc->text_view->LoadDocument(file_name, only_metadata);
	doc->dom_doc = doc->text_view->getDocument();

	bool loaded = false;
	if (doc->dom_doc) { loaded = true ;}
	lua_pushboolean(L, loaded);
	return 1;
}

static int renderDocument(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	doc->text_view->Render();

	return 0;
}

static int closeDocument(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	/* should be save if called twice */
	if(doc->text_view != NULL) {
		delete doc->text_view;
		doc->text_view = NULL;
	}

	return 0;
}

static int isBuiltDomStale(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    lua_pushboolean(L, doc->dom_doc->isBuiltDomStale());
    return 1;
}

static int hasCacheFile(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    lua_pushboolean(L, doc->dom_doc->hasCacheFile());
    return 1;
}

static int invalidateCacheFile(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    doc->dom_doc->invalidateCacheFile();
    return 0;
}

static int getCacheFilePath(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    lString16 cache_path = doc->dom_doc->getCacheFilePath();
    if (cache_path.empty())
        return 0;
    lua_pushstring(L, UnicodeToLocal(cache_path).c_str());
    return 1;
}

static int getDocumentProps(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	lua_newtable(L);
	lua_pushstring(L, "title");
	lua_pushstring(L, UnicodeToLocal(doc->text_view->getTitle()).c_str());
	lua_settable(L, -3);

	lua_pushstring(L, "authors");
	lua_pushstring(L, UnicodeToLocal(doc->text_view->getAuthors()).c_str());
	lua_settable(L, -3);

	lua_pushstring(L, "language");
	lua_pushstring(L, UnicodeToLocal(doc->text_view->getLanguage()).c_str());
	lua_settable(L, -3);

	lua_pushstring(L, "series");
	lua_pushstring(L, UnicodeToLocal(doc->text_view->getSeries()).c_str());
	lua_settable(L, -3);

	lua_pushstring(L, "description");
	lua_pushstring(L, UnicodeToLocal(doc->text_view->getDescription()).c_str());
	lua_settable(L, -3);

	lua_pushstring(L, "keywords");
	lua_pushstring(L, UnicodeToLocal(doc->text_view->getKeywords()).c_str());
	lua_settable(L, -3);

	return 1;
}


static int getNumberOfPages(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	lua_pushinteger(L, doc->text_view->getPageCount());

	return 1;
}

static int getCurrentPage(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	lua_pushinteger(L, doc->text_view->getCurPage()+1);

	return 1;
}

static int getPageFromXPointer(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const char *xpointer_str = luaL_checkstring(L, 2);

	int page = 1;
	ldomXPointer xp = doc->dom_doc->createXPointer(lString16(xpointer_str));

	page = doc->text_view->getBookmarkPage(xp) + 1;
	lua_pushinteger(L, page);

	return 1;
}

static int getPosFromXPointer(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const char *xpointer_str = luaL_checkstring(L, 2);

	int pos = 0;
	ldomXPointer xp = doc->dom_doc->createXPointer(lString16(xpointer_str));

	lvPoint pt = xp.toPoint(true); // extended=true, for better accuracy
	if (pt.y > 0) {
		pos = pt.y;
	}
	lua_pushinteger(L, pos);

	// Also returns the x value (as the 2nd returned value, as its
	// less interesting to current code than the y value)
	lua_pushinteger(L, pt.x);

	return 2;
}

static int getCurrentPos(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	lua_pushinteger(L, doc->text_view->GetPos());

	return 1;
}

static int getCurrentPercent(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	lua_pushinteger(L, doc->text_view->getPosPercent());

	return 1;
}

static int getXPointer(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	ldomXPointer xp = doc->text_view->getBookmark();
	lua_pushstring(L, UnicodeToLocal(xp.toString()).c_str());

	return 1;
}

static int getFullHeight(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	lua_pushinteger(L, doc->text_view->GetFullHeight());

	return 1;
}

static int getFontSize(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	lua_pushinteger(L, doc->text_view->getFontSize());

	return 1;
}

static int getFontFace(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	lua_pushstring(L, doc->text_view->getDefaultFontFace().c_str());

	return 1;
}

/*
 * helper function for getTableOfContent()
 */
static int walkTableOfContent(lua_State *L, LVTocItem *toc, int *count) {
	LVTocItem *toc_tmp = NULL;
	int i = 0,
		nr_child = toc->getChildCount();

	for (i = 0; i < nr_child; i++)  {
		toc_tmp = toc->getChild(i);
		lua_pushnumber(L, (*count)++);

		/* set subtable, Toc entry */
		lua_newtable(L);
		lua_pushstring(L, "page");
		lua_pushnumber(L, toc_tmp->getPage()+1);
		lua_settable(L, -3);

		// Note: toc_tmp->getXPointer().toString() and toc_tmp->getPath() return
		// the same xpath string. But when just loaded from cache, the XPointer
		// is not yet available, but getPath() is. So let's use it, which avoids
		// having to build the XPointers until they are needed to update page numbers.
		lua_pushstring(L, "xpointer");
		// lua_pushstring(L, UnicodeToLocal( toc_tmp->getXPointer().toString()).c_str());
		lua_pushstring(L, UnicodeToLocal(toc_tmp->getPath()).c_str());
		lua_settable(L, -3);

		lua_pushstring(L, "depth");
		lua_pushnumber(L, toc_tmp->getLevel());
		lua_settable(L, -3);

		lua_pushstring(L, "title");
		lua_pushstring(L, UnicodeToLocal(toc_tmp->getName()).c_str());
		lua_settable(L, -3);


		/* set Toc entry to Toc table */
		lua_settable(L, -3);

		if (toc_tmp->getChildCount() > 0) {
			walkTableOfContent(L, toc_tmp, count);
		}
	}
	return 0;
}

/*
 * Return a table like this:
 * {
 *    {
 *       page=12,
 *       xpointer = "/body/DocFragment[11].0",
 *       depth=1,
 *       title="chapter1"
 *    },
 *    {
 *       page=54,
 *       xpointer = "/body/DocFragment[13].0",
 *       depth=1,
 *       title="chapter2"
 *    },
 * }
 *
 */
static int getTableOfContent(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	LVTocItem * toc = doc->text_view->getToc();
	int count = 1;

	lua_newtable(L);
	walkTableOfContent(L, toc, &count);

	return 1;
}

static int isTocAlternativeToc(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	if (doc->dom_doc) {
            lua_pushboolean(L, doc->dom_doc->isTocAlternativeToc());
            return 1;
        }
	return 0;
}
static int buildAlternativeToc(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	if (doc->dom_doc) {
            doc->dom_doc->buildAlternativeToc();
        }
	return 0;
}

/*
 * Return a table like this:
 * {
 *		"FreeMono",
 *		"FreeSans",
 *		"FreeSerif",
 * }
 *
 */
static int getFontFaces(lua_State *L) {
	int i = 0;
	lString16Collection face_list;

	fontMan->getFaceList(face_list);

	lua_newtable(L);
	for (i = 0; i < face_list.length(); i++)
	{
		lua_pushnumber(L, i+1);
		lua_pushstring(L, UnicodeToLocal(face_list[i]).c_str());
		lua_settable(L, -3);
	}

	return 1;
}

static int setViewMode(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	LVDocViewMode view_mode = (LVDocViewMode)luaL_checkint(L, 2);

	doc->text_view->setViewMode(view_mode, -1);

	return 0;
}

static int setViewDimen(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int w = luaL_checkint(L, 2);
	int h = luaL_checkint(L, 3);

	doc->text_view->Resize(w, h);
	doc->text_view->Render();

	return 0;
}

static int setHeaderInfo(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int info = luaL_checkint(L, 2);

	doc->text_view->setPageHeaderInfo(info);

	return 0;
}

static int setHeaderFont(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const char *face = luaL_checkstring(L, 2);

	doc->text_view->setStatusFontFace(lString8(face));

	return 0;
}

static int setFontFace(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const char *face = luaL_checkstring(L, 2);

	doc->text_view->setDefaultFontFace(lString8(face));
	//fontMan->SetFallbackFontFace(lString8(face));

	return 0;
}

static int setAsPreferredFontWithBias(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const char *face = luaL_checkstring(L, 2);
	int bias = luaL_checkint(L, 3);
	bool clearOthersBias = true;
	if (lua_isboolean(L,4)) {
		clearOthersBias = lua_toboolean(L, 4);
	}

	fontMan->SetAsPreferredFontWithBias(lString8(face), bias, clearOthersBias);

	return 0;
}

static int gotoPage(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int pageno = luaL_checkint(L, 2);

	doc->text_view->goToPage(pageno-1);

	return 0;
}

static int gotoPercent(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int percent = luaL_checkint(L, 2);

	doc->text_view->SetPos(percent * doc->text_view->GetFullHeight() / 10000);

	return 0;
}

static int gotoPos(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int pos = luaL_checkint(L, 2);

	doc->text_view->SetPos(pos);

	return 0;
}

static int gotoXPointer(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const char *xpointer_str = luaL_checkstring(L, 2);

	ldomXPointer xp = doc->dom_doc->createXPointer(lString16(xpointer_str));

	doc->text_view->goToBookmark(xp);
	/* CREngine does not call checkPos() immediately after goToBookmark,
	 * so I have to manually update the pos in order to get a correct
	 * return from GetPos() call. */
	doc->text_view->SetPos(xp.toPoint().y);

	return 0;
}

/* zoom font by given delta and return zoomed font size */
static int zoomFont(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int delta = luaL_checkint(L, 2);

	doc->text_view->ZoomFont(delta);

	lua_pushnumber(L, doc->text_view->getFontSize());
	return 1;
}

static int setFontSize(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int size = luaL_checkint(L, 2);

	doc->text_view->setFontSize(size);
	return 0;
}

static int setDefaultInterlineSpace(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int space = luaL_checkint(L, 2);

	doc->text_view->setDefaultInterlineSpace(space);
	return 0;
}

static int setStyleSheet(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	lString8 css;

	if (lua_isstring(L, 2)) { // if css_file path provided, try reading it
		const char* css_file = luaL_checkstring(L, 2);
		if (! LVLoadStylesheetFile(lString16(css_file), css)){
			css = lString8(); // failed loading, continue with empty content
		}
	}

	if (lua_isstring(L, 3)) { // if css_content provided, append it
		const char* css_content = luaL_checkstring(L, 3);
		css << "\r\n" << lString8(css_content);
	}

	doc->text_view->setStyleSheet(css);
	return 0;
}

/// ------- Page Margins -------

static int setPageMargins(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	lvRect rc;
	rc.left = luaL_checkint(L, 2);
	rc.top = luaL_checkint(L, 3);
	rc.right = luaL_checkint(L, 4);
	rc.bottom = luaL_checkint(L, 5);
	doc->text_view->setPageMargins(rc);
    return 0;
}

static int getVisiblePageCount(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	lua_pushinteger(L, doc->text_view->getVisiblePageCount());

	return 1;
}

static int setVisiblePageCount(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	doc->text_view->setVisiblePageCount(luaL_checkint(L, 2));

	return 0;
}

static int adjustFontSizes(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    int dpi = luaL_checkint(L, 2);
    static int fontSizes[] = {	12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
				31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 42, 44, 48, 52, 56, 60, 64, 68, 72,
				78, 84, 90, 110, 130, 150, 170, 200, 230, 260, 300, 340};
    LVArray<int> sizes( fontSizes, sizeof(fontSizes)/sizeof(int) );
    doc->text_view->setFontSizes(sizes, false); // text
    if (dpi < 170) {
        doc->text_view->setStatusFontSize(20);  // header
    } else if (dpi > 250) {
        doc->text_view->setStatusFontSize(28);
    } else {
        doc->text_view->setStatusFontSize(24);
    }
    return 0;
}

static int getPageMargins(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	lvRect rc = doc->text_view->getPageMargins();

	lua_newtable(L);

	lua_pushstring(L, "left");
	lua_pushnumber(L, rc.left);
	lua_settable(L, -3);

	lua_pushstring(L, "top");
	lua_pushnumber(L, rc.top);
	lua_settable(L, -3);

	lua_pushstring(L, "right");
	lua_pushnumber(L, rc.right);
	lua_settable(L, -3);

	lua_pushstring(L, "bottom");
	lua_pushnumber(L, rc.bottom);
	lua_settable(L, -3);

	return 1;
}

static int setEmbeddedStyleSheet(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	doc->text_view->doCommand(DCMD_SET_INTERNAL_STYLES, luaL_checkint(L, 2));

	return 0;
}

static int setEmbeddedFonts(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	doc->text_view->doCommand(DCMD_SET_DOC_FONTS, luaL_checkint(L, 2));

	return 0;
}

static int toggleFontBolder(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	doc->text_view->doCommand(DCMD_TOGGLE_BOLD);

	return 0;
}

static int cursorRight(lua_State *L) {
	//CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	//LVDocView *tv = doc->text_view;

	//ldomXPointer p = tv->getCurrentPageMiddleParagraph();
	//lString16 s = p.getText();
	//lString16 s = p.toString();
	//printf("~~~~~~~~~~%s\n", UnicodeToLocal(s).c_str());

	//tv->selectRange(*(tv->selectFirstPageLink()));
	//ldomXRange *r = tv->selectNextPageLink(true);
	//lString16 s = r->getRangeText();
	//printf("------%s\n", UnicodeToLocal(s).c_str());

	//tv->selectRange(*r);
	//tv->updateSelections();

	//LVPageWordSelector sel(doc->text_view);
	//doc->text_view->doCommand(DCMD_SELECT_FIRST_SENTENCE);
	//sel.moveBy(DIR_RIGHT, 2);
	//printf("---------------- %s\n", UnicodeToLocal(sel.getSelectedWord()->getText()).c_str());

	return 0;
}

static int getLinkFromPosition(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int x = luaL_checkint(L, 2);
	int y = luaL_checkint(L, 3);

	lvPoint pt(x, y);
	ldomXPointer p = doc->text_view->getNodeByPoint(pt, true);
	ldomXPointer a_p;
	lString16 href = p.getHRef(a_p);
	lua_pushstring(L, UnicodeToLocal(href).c_str());
	if (!a_p.isNull()) { // return xpointer to <a> itself
		lua_pushstring(L, UnicodeToLocal(a_p.toString()).c_str());
		return 2;
	}
	return 1;
}

static int getWordFromPosition(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int x = luaL_checkint(L, 2);
	int y = luaL_checkint(L, 3);

	LVDocView *tv = doc->text_view;
	lvRect margin = tv->getPageMargins();
	int x_offset = margin.left;
	int y_offset = tv->GetPos() - (tv->getPageHeaderHeight() + margin.top) * (tv->getViewMode()==DVM_PAGES);

	LVPageWordSelector sel(tv);
	sel.selectWord(x - x_offset, y + y_offset);

	ldomWordEx * word = sel.getSelectedWord();
	lua_newtable(L); // new word box
	if (word) {
		lvRect rect;
		ldomXRange range = word->getRange();
		if (range.getRectEx(rect)) {
			lua_pushstring(L, "word");
			lua_pushstring(L, UnicodeToLocal(word->getText()).c_str());
			lua_settable(L, -3);
			lua_pushstring(L, "x0");
			lua_pushinteger(L, rect.left + x_offset);
			lua_settable(L, -3);
			lua_pushstring(L, "y0");
			lua_pushinteger(L, rect.top - y_offset);
			lua_settable(L, -3);
			lua_pushstring(L, "x1");
			lua_pushinteger(L, rect.right + x_offset);
			lua_settable(L, -3);
			lua_pushstring(L, "y1");
			lua_pushinteger(L, rect.bottom - y_offset);
			lua_settable(L, -3);
		}
	}
	return 1;
}

static int getTextFromPositions(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int x0 = luaL_checkint(L, 2);
	int y0 = luaL_checkint(L, 3);
	int x1 = luaL_checkint(L, 4);
	int y1 = luaL_checkint(L, 5);

	LVDocView *tv = doc->text_view;
	lvRect margin = tv->getPageMargins();

	lvPoint startpt(x0, y0);
	lvPoint endpt(x1, y1);
	ldomXPointer startp = tv->getNodeByPoint(startpt);
	ldomXPointer endp = tv->getNodeByPoint(endpt);
	if (!startp.isNull() && !endp.isNull()) {
	    lua_newtable(L); // new text boxes
		ldomXRange r(startp, endp);
		if (r.getStart().isNull() || r.getEnd().isNull())
			return 0;
		r.sort();

		if (!r.getStart().isVisibleWordStart())
			r.getStart().prevVisibleWordStart();
		if (!r.getEnd().isVisibleWordEnd())
			r.getEnd().nextVisibleWordEnd();
		if (r.isNull())
			return 0;

		if (r.getStart() == r.getEnd()) { // for single CJK character
			ldomNode * node = r.getStart().getNode();
			lString16 text = node->getText();
			int textLen = text.length();
			int offset = r.getEnd().getOffset();
			if (offset < textLen - 1)
				r.getEnd().setOffset(offset + 1);
		}

		r.setFlags(1);
		tv->selectRange(r);  // we don't need native highlight of selection

		int page = tv->getBookmarkPage(startp);
		int pages = tv->getPageCount();
		lString16 titleText;
		lString16 posText;
		tv->getBookmarkPosText(startp, titleText, posText);
		lString16 selText = r.getRangeText( '\n', 8192 );

		lua_pushstring(L, "text");
		lua_pushstring(L, UnicodeToLocal(selText).c_str());
		lua_settable(L, -3);
		lua_pushstring(L, "pos0");
		lua_pushstring(L, UnicodeToLocal(r.getStart().toString()).c_str());
		lua_settable(L, -3);
		lua_pushstring(L, "pos1");
		lua_pushstring(L, UnicodeToLocal(r.getEnd().toString()).c_str());
		lua_settable(L, -3);
		lua_pushstring(L, "title");
		lua_pushstring(L, UnicodeToLocal(titleText).c_str());
		lua_settable(L, -3);
		lua_pushstring(L, "context");
		lua_pushstring(L, UnicodeToLocal(posText).c_str());
		lua_settable(L, -3);
		lua_pushstring(L, "percent");
		lua_pushnumber(L, 1.0*page/(pages-1));
		lua_settable(L, -3);
	    return 1;
	}
    return 0;
}

void lua_pushLineRect(lua_State *L, int left, int top, int right, int bottom, int lcount) {
	lua_pushstring(L, "x0");
	lua_pushinteger(L, left);
	lua_settable(L, -3);
	lua_pushstring(L, "y0");
	lua_pushinteger(L, top);
	lua_settable(L, -3);
	lua_pushstring(L, "x1");
	lua_pushinteger(L, right);
	lua_settable(L, -3);
	lua_pushstring(L, "y1");
	lua_pushinteger(L, bottom);
	lua_settable(L, -3);
	lua_rawseti(L, -2, lcount);
}

bool docToWindowRect(LVDocView *tv, lvRect &rc) {
    lvPoint topLeft = rc.topLeft();
    lvPoint bottomRight = rc.bottomRight();
    if (tv->docToWindowPoint(topLeft)) {
        rc.setTopLeft(topLeft);
    }
    else {
        return false;
    }
    if (tv->docToWindowPoint(bottomRight)) {
        rc.setBottomRight(bottomRight);
    }
    else {
        return false;
    }
    return true;
}

static int getWordBoxesFromPositions(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const char* pos0 = luaL_checkstring(L, 2);
	const char* pos1 = luaL_checkstring(L, 3);

	LVDocView *tv = doc->text_view;
	ldomDocument *dv = doc->dom_doc;

	ldomXPointer startp = dv->createXPointer(lString16(pos0));
	ldomXPointer endp = dv->createXPointer(lString16(pos1));
	lua_newtable(L); // new word boxes
	if (!startp.isNull() && !endp.isNull()) {
		ldomXRange r(startp, endp);
		if (r.getStart().isNull() || r.getEnd().isNull())
			return 0;
		r.sort();

	        // Old saved highlights may have included punctuation at
	        // edges (they were not displayed in boxes because of
	        // lvtinydom.cpp's ldomWordsCollector catching only letters)
	        // and punctuation was considered part of the word
	        // (a space was the sole word separator), so
	        // r.getStart().isVisibleWordStart() and r.getEnd().isVisibleWordEnd()
	        // were always true.
	        // With our changes to word detection, this is no more true,
	        // and the next tests would gather the previous or following
	        // words, which were not part of the saved highlight !
	        // But we can change the method to indeed get the word just
	        // after or before the punctuation and actually get
	        // exactly the included words without punctuation
		if (!r.getStart().isVisibleWordStart())
			// r.getStart().prevVisibleWordStart();
			r.getStart().nextVisibleWordStart();
		if (!r.getEnd().isVisibleWordEnd())
			// r.getEnd().nextVisibleWordEnd();
			r.getEnd().prevVisibleWordEnd();
		if (r.isNull())
			return 0;

		r.setFlags(1);
		//tv->selectRange(r);  // we don't need native highlight of selection

		/*  accumulate text lines */
		LVArray<ldomWord> words;
		r.getRangeWords(words);
		lvRect charRect, wordRect, lineRect;
		int lcount = 1;
		int lastx = -1;
		lua_newtable(L); // first line box
		for (int i=0; i<words.length(); i++) {
			if (ldomXRange(words[i]).getRectEx(wordRect)) {
				if (!docToWindowRect(tv, wordRect)) continue;//docToWindowRect returns false means it is not on current showing page.
				if (wordRect.left < lastx) {
					lua_pushLineRect(L, lineRect.left, lineRect.top,
									    lineRect.right, lineRect.bottom, lcount++);
					lua_newtable(L); // new line box
					lineRect.clear();
				}
				lineRect.extend(wordRect);
				lastx = wordRect.left;
			} else {  // word is hyphenated
				ldomWord word = words[i];
				int y = -1;
				for (int j=word.getStart(); j < word.getEnd(); j++) {
					if (ldomXPointer(word.getNode(), j).getRectEx(charRect)) {
						if (!docToWindowRect(tv, charRect)) continue;
						if (y == -1) y = charRect.top;
						// charRect is now the width of each individual char.
						// Previously, ldomXPointer::getRectEx() was returning its
						// own word->width, so getting it only from the first call
						// looked like it was fine. But our "word"s come from
						// lStr_findWordBounds(), unlike the ones ldomXPointer::getRectEx()
						// uses that come from lvtextfm.cpp which splits on spaces only.
						// We would then get shifted highlights with some texts
						// (e.g. with french text "l'empereur" word->t.start starts
						// at 'l' while here our word may start at 'e'mpereur)
						// was: if (j != word.getStart() && y == charRect.top) continue;
						// Keep extending lineRect with each individual charRect we met.
						// When charRect.left < lastx, we are on next line and lineRect
						// is ready to be pushed.
						y = charRect.top;
						if (charRect.left < lastx) {
							lua_pushLineRect(L, lineRect.left, lineRect.top,
												lineRect.right, lineRect.bottom, lcount++);
							lua_newtable(L); // new line box
							lineRect.clear();
						}
						lineRect.extend(charRect);
						lastx = charRect.left;
					}
				}
			}
		}
		lua_pushLineRect(L, lineRect.left, lineRect.top,
							lineRect.right, lineRect.bottom, lcount);
	}
	return 1;
}

static int getPageLinks(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	lua_newtable(L); // all links

	ldomXRangeList links;
	ldomXRangeList & sel = doc->text_view->getDocument()->getSelections();

	doc->text_view->getCurrentPageLinks( links );
	int linkCount = links.length();
	if ( linkCount ) {
		sel.clear();
		lvRect margin = doc->text_view->getPageMargins();
		int x_offset = margin.left;
		int y_offset = doc->text_view->GetPos() - doc->text_view->getPageHeaderHeight() - margin.top;
		for ( int i=0; i<linkCount; i++ ) {
			lString16 txt = links[i]->getRangeText();
			lString8 txt8 = UnicodeToLocal( txt );

			ldomXPointer a_xpointer;
			lString16 link = links[i]->getHRef(a_xpointer);
			lString8 link8 = UnicodeToLocal( link );

			ldomXRange currSel;
			currSel = *links[i];

			lvPoint start_pt ( currSel.getStart().toPoint() );
			lvPoint end_pt ( currSel.getEnd().toPoint() );

				CRLog::debug("# link %d start %d %d end %d %d '%s' %s\n", i,
				start_pt.x, start_pt.y, end_pt.x, end_pt.y,
				txt8.c_str(), link8.c_str()
			);

			lua_newtable(L); // new link

			lua_pushstring(L, "start_x");
			lua_pushinteger(L, start_pt.x + x_offset);
			lua_settable(L, -3);
			lua_pushstring(L, "start_y");
			lua_pushinteger(L, start_pt.y - y_offset);
			lua_settable(L, -3);
			lua_pushstring(L, "end_x");
			lua_pushinteger(L, end_pt.x + x_offset);
			lua_settable(L, -3);
			lua_pushstring(L, "end_y");
			lua_pushinteger(L, end_pt.y - y_offset);
			lua_settable(L, -3);

			if (!a_xpointer.isNull()) { // xpointer to <a> itself
				lua_pushstring(L, "a_xpointer");
				lua_pushstring(L, UnicodeToLocal(a_xpointer.toString()).c_str());
				lua_settable(L, -3);
			}

			const char * link_to = link8.c_str();

			if ( link_to[0] == '#' ) {
				lua_pushstring(L, "section");
				lua_pushstring(L, link_to);
				lua_settable(L, -3);

				sel.add( new ldomXRange(*links[i]) ); // highlight
			} else {
				lua_pushstring(L, "uri");
				lua_pushstring(L, link_to);
				lua_settable(L, -3);
			}

			lua_rawseti(L, -2, i + 1);

		}
		doc->text_view->updateSelections();
	}

	return 1;
}

static int gotoLink(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const char *pos = luaL_checkstring(L, 2);

	doc->text_view->goLink(lString16(pos), true);

	return 0;
}

static int goBack(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	doc->text_view->goBack();

	return 0;
}

static int goForward(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	doc->text_view->goForward();

	return 0;
}

static int clearSelection(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	doc->text_view->clearSelection();

	return 0;
}

static int drawCurrentPage(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	BlitBuffer *bb = (BlitBuffer*) lua_topointer(L, 2);
	bool color = false;
	if (lua_isboolean(L, 3)) {
		color = lua_toboolean(L, 3);
	}

	int w = bb->w,
		h = bb->h;

	doc->text_view->Resize(w, h);
	doc->text_view->Render();
	if (color) {
		/* Use Color buffer - caller should have provided us with a
                 * Blitbuffer.TYPE_BBRGB16, see CreDocument:drawCurrentView
                 * for why not TYPE_BBRGB32) */
		LVColorDrawBuf drawBuf(w, h, bb->data, 16);
		doc->text_view->Draw(drawBuf, false);
	}
	else {
		/* Set DrawBuf to 8bpp */
		LVGrayDrawBuf drawBuf(w, h, 8, bb->data);
		doc->text_view->Draw(drawBuf, false);
	}

	return 0;
}

static int drawCoverPage(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	BlitBuffer *bb = (BlitBuffer*) lua_topointer(L, 2);

	int w = bb->w,
		h = bb->h;
	/* Set DrawBuf to 8bpp */
	LVGrayDrawBuf drawBuf(w, h, 8, bb->data);

	LVImageSourceRef cover = doc->text_view->getCoverPageImage();
	if (!cover.isNull())
		printf("cover size:%d,%d\n", cover->GetWidth(), cover->GetHeight());
	else
		printf("cover page is null.\n");
	LVDrawBookCover(drawBuf, cover, lString8("Droid Sans Mono"),
			lString16("test"), lString16("test"), lString16("test"), 0);

	return 0;
}

static int getCoverPageImageData(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	LVStreamRef stream = doc->text_view->getCoverPageImageStream();
	if (!stream.isNull()) {
		unsigned size = stream->GetSize();
		lvsize_t read_size = 0;
		void *buffer = (void *)malloc(size);
		/* This malloc'ed buffer NEEDs to be freed from lua after use with :
		 *     ffi.C.free(data)
		 * to not leak memory */
		if (buffer != NULL) {
			stream->Read(buffer, size, &read_size);
			if (read_size == size) {
				lua_pushlightuserdata(L, buffer);
				lua_pushinteger(L, size);
				return 2;
			}
		}
	}
	return 0;
}

static int registerFont(lua_State *L) {
	const char *fontfile = luaL_checkstring(L, 1);
	if ( !fontMan->RegisterFont(lString8(fontfile)) ) {
		return luaL_error(L, "cannot register font <%s>", fontfile);
	}
	return 0;
}

// ported from Android UI kpvcrlib/crengine/android/jni/docview.cpp

static int findText(lua_State *L) {
	CreDocument *doc		= (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const char *l_pattern   = luaL_checkstring(L, 2);
	lString16 pattern		= lString16(l_pattern);
	int origin				= luaL_checkint(L, 3);
	bool reverse			= luaL_checkint(L, 4);
	bool caseInsensitive	= luaL_checkint(L, 5);

    if ( pattern.empty() )
        return 0;

    LVArray<ldomWord> words;
    lvRect rc;
    doc->text_view->GetPos( rc );
    int pageHeight = doc->text_view->GetHeight();
    // To not miss any occurence, and have them all highlighted,
    // we need to search in 3*pageHeight:
    // 1) the current page that we may include in start-end below,
    // 2) the next/previous page where we may find our interesting occurences
    // 3) the page after/before that one, where some node shown on 2) may start or end in
    // (We only need to use "2 * pageHeight" here, because current page (1) is
    // not accounted for searchHeight, thanks to the searchHeightCheckStartY
    // we set below when needed)
    int searchHeight = 2 * pageHeight;
    // And to not be stopped from searching further if there is a hit on current page,
    // but none on 2) & 3): let crengine not start ensuring searchHeight before
    // we pass beyond current page.
    int searchHeightCheckStartY = -1;
    // So, below, we include current page when needed, and adjust searchHeightCheckStartY
    // accordingly.
    // Results will be highlighted on multiple page, but lua code will find the good
    // page to go to and show among the results.

    int start = -1;
    int end = -1;
    if ( reverse ) {
        // backward
        if ( origin == 0 ) {
            // from end of current page to first page
            end = rc.bottom;
            searchHeightCheckStartY = rc.top - 1;
        } else if ( origin == -1 ) {
            // from the last page to end of current page
            // start = rc.bottom + 1;
            start = rc.top; // avoid edge cases and include current page
        } else { // origin == 1
            // from prev page to the first page
            // end = rc.top - 1;
            if (rc.top == 0) // if we are on first page, nothing to search back
                return 0;
            end = rc.bottom; // avoid edge cases and include current page
            searchHeightCheckStartY = rc.top - 1;
        }
    } else {
        // forward
        if ( origin == 0 ) {
            // from current page to the last page
            start = rc.top;
            searchHeightCheckStartY = rc.bottom + 1;
        } else if ( origin == -1 ) {
            // from the first page to current page
            // end = rc.top + 1;
            end = rc.bottom; // avoid edge cases and include current page
        } else { // origin == 1
            // from next page to the last page
            // start = rc.bottom + 1;
            start = rc.top; // avoid edge cases and include current page
            searchHeightCheckStartY = rc.bottom + 1;
        }
    }
    CRLog::debug("CRViewDialog::findText: Current page: %d .. %d", rc.top, rc.bottom);
    CRLog::debug("CRViewDialog::findText: searching for text '%s' from %d to %d origin %d", LCSTR(pattern), start, end, origin );
    if ( doc->text_view->getDocument()->findText( pattern, caseInsensitive, reverse, start, end, words, 200, searchHeight, searchHeightCheckStartY ) ) {
        CRLog::debug("CRViewDialog::findText: pattern found");
        doc->text_view->clearSelection();
        doc->text_view->selectWords( words );
        ldomMarkedRangeList * ranges = doc->text_view->getMarkedRanges();
        if ( ranges && ranges->length() > 0 ) {
            lua_newtable(L); // hold all words
            for (int i = 0; i < words.length(); i++) {
                ldomWord word = words[i];
                lua_newtable(L); // new word
                lua_pushstring(L, "start");
                lua_pushstring(L, UnicodeToLocal(word.getStartXPointer().toString()).c_str());
                lua_settable(L, -3);
                lua_pushstring(L, "end");
                lua_pushstring(L, UnicodeToLocal(word.getEndXPointer().toString()).c_str());
                lua_settable(L, -3);
                lua_rawseti(L, -2, i + 1);
            }
            return 1;
        }
    }
    CRLog::debug("CRViewDialog::findText: pattern not found");
    return 0;
}

static int setBatteryState(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int state = luaL_checkint(L, 2);
	doc->text_view->setBatteryState(state);
	return 0;
}

static int isXPointerInCurrentPage(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const char *xpointer = luaL_checkstring(L, 2);

	lvRect page_rect, xp_rect;
	doc->text_view->GetPos(page_rect);
	doc->dom_doc->createXPointer(lString16(xpointer)).getRect(xp_rect);
	//CRLog::trace("page range: %d,%d - %d,%d", page_rect.left, page_rect.top, page_rect.right, page_rect.bottom);
	//CRLog::trace("xp range: %d,%d - %d,%d", xp_rect.left, xp_rect.top, xp_rect.right, xp_rect.bottom);
	lua_pushboolean(L, page_rect.isRectInside(xp_rect));
	return 1;
}

static int isXPointerInDocument(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char *xpointer_str = luaL_checkstring(L, 2);

    bool found = true;
    ldomXPointer xp = doc->dom_doc->createXPointer(lString16(xpointer_str));
    lvPoint pt = xp.toPoint();
    if (pt.y < 0) {
        found = false;
    }
    lua_pushboolean(L, found);
    return 1;
}

static int getImageDataFromPosition(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    int x = luaL_checkint(L, 2);
    int y = luaL_checkint(L, 3);
    lvPoint pt(x, y);
    ldomXPointer ptr = doc->text_view->getNodeByPoint(pt);
    if (ptr.isNull())
        return 0;
    LVStreamRef stream = ptr.getNode()->getObjectImageStream();
    if (!stream.isNull()) {
        unsigned size = stream->GetSize();
        lvsize_t read_size = 0;
        void *buffer = (void *)malloc(size);
        /* This malloc'ed buffer NEEDs to be freed from lua after use with :
         *     ffi.C.free(data)
         * to not leak memory */
        if (buffer != NULL) {
            stream->Read(buffer, size, &read_size);
            if (read_size == size) {
                // buffer may be SVG data, that MuPDF does not support yet (20170429)
                // But crengine (with nanosvg code) can convert SVG to PNG, so let's do that here
                unsigned char *cbuf = (unsigned char*) buffer; // cast same void pointer to char pointer
                // if buffer starts with <?xml or <svg, it's probably SVG
                if ( (size > 5 && cbuf[0]=='<' && cbuf[1]=='?' && (cbuf[2]=='x' || cbuf[2] == 'X') && (cbuf[3]=='m' || cbuf[3] == 'M') && (cbuf[4]=='l' || cbuf[4] == 'L')) ||
                     (size > 4 && cbuf[0]=='<' && (cbuf[1]=='s' || cbuf[1] == 'S') && (cbuf[2]=='v' || cbuf[2] == 'V') && (cbuf[3]=='g' || cbuf[3] == 'G')) ) {
                    unsigned char *pngbuf;
                    int pngbuflen;
                    // We use a zoom_factor of 4 to return a higher quality rasterized image from the SVG vector image
                    pngbuf = convertSVGtoPNG(cbuf, size, 4, &pngbuflen); // provided by crengine/src/lvimg.cpp
                    if (pngbuf != NULL) {
                        // free SVG data, and return PNG data instead
                        free(buffer);
                        lua_pushlightuserdata(L, (void*)pngbuf);
                        lua_pushinteger(L, pngbuflen);
                        return 2;
                    }
                    // if it failed, go on returning original data
                }
                lua_pushlightuserdata(L, buffer);
                lua_pushinteger(L, size);
                return 2;
            }
        }
    }
    return 0;
}


static const struct luaL_Reg cre_func[] = {
	{"initCache", initCache},
	{"initHyphDict", initHyphDict},
	{"newDocView", newDocView},
	{"getFontFaces", getFontFaces},
	{"getGammaLevel", getGammaLevel},
	{"getGammaIndex", getGammaIndex},
	{"setGammaIndex", setGammaIndex},
	{"registerFont", registerFont},
	{"getHyphDictList", getHyphDictList},
	{"getSelectedHyphDict", getSelectedHyphDict},
	{"setHyphDictionary", setHyphDictionary},
	{"getLatestDomVersion", getLatestDomVersion},
	{"requestDomVersion", requestDomVersion},
	{NULL, NULL}
};

static const struct luaL_Reg credocument_meth[] = {
	{"loadDocument", loadDocument},
	{"renderDocument", renderDocument},
	/*--- get methods ---*/
	{"getIntProperty", getIntProperty},
	{"getStringProperty", getStringProperty},
	{"getDocumentProps", getDocumentProps},
	{"getPages", getNumberOfPages},
	{"getCurrentPage", getCurrentPage},
	{"getPageFromXPointer", getPageFromXPointer},
	{"getPosFromXPointer", getPosFromXPointer},
	{"getCurrentPos", getCurrentPos},
	{"getCurrentPercent", getCurrentPercent},
	{"getXPointer", getXPointer},
	{"getFullHeight", getFullHeight},
	{"getFontSize", getFontSize},
	{"getFontFace", getFontFace},
	{"getPageMargins", getPageMargins},
	{"getToc", getTableOfContent},
	{"getVisiblePageCount", getVisiblePageCount},
	/*--- set methods ---*/
	{"setIntProperty", setIntProperty},
	{"setStringProperty", setStringProperty},
	{"setViewMode", setViewMode},
	{"setViewDimen", setViewDimen},
	{"setHeaderInfo", setHeaderInfo},
	{"setHeaderFont", setHeaderFont},
	{"setFontFace", setFontFace},
	{"setAsPreferredFontWithBias", setAsPreferredFontWithBias},
	{"setFontSize", setFontSize},
	{"setDefaultInterlineSpace", setDefaultInterlineSpace},
	{"setStyleSheet", setStyleSheet},
	{"setEmbeddedStyleSheet", setEmbeddedStyleSheet},
	{"setEmbeddedFonts", setEmbeddedFonts},
	{"setPageMargins", setPageMargins},
	{"setVisiblePageCount", setVisiblePageCount},
	{"adjustFontSizes", adjustFontSizes},
	{"setBatteryState", setBatteryState},
	/* --- control methods ---*/
	{"isBuiltDomStale", isBuiltDomStale},
	{"hasCacheFile", hasCacheFile},
	{"invalidateCacheFile", invalidateCacheFile},
	{"getCacheFilePath", getCacheFilePath},
	{"buildAlternativeToc", buildAlternativeToc},
	{"isTocAlternativeToc", isTocAlternativeToc},
	{"gotoPage", gotoPage},
	{"gotoPercent", gotoPercent},
	{"gotoPos", gotoPos},
	{"gotoXPointer", gotoXPointer},
	{"zoomFont", zoomFont},
	{"toggleFontBolder", toggleFontBolder},
	//{"cursorLeft", cursorLeft},
	//{"cursorRight", cursorRight},
	{"drawCurrentPage", drawCurrentPage},
	//{"drawCoverPage", drawCoverPage},
	{"findText", findText},
	{"isXPointerInCurrentPage", isXPointerInCurrentPage},
	{"isXPointerInDocument", isXPointerInDocument},
	{"getLinkFromPosition", getLinkFromPosition},
	{"getWordFromPosition", getWordFromPosition},
	{"getTextFromPositions", getTextFromPositions},
	{"getWordBoxesFromPositions", getWordBoxesFromPositions},
	{"getImageDataFromPosition", getImageDataFromPosition},
	{"getPageLinks", getPageLinks},
	{"getCoverPageImageData", getCoverPageImageData},
	{"gotoLink", gotoLink},
	{"goBack", goBack},
	{"goForward", goForward},
	{"clearSelection", clearSelection},
	{"saveDefaults", saveDefaults},
	{"close", closeDocument},
	{"__gc", closeDocument},
	{NULL, NULL}
};

int luaopen_cre(lua_State *L) {
	luaL_newmetatable(L, "credocument");
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);
	lua_settable(L, -3);
	luaL_register(L, NULL, credocument_meth);
	lua_pop(L, 1);
	luaL_register(L, "cre", cre_func);

	/* initialize font manager for CREngine */
	InitFontManager(lString8());

#if DEBUG_CRENGINE
	CRLog::setStdoutLogger();
	CRLog::setLogLevel(CRLog::LL_TRACE);
#endif

	return 1;
}
