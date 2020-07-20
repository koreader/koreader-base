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

// Single global object to handle callbacks from crengine to Lua
class CreCallbackForwarder : public LVDocViewCallback
{
    bool _active;
    lua_State * _L; // stack (of the coroutine) that set the callback
    // References in the Lua registry, to prevent these objects to be gc()'ed
    int _r_L; // ref to L, to prevent it from being gc'ed when coroutine ends
    int _r_cb; // ref to provided Lua function to be forwarded crengine events
public:
    CreCallbackForwarder() :
        _active(false),
        // As a crengine document is opened from inside a coroutine, but can be closed
        // from the main thread, and as Lua 5.1 does not provide access to the main thread
        // from a coroutine, we need to store the coroutine lua_State to keep a reference
        // to it and prevent if from being gc'ed.
        // Fortunatly, the registry index is shared by the main thread and all coroutines
        _L(NULL),
        _r_L(LUA_NOREF),
        _r_cb(LUA_NOREF)
        { }
    void setCallback(lua_State *L) {
        // Cleanup any previous references
        unsetCallback(L);
        // Get and keep reference to the callback (first on the stack)
        _r_cb = luaL_ref(L, LUA_REGISTRYINDEX);
        // printf("CreCallbackForwarder._r_cb = %x\n", _r_cb);
        // Push current coroutine/thread (L) onto the stack, and keep a reference to it,
        // so it does not get gc'ed when our coroutine exits
        lua_pushthread(L);
        _r_L = luaL_ref(L, LUA_REGISTRYINDEX);
        // printf("CreCallbackForwarder._r_L = %x\n", _r_L);
        _L = L; // Store L, so we can fetch the callback from _r_cb
        _active = true;
    }
    void unsetCallback(lua_State *L) {
        _active = false;
        if (_r_cb != LUA_NOREF) {
            luaL_unref(L, LUA_REGISTRYINDEX, _r_cb);
            _r_cb = LUA_NOREF;
        }
        if (_r_L != LUA_NOREF) {
            luaL_unref(L, LUA_REGISTRYINDEX, _r_L);
            _r_L = LUA_NOREF;
        }
        _L = NULL;
    }
    void callback(const char * event) {
        if (!_active)
            return;
        lua_rawgeti(_L, LUA_REGISTRYINDEX, _r_cb);
        lua_pushstring(_L, event);
        lua_pcall(_L, 1, 0, 0);
    }
    void callback(const char * event, int number) {
        if (!_active)
            return;
        lua_rawgeti(_L, LUA_REGISTRYINDEX, _r_cb);
        lua_pushstring(_L, event);
        lua_pushnumber(_L, number);
        lua_pcall(_L, 2, 0, 0);
    }
    void callback(const char * event, const char * str) {
        if (!_active)
            return;
        lua_rawgeti(_L, LUA_REGISTRYINDEX, _r_cb);
        lua_pushstring(_L, event);
        lua_pushstring(_L, str);
        lua_pcall(_L, 2, 0, 0);
    }
    virtual void OnLoadFileStart( lString16 filename ) {
        callback("OnLoadFileStart", UnicodeToLocal(filename).c_str());
    }
    virtual void OnLoadFileFormatDetected( doc_format_t fileFormat) {
        callback("OnLoadFileFormatDetected", UnicodeToLocal(getDocFormatName(fileFormat)).c_str());
    }
    virtual void OnLoadFileProgress( int percent) {
        callback("OnLoadFileProgress", percent);
    }
    virtual void OnLoadFileEnd() {
        callback("OnLoadFileEnd");
    }
    virtual void OnLoadFileError(lString16 message) {
        callback("OnLoadFileError", UnicodeToLocal(message).c_str());
    }
    virtual void OnNodeStylesUpdateStart() {
        callback("OnNodeStylesUpdateStart");
    }
    virtual void OnNodeStylesUpdateProgress(int percent) {
        callback("OnNodeStylesUpdateProgress", percent);
    }
    virtual void OnNodeStylesUpdateEnd() {
        callback("OnNodeStylesUpdateEnd");
    }
    virtual void OnFormatStart() {
        callback("OnFormatStart");
    }
    virtual void OnFormatProgress(int percent) {
        callback("OnFormatProgress", percent);
    }
    virtual void OnFormatEnd() {
        callback("OnFormatEnd");
    }
    virtual void OnDocumentReady() {
        callback("OnDocumentReady");
    }
    virtual void OnSaveCacheFileStart() {
        callback("OnSaveCacheFileStart");
    }
    virtual void OnSaveCacheFileProgress(int percent) {
        callback("OnSaveCacheFileProgress", percent);
    }
    virtual void OnSaveCacheFileEnd() {
        callback("OnSaveCacheFileEnd");
    }
    // virtual void OnLoadFileFirstPagesReady() { } // useless
    // virtual void OnExportProgress(int percent) { } // Export to WOL format
    // virtual void OnExternalLink(lString16 /*url*/, ldomNode * /*node*/) { }
    // virtual void OnImageCacheClear() { }
    // virtual bool OnRequestReload() { return false; }
};

CreCallbackForwarder * cre_callback_forwarder = NULL;

typedef struct CreDocument {
	LVDocView *text_view;
	ldomDocument *dom_doc;
} CreDocument;

static int setCallback(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    if ( cre_callback_forwarder == NULL ) {
        cre_callback_forwarder = new CreCallbackForwarder();
    }
    if (lua_isfunction(L, 2)) {
        cre_callback_forwarder->setCallback(L);
        doc->text_view->setCallback(cre_callback_forwarder);
    }
    else {
        doc->text_view->setCallback(NULL);
        cre_callback_forwarder->unsetCallback(L);
    }
    return 0;
}

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

	doc->text_view = new LVDocView(-1, true); // bitsPerPixel=-1, noDefaultDocument=true
	//doc->text_view->setBackgroundColor(0xFFFFFF);
	//doc->text_view->setTextColor(0x000000);
	//doc->text_view->doCommand(DCMD_SET_DOC_FONTS, 1);
	//doc->text_view->doCommand(DCMD_SET_INTERNAL_STYLES, 1);
	doc->text_view->setViewMode(view_mode, -1);
	doc->text_view->Resize(width, height);
	doc->text_view->setPageHeaderInfo(PGHDR_AUTHOR|PGHDR_TITLE|PGHDR_PAGE_NUMBER|PGHDR_PAGE_COUNT|PGHDR_CHAPTER_MARKS|PGHDR_CLOCK);
	doc->text_view->setBatteryIcons(getBatteryIcons(0x000000));

	return 1;
}

static int readDefaults(lua_State *L) {
	// This is to be called only when the document is opened to be
	// read by ReaderUI - not when the document is opened to just
	// get its metadata or cover image - as it will affect some
	// crengine global variables and state, whose change would
	// affect the currently opened for reading document.
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

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
                // Note: the values we set here don't really matter, they will
                // be re-set/overridden by readerfont.lua on each book load
		props->setInt(PROP_FONT_HINTING, 2); // autohint, to be conservative (some ttf fonts' bytecode is truly crappy)
		props->setInt(PROP_FONT_KERNING, 3); // harfbuzz (slower than freetype kerning, but needed for proper arabic)
		// props->setInt(PROP_FONT_KERNING_ENABLED, 1);
		props->setString("styles.pre.font-face", "font-family: \"Droid Sans Mono\"");

		stream = LVOpenFileStream("data/cr3.ini", LVOM_WRITE);
		props->saveToStream(stream.get());
	}
	return 0;
}

static int saveDefaults(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	CRPropRef props = doc->text_view->propsGetCurrent();
	LVStreamRef stream = LVOpenFileStream("data/cr3.ini", LVOM_WRITE);
	return props->saveToStream(stream.get());
}

static int getLatestDomVersion(lua_State *L) {
    lua_pushnumber(L, gDOMVersionCurrent);
    return 1;
}

static int getDomVersionWithNormalizedXPointers(lua_State *L) {
    lua_pushnumber(L, DOM_VERSION_WITH_NORMALIZED_XPOINTERS); // defined in lvtinydom.h
    return 1;
}

static int requestDomVersion(lua_State *L) {
    int version = luaL_checkint(L, 1);
    gDOMVersionRequested = version;
    return 0;
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

static int getTextLangStatus(lua_State *L) {
	lua_pushstring(L, UnicodeToLocal(TextLangMan::getMainLang()).c_str());
	lua_pushstring(L, UnicodeToLocal(TextLangMan::getMainLangHyphMethod()->getId()).c_str());
	lua_newtable(L);
	LVPtrVector<TextLangCfg> *list = TextLangMan::getLangCfgList();
	for(int i = 0; i < list->length(); i++) {
                TextLangCfg * lang_cfg = list->get(i);
		// Key
		lua_pushstring(L, UnicodeToLocal(lang_cfg->getLangTag()).c_str());
		// Value: table
		lua_newtable(L);

		lua_pushstring(L, "hyph_dict_name");
		lua_pushstring(L, UnicodeToLocal(lang_cfg->getDefaultHyphMethod()->getId()).c_str());
		lua_settable(L, -3);

		lua_pushstring(L, "hyph_nb_patterns");
		lua_pushinteger(L, lang_cfg->getDefaultHyphMethod()->getCount());
		lua_settable(L, -3);

		lua_pushstring(L, "hyph_mem_size");
		lua_pushinteger(L, lang_cfg->getDefaultHyphMethod()->getSize());
		lua_settable(L, -3);

		lua_settable(L, -3);
	}
	return 3;
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
		// Call close() to have the cache explicitely saved now
		// while we still have a callback (to show its progress).
		doc->text_view->close();
		// Remove any callback
		if (cre_callback_forwarder) {
			doc->text_view->setCallback(NULL);
			cre_callback_forwarder->unsetCallback(L);
		}
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

static int getStatistics(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    lString16 stats = doc->dom_doc->getStatistics();
    lua_pushstring(L, UnicodeToLocal(stats).c_str());
    return 1;
}

static int getUnknownEntities(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    lString16Collection unknown_entities = doc->dom_doc->getUnknownEntities();
    lua_pushstring(L, UnicodeToLocal(unknown_entities[0]).c_str());
    lua_pushstring(L, UnicodeToLocal(unknown_entities[1]).c_str());
    lua_pushstring(L, UnicodeToLocal(unknown_entities[2]).c_str());
    return 3;
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
	if ( !xp.isNull() ) { // Found in document
		// Ensure xp points to a visible node that has a y in the document.
		// If it is invisible, get the next visible node
		ldomXPointerEx xpe = xp;
		if ( xpe.isText() )
			xpe.parent();
		if ( xpe.getNode()->getRendMethod() == erm_invisible ) {
			xpe = xp;
			while ( xpe.nextElement() ) {
				if ( xpe.getNode()->getRendMethod() != erm_invisible ) {
					xp = xpe;
					break;
				}
			}
		}
		page = doc->text_view->getBookmarkPage(xp) + 1;
	}

	lua_pushinteger(L, page);
	return 1;
}

static int getPosFromXPointer(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const char *xpointer_str = luaL_checkstring(L, 2);

	int y = 0;
	int x = 0;
	ldomXPointer xp = doc->dom_doc->createXPointer(lString16(xpointer_str));
	if ( !xp.isNull() ) { // Found in document
		// Ensure xp points to a visible node that has a y in the document.
		// If it is invisible, get the next visible node
		ldomXPointerEx xpe = xp;
		if ( xpe.isText() )
			xpe.parent();
		if ( xpe.getNode()->getRendMethod() == erm_invisible ) {
			xpe = xp;
			while ( xpe.nextElement() ) {
				if ( xpe.getNode()->getRendMethod() != erm_invisible ) {
					xp = xpe;
					break;
				}
			}
		}
		lvPoint pt = xp.toPoint(true); // extended=true, for better accuracy
		if (pt.y > 0) {
			y = pt.y;
		}
		x = pt.x;
	}

	lua_pushinteger(L, y);
	// Also returns the x value (as the 2nd returned value, as its
	// less interesting to current code than the y value)
	lua_pushinteger(L, x);
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

static int getPageStartY(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int pageno = luaL_checkint(L, 2);

	lua_pushinteger(L, doc->text_view->getPageStartY(pageno - 1));

	return 1;
}

static int getPageHeight(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int pageno = luaL_checkint(L, 2);

	lua_pushinteger(L, doc->text_view->getPageHeight(pageno - 1));

	return 1;
}

static int getPageOffsetX(lua_State *L) {
	// Mostly useful to get the 2nd page x in 2-pages mode
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int pageno = luaL_checkint(L, 2);

	lvRect rc;
	doc->text_view->getPageRectangle(pageno - 1, rc);
	lua_pushinteger(L, rc.left);

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

static int hasPageMap(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

    LVPageMap * pagemap = doc->text_view->getPageMap();
    bool has_pagemap = pagemap->getChildCount() > 0;
    lua_pushboolean(L, has_pagemap);
    return 1;
}

static int getPageMap(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

    LVPageMap * pagemap = doc->text_view->getPageMap();
    int nb = pagemap->getChildCount();
    if ( !nb )
        return 0;

    lua_newtable(L);
    for (int i = 0; i < nb; i++)  {
        LVPageMapItem * item = pagemap->getChild(i);
        lua_pushnumber(L, i+1);

        // New table for item
        lua_newtable(L);

        lua_pushstring(L, "page");
        lua_pushnumber(L, item->getPage()+1);
        lua_settable(L, -3);

        // Note: toc_tmp->getXPointer().toString() and toc_tmp->getPath() return
        // the same xpath string. But when just loaded from cache, the XPointer
        // is not yet available, but getPath() is. So let's use it, which avoids
        // having to build the XPointers until they are needed to update page numbers.
        lua_pushstring(L, "xpointer");
        lua_pushstring(L, UnicodeToLocal(item->getPath()).c_str());
        lua_settable(L, -3);

        lua_pushstring(L, "doc_y");
        lua_pushnumber(L, item->getDocY());
        lua_settable(L, -3);

        lua_pushstring(L, "label");
        lua_pushstring(L, UnicodeToLocal(item->getLabel()).c_str());
        lua_settable(L, -3);

        // add item to returned table
        lua_settable(L, -3);
    }
    return 1;
}

static int getPageMapSource(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

    LVPageMap * pagemap = doc->text_view->getPageMap();
    lString16 source = pagemap->getSource();
    if ( source.empty() )
        return 0;
    lua_pushstring(L, UnicodeToLocal(source).c_str());
    return 1;
}

static int getPageMapFirstPageLabel(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

    LVDocView * tv = doc->text_view;
    LVPageMap * pagemap = tv->getPageMap();
    int nb = pagemap->getChildCount();
    if ( !nb )
        return 0;
    lua_pushstring(L, UnicodeToLocal(pagemap->getChild(0)->getLabel()).c_str());
    return 1;
}

static int getPageMapLastPageLabel(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

    LVDocView * tv = doc->text_view;
    LVPageMap * pagemap = tv->getPageMap();
    int nb = pagemap->getChildCount();
    if ( !nb )
        return 0;
    lua_pushstring(L, UnicodeToLocal(pagemap->getChild(nb-1)->getLabel()).c_str());
    return 1;
}

static int getPageMapCurrentPageLabel(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

    LVDocView * tv = doc->text_view;
    LVPageMap * pagemap = tv->getPageMap();
    int nb = pagemap->getChildCount();
    if ( !nb )
        return 0;

    // Note: in scroll mode with PDF, when multiple pages are shown on
    // the screen, the advertized page number is the greatest page number
    // among the pages shown (so, the page number of the partial page
    // shown at bottom of screen).
    // For consistency, we return the last page label shown in the view
    // if there are more than one (or the previous one if there is none).
    lvRect rc;
    tv->GetPos(rc);
    int max_y = rc.bottom;

    // Binary search to find the last doc_y < max_y
    // (We expect items to be ordered by doc_y)
    // https://en.wikipedia.org/wiki/Binary_search_algorithm#Procedure_for_finding_the_leftmost_element
    int left = 0;
    int right = nb;
    int middle;
    while ( left < right ) {
        middle = (left + right) / 2;
        int y = pagemap->getChild(middle)->getDocY();
        if ( y >= max_y )
            right = middle;
        else
            left = middle + 1;
    }
    int idx = left-1;
    if ( idx < 0 )
        idx = 0;
    else if (idx >= nb)
        idx = nb - 1;
    lua_pushstring(L, UnicodeToLocal(pagemap->getChild(idx)->getLabel()).c_str());
    return 1;
}

static int getPageMapXPointerPageLabel(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char *xpointer_str = luaL_checkstring(L, 2);

    LVDocView * tv = doc->text_view;
    LVPageMap * pagemap = tv->getPageMap();
    int nb = pagemap->getChildCount();
    if ( !nb )
        return 0;

    ldomXPointer xp = doc->dom_doc->createXPointer(lString16(xpointer_str));

    lvPoint pt = xp.toPoint(true); // extended=true, for better accuracy
    int xp_y = pt.y >= 0 ? pt.y : 0;

    // Binary search to find the last doc_y <= xp_y
    int left = 0;
    int right = nb;
    int middle;
    while ( left < right ) {
        middle = (left + right) / 2;
        int y = pagemap->getChild(middle)->getDocY();
        if ( y > xp_y )
            right = middle;
        else
            left = middle + 1;
    }
    int idx = left-1;
    if ( idx < 0 )
        idx = 0;
    else if (idx >= nb)
        idx = nb - 1;
    lua_pushstring(L, UnicodeToLocal(pagemap->getChild(idx)->getLabel()).c_str());
    return 1;
}

static int getPageMapVisiblePageLabels(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

    LVDocView * tv = doc->text_view;
    LVPageMap * pagemap = tv->getPageMap();
    int nb = pagemap->getChildCount();
    if ( !nb )
        return 0;

    // Get visible min and max doc_y
    lvRect rc;
    tv->GetPos(rc);
    int min_y = rc.top;
    int max_y = rc.bottom;
    int page2_y = -1;
    if ( tv->getVisiblePageCount() == 2 ) {
        int next_page = tv->getCurPage() + 1;
        if ( next_page < tv->getPageCount() ) {
            page2_y = tv->getPageStartY( next_page );
        }
    }

    bool is_page_mode = tv->getViewMode()==DVM_PAGES;
    int offset_y = is_page_mode ? tv->getPageMargins().top + tv->getPageHeaderHeight() : 0;

    // Binary search to find the first y >= min_y
    // (We expect items to be ordered by doc_y)
    // https://en.wikipedia.org/wiki/Binary_search_algorithm#Procedure_for_finding_the_leftmost_element
    int left = 0;
    int right = nb;
    int middle;
    while ( left < right ) {
        middle = (left + right) / 2;
        int y = pagemap->getChild(middle)->getDocY();
        if ( y < min_y )
            left = middle + 1;
        else
            right = middle;
    }
    int start = left;

    lua_newtable(L);
    int count = 1;
    for (int i = start; i < nb; i++)  {
        LVPageMapItem * item = pagemap->getChild(i);
        int doc_y = item->getDocY();
        if ( doc_y >= max_y)
            break;
        if ( doc_y < min_y ) // should not happen
            continue;

        int screen_page = 1;
        int screen_y = doc_y - min_y + offset_y;
        if ( page2_y >= 0 && doc_y >= page2_y ) {
            screen_page = 2;
            screen_y = doc_y - page2_y + offset_y;
        }

        lua_pushnumber(L, count++);

        // New table for item
        lua_newtable(L);

        lua_pushstring(L, "screen_page");
        lua_pushnumber(L, screen_page);
        lua_settable(L, -3);

        lua_pushstring(L, "screen_y");
        lua_pushnumber(L, screen_y);
        lua_settable(L, -3);

        lua_pushstring(L, "page");
        lua_pushnumber(L, item->getPage()+1);
        lua_settable(L, -3);

        lua_pushstring(L, "xpointer");
        lua_pushstring(L, UnicodeToLocal(item->getPath()).c_str());
        lua_settable(L, -3);

        lua_pushstring(L, "doc_y");
        lua_pushnumber(L, item->getDocY());
        lua_settable(L, -3);

        lua_pushstring(L, "label");
        lua_pushstring(L, UnicodeToLocal(item->getLabel()).c_str());
        lua_settable(L, -3);

        // add item to returned table
        lua_settable(L, -3);
    }
    return 1;
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

static int setHeaderProgressMarks(lua_State *L) {
        CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
        int pages = luaL_checkint(L, 2);

        // Get a reference to LvDocView internal m_section_bounds that
        // we will update. We need to add ticks for 0 and 10000.
        // Values are in 0.01 % (so 10000 = 100%)
        LVArray<int> & m_section_bounds = doc->text_view->getSectionBounds(true);
        m_section_bounds.clear();
        m_section_bounds.add(0);
        if ( lua_istable(L, 3) ) {
            int len = lua_objlen(L, 3);
            for (int i = 1; i <= len; i++) {
                lua_pushinteger(L, i);
                lua_gettable(L, 3);
                if ( lua_isnumber(L, -1) ) {
                    int n = lua_tointeger(L, -1);
                    m_section_bounds.add( 10000 * (n-1) / pages);
                }
            }
        }
        m_section_bounds.add(10000);

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

	doc->text_view->goToPage(pageno-1, true, false); // regulateTwoPages=false
	// In 2-pages mode, we will ensure from frontend the first page displayed
	// is an even one: we don't need crengine to ensure that.

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

	doc->text_view->SetPos(pos, true, true);
	// savePos=true is the default, but we use allowScrollAfterEnd=true
	// to allow frontend code to control how much we can scroll after end
	// by adjusting pos

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

static int setBackgroundColor(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const int bgcolor = (int)luaL_optint(L, 2, 0xFFFFFF); // default to white if not provided

	doc->text_view->setBackgroundColor(bgcolor);
	return 0;
}

static int setBackgroundImage(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	if (lua_isstring(L, 2)) {
		const char *img_path = luaL_checkstring(L, 2);
		LVStreamRef stream = LVOpenFileStream(img_path, LVOM_READ);
		if ( !stream.isNull() ) {
			LVImageSourceRef img = LVCreateStreamImageSource(stream);
			if ( !img.isNull() ) {
				doc->text_view->setBackgroundImage(img, true); // tiled=true
			}
		}
	}
	else { // if not a string (nil, false...), remove background image
		LVImageSourceRef img;
		doc->text_view->setBackgroundImage(img);
	}
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
				31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
				50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68,
				69, 70, 71, 72, 78, 84, 90, 110, 130, 150, 170, 200, 230, 260, 300, 340};
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

static int getHeaderHeight(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");

	lua_pushinteger(L, doc->text_view->getPageHeaderHeight());
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

static int getTextFromXPointers(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const char* pos0 = luaL_checkstring(L, 2);
	const char* pos1 = luaL_checkstring(L, 3);

	ldomDocument *dv = doc->dom_doc;

	ldomXPointer startp = dv->createXPointer(lString16(pos0));
	ldomXPointer endp = dv->createXPointer(lString16(pos1));
	if (!startp.isNull() && !endp.isNull()) {
		ldomXRange r(startp, endp);
		if (r.getStart().isNull() || r.getEnd().isNull())
			return 0;
		r.sort();

		if (r.getStart() == r.getEnd()) { // for single CJK character
			ldomNode * node = r.getStart().getNode();
			lString16 text = node->getText();
			int textLen = text.length();
			int offset = r.getEnd().getOffset();
			if (offset < textLen - 1)
				r.getEnd().setOffset(offset + 1);
		}

		lString16 selText = r.getRangeText( '\n', 8192 );
		lua_pushstring(L, UnicodeToLocal(selText).c_str());
        return 1;
    }
    return 0;
}

static int getTextFromPositions(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int x0 = luaL_checkint(L, 2);
	int y0 = luaL_checkint(L, 3);
	int x1 = luaL_checkint(L, 4);
	int y1 = luaL_checkint(L, 5);
	// Default to have crengine do native highlight of selected text
	// (segmented by line, for better results)
	bool drawSelection = true;
	if (lua_isboolean(L, 6)) {
		drawSelection = lua_toboolean(L, 6);
	}
	bool drawSegmentedSelection = true;
	if (lua_isboolean(L, 7)) {
		drawSegmentedSelection = lua_toboolean(L, 7);
	}

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

		// When panning, only extend to include the whole word when we are
		// actually holding inside a word. This allows selecting punctuation,
		// quotes or parens at start or end of selection to have them
		// included in the highlight.
		bool not_panning = r.getStart() == r.getEnd();
		if ( (not_panning || r.getStart().isVisibleWordChar()) && !r.getStart().isVisibleWordStart())
			r.getStart().prevVisibleWordStart();
		if ( (not_panning || r.getEnd().isVisibleWordChar()) && !r.getEnd().isVisibleWordEnd())
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

		int rangeFlags = 0;
		if (drawSelection) // have crengine do native highlight of selection
			rangeFlags = drawSegmentedSelection ? 0x11 : 0x01;
		r.setFlags(rangeFlags);
		tv->selectRange(r);

		/* We don't need these:
		int page = tv->getBookmarkPage(startp);
		int pages = tv->getPageCount();
		lString16 titleText;
		lString16 posText;
		tv->getBookmarkPosText(startp, titleText, posText);
		*/
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
		/* We don't need these:
		lua_pushstring(L, "title");
		lua_pushstring(L, UnicodeToLocal(titleText).c_str());
		lua_settable(L, -3);
		lua_pushstring(L, "context");
		lua_pushstring(L, UnicodeToLocal(posText).c_str());
		lua_settable(L, -3);
		lua_pushstring(L, "percent");
		lua_pushnumber(L, 1.0*page/(pages-1));
		lua_settable(L, -3);
		*/
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
    bool topInPage = false;
    bool bottomInPage = false;
    if (tv->docToWindowPoint(topLeft)) {
        rc.setTopLeft(topLeft);
        topInPage = true;
    }
    if (tv->docToWindowPoint(bottomRight, true)) {
        // isRectBottom=true: allow this bottom point (outside of the
        // rect content) to be considered in this page, if it is
        // actually the top of the next page.
        rc.setBottomRight(bottomRight);
        bottomInPage = true;
    }
    if (topInPage && bottomInPage) {
        return true;
    }
    else if (bottomInPage && !topInPage) {
        // Rect's bottom is in page, but not its top:
        // get top truncated/clipped to current page top
        topLeft = rc.topLeft();
        if (tv->docToWindowPoint(topLeft, false, true)) {
            rc.setTopLeft(topLeft);
            return true;
        }
    }
    else if (topInPage && !bottomInPage) {
        // Rect's top is in page, but not its bottom:
        // get bottom truncated/clipped to current page bottom
        bottomRight = rc.bottomRight();
        if (tv->docToWindowPoint(bottomRight, true, true)) {
            rc.setBottomRight(bottomRight);
            return true;
        }
    }
    // Neither top or bottom of rect in page
    return false;
}

// Push to the Lua stack the multiple segments (rectangle for each text line)
// that a ldomXRange spans on the page.
// Each segment is pushed as a table {x0=, y0=, x1=, y1=}.
// The Lua stack must be prepared as a table to receive them.
void lua_pushSegmentsFromRange(lua_State *L, CreDocument *doc, ldomXRange *range) {
    LVDocView *tv = doc->text_view;
    LVArray<lvRect> rects;
    range->getSegmentRects(rects);
    int lcount = 1;
    for (int i=0; i<rects.length(); i++) {
        lvRect r = rects[i];
        if (! r.isEmpty()) {
            if (docToWindowRect(tv, r)) { // it is in current showing page
                lua_newtable(L); // new segment
                lua_pushLineRect(L, r.left, r.top, r.right, r.bottom, lcount++);
            }
        }
    }
}

static int compareXPointers(lua_State *L){
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char* xp1 = luaL_checkstring(L, 2);
    const char* xp2 = luaL_checkstring(L, 3);
    ldomXPointerEx nodep1 = doc->dom_doc->createXPointer(lString16(xp1));
    ldomXPointerEx nodep2 = doc->dom_doc->createXPointer(lString16(xp2));
    if (nodep1.isNull() || nodep2.isNull())
        return 0;
    // Return 1 if pointers are ordered (if xp2 is after xp1), -1 if not, 0 if same
    lua_pushinteger(L, nodep2.compare(nodep1));
    return 1;
}

static int getNextVisibleWordStart(lua_State *L){
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char* xp = luaL_checkstring(L, 2);
    ldomXPointerEx nodep = doc->dom_doc->createXPointer(lString16(xp));
    if (nodep.isNull())
        return 0;
    if (nodep.nextVisibleWordStart()) {
        lua_pushstring(L, UnicodeToLocal(nodep.toString()).c_str());
        return 1;
    }
    return 0;
}

static int getNextVisibleWordEnd(lua_State *L){
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char* xp = luaL_checkstring(L, 2);
    ldomXPointerEx nodep = doc->dom_doc->createXPointer(lString16(xp));
    if (nodep.isNull())
        return 0;
    if (nodep.nextVisibleWordEnd()) {
        lua_pushstring(L, UnicodeToLocal(nodep.toString()).c_str());
        return 1;
    }
    return 0;
}

static int getPrevVisibleWordStart(lua_State *L){
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char* xp = luaL_checkstring(L, 2);
    ldomXPointerEx nodep = doc->dom_doc->createXPointer(lString16(xp));
    if (nodep.isNull())
        return 0;
    if (nodep.prevVisibleWordStart()) {
        lua_pushstring(L, UnicodeToLocal(nodep.toString()).c_str());
        return 1;
    }
    return 0;
}


static int getPrevVisibleWordEnd(lua_State *L){
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char* xp = luaL_checkstring(L, 2);
    ldomXPointerEx nodep = doc->dom_doc->createXPointer(lString16(xp));
    if (nodep.isNull())
        return 0;
    if (nodep.prevVisibleWordEnd()) {
        lua_pushstring(L, UnicodeToLocal(nodep.toString()).c_str());
        return 1;
    }
    return 0;
}

static int getNextVisibleChar(lua_State *L){
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char* xp = luaL_checkstring(L, 2);
    ldomXPointerEx nodep = doc->dom_doc->createXPointer(lString16(xp));
    if (nodep.isNull())
        return 0;
    if (nodep.nextVisibleChar()) {
        lua_pushstring(L, UnicodeToLocal(nodep.toString()).c_str());
        return 1;
    }
    return 0;
}

static int getPrevVisibleChar(lua_State *L){
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char* xp = luaL_checkstring(L, 2);
    ldomXPointerEx nodep = doc->dom_doc->createXPointer(lString16(xp));
    if (nodep.isNull())
        return 0;
    if (nodep.prevVisibleChar()) {
        lua_pushstring(L, UnicodeToLocal(nodep.toString()).c_str());
        return 1;
    }
    return 0;
}

static int getWordBoxesFromPositions(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	const char* pos0 = luaL_checkstring(L, 2);
	const char* pos1 = luaL_checkstring(L, 3);
	bool getSegments = false; // by default, use concatenated boxes from each word
	if (lua_isboolean(L, 4)) {
		// Use full line segments instead of concatenated words boxes.
		// This will gather punctuations at start and end of intermediate
		// lines, which makes out a nicer display of text selection.
		getSegments = lua_toboolean(L, 4);
	}

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

		// Segments are not limited to word boundaries, so they
		// work with precise xpointers. Do that before the
		// VisibleWord() stuff below, so that it works if/when
		// we make text selection work outside word boundaries
		// (to select following puncutations, etc...)
		if (getSegments) {
			lua_pushSegmentsFromRange(L, doc, &r);
			return 1;
		}

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
				// int y = -1; // no more used
				for (int j=word.getStart(); j < word.getEnd(); j++) {
					if (ldomXPointer(word.getNode(), j).getRectEx(charRect)) {
						if (!docToWindowRect(tv, charRect)) continue;
						// charRect is now the width of each individual char.
						// Previously, ldomXPointer::getRectEx() was returning its
						// own word->width, so getting it only from the first call
						// looked like it was fine. But our "word"s come from
						// lStr_findWordBounds(), unlike the ones ldomXPointer::getRectEx()
						// uses that come from lvtextfm.cpp which splits on spaces only.
						// We would then get shifted highlights with some texts
						// (e.g. with french text "l'empereur" word->t.start starts
						// at 'l' while here our word may start at 'e'mpereur)
						// was:
						//   if (y == -1) y = charRect.top;
						//   if (j != word.getStart() && y == charRect.top) continue;
						//   y = charRect.top;
						// Keep extending lineRect with each individual charRect we met.
						// When charRect.left < lastx, we are on next line and lineRect
						// is ready to be pushed.
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

static int getDocumentFileContent(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char* internalFilePath = luaL_checkstring(L, 2);

    LVStreamRef stream = doc->text_view->getDocumentFileStream(lString16(internalFilePath));
    if (!stream.isNull()) {
        unsigned size = stream->GetSize();
        lvsize_t read_size = 0;
        void *buffer = (void *)malloc(size);
        if (buffer != NULL) {
            stream->Read(buffer, size, &read_size);
            if (read_size == size) {
                // (We can push a string containing NULL bytes with lua_pushlstring,
                // so this function works with binary files like images.)
                lua_pushlstring(L, (const char*)buffer, size);
                free(buffer);
                return 1;
            }
            free(buffer);
        }
    }
    return 0;
}

static int getTextFromXPointer(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char* xp = luaL_checkstring(L, 2);

    ldomXPointer nodep = doc->dom_doc->createXPointer(lString16(xp));
    if (nodep.isNull())
        return 0;
    ldomNode * node = nodep.getNode();
    if (node->isNull())
        return 0;
    lString8 text = node->getText8();
    lua_pushstring(L, text.c_str());
    return 1;
}

static int getHTMLFromXPointer(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char* xp = luaL_checkstring(L, 2);
    int wflags = (int)luaL_optint(L, 3, 0);
    bool fromParentFinalNode = false;
    if (lua_isboolean(L, 4))
        fromParentFinalNode = lua_toboolean(L, 4);

    ldomXPointer nodep = doc->dom_doc->createXPointer(lString16(xp));
    if (nodep.isNull())
        return 0;
    ldomNode * node = nodep.getNode();
    if (node->isNull())
        return 0;
    if (fromParentFinalNode) {
        // get the first parent that is rendered final, which is probably
        // what we want if we are displaying footnotes
        ldomNode * finalNode = nodep.getFinalNode();
        if ( finalNode && !finalNode->isNull() )
            node = finalNode;
    }
    nodep = ldomXPointer(node, 0); // reset offset to 0, to get the full text of text nodes
    lString16Collection cssFiles;
    lString8 html = nodep.getHtml(cssFiles, wflags);
    lua_pushstring(L, html.c_str());
    lua_newtable(L);
    for (int i = 0; i < cssFiles.length(); i++) {
        lua_pushnumber(L, i+1);
        lua_pushstring(L, UnicodeToLocal(cssFiles[i]).c_str());
        lua_settable(L, -3);
    }
    return 2;
}

static int getHTMLFromXPointers(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char* xp0 = luaL_checkstring(L, 2);
    const char* xp1 = luaL_checkstring(L, 3);
    int wflags = (int)luaL_optint(L, 4, 0);
    bool fromRootNode = false;
    if (lua_isboolean(L, 5))
        fromRootNode = lua_toboolean(L, 5);

    ldomXPointer startp = doc->dom_doc->createXPointer(lString16(xp0));
    ldomXPointer endp = doc->dom_doc->createXPointer(lString16(xp1));
    if (startp.isNull() || endp.isNull())
        return 0;
    ldomXRange r(startp, endp);
    if (r.getStart().isNull() || r.getEnd().isNull())
        return 0;
    lString16Collection cssFiles;
    lString8 html = r.getHtml(cssFiles, wflags, fromRootNode);
    lua_pushstring(L, html.c_str());
    lua_newtable(L);
    for (int i = 0; i < cssFiles.length(); i++) {
        lua_pushnumber(L, i+1);
        lua_pushstring(L, UnicodeToLocal(cssFiles[i]).c_str());
        lua_settable(L, -3);
    }
    return 2;
}

static int getPageLinks(lua_State *L) {
	CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
	int internalLinksOnly = false;
	if (lua_isboolean(L, 2)) {
		internalLinksOnly = lua_toboolean(L, 2);
	}

	lua_newtable(L); // all links

	ldomXRangeList links;
	ldomXRangeList & sel = doc->text_view->getDocument()->getSelections();

	doc->text_view->getCurrentPageLinks( links );
	int linkCount = links.length();
	if ( linkCount ) {
		// sel.clear();
		lvRect margin = doc->text_view->getPageMargins();
		int x_offset = margin.left;
		int y_offset = doc->text_view->GetPos() - doc->text_view->getPageHeaderHeight() - margin.top;
		int linkNum = 1;
		for ( int i=0; i<linkCount; i++ ) {
			ldomXPointer a_xpointer;
			lString16 link = links[i]->getHRef(a_xpointer);
			lString8 link8 = UnicodeToLocal( link );
			bool isInternal = link8[0] == '#';

			if ( internalLinksOnly && !isInternal )
				continue;

			ldomXRange currSel;
			currSel = *links[i];

			lvPoint start_pt ( currSel.getStart().toPoint() );
			lvPoint end_pt ( currSel.getEnd().toPoint() );

			#if DEBUG_CRENGINE
				lString16 txt = links[i]->getRangeText();
				lString8 txt8 = UnicodeToLocal( txt );
				CRLog::debug("# link %d start %d %d end %d %d '%s' %s\n", i,
				start_pt.x, start_pt.y, end_pt.x, end_pt.y,
				txt8.c_str(), link8.c_str());
			#endif

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
			if ( isInternal ) {
				lua_pushstring(L, "section");
				lua_pushstring(L, link_to);
				lua_settable(L, -3);
			} else {
				lua_pushstring(L, "uri");
				lua_pushstring(L, link_to);
				lua_settable(L, -3);
			}

			// Add segments rects
			ldomXRange *linkRange = new ldomXRange(*links[i]);
			lua_pushstring(L, "segments");
			lua_newtable(L); // all segments
			lua_pushSegmentsFromRange(L, doc, linkRange);
			lua_settable(L, -3); // adds "segments" = table

			lua_rawseti(L, -2, linkNum++);

			// If we'd need to visually see them when debugging:
			// sel.add( new ldomXRange(*links[i]) );
		}
		// If we'd need to visually see them when debugging:
		// doc->text_view->updateSelections();
	}

	return 1;
}

// Internal function that just returns true or false as soon as detection is decided.
// Used by the real isLinkToFootnote(lua_State *L) that will push that bool to the Lua stack
static bool _isLinkToFootnote(CreDocument *doc, const lString16 source_xpointer, const lString16 target_xpointer,
            const int flags, const int maxTextSize, lString16 &reason,
            lString16 &extendedStopReason, ldomXRange &extendedRange)
{
    ldomDocument *dv = doc->dom_doc;
    const ldomXPointerEx sourceXP = ldomXPointerEx(doc->dom_doc->createXPointer(source_xpointer));
    const ldomXPointerEx targetXP = ldomXPointerEx(doc->dom_doc->createXPointer(target_xpointer));
    ldomNode *sourceNode = sourceXP.getNode();
    ldomNode *targetNode = targetXP.getNode();
    // target_xpointer might be "#_doc_fragment_0_ References", but we may also need
    // to use its DOM xpath equivalent: /body/DocFragment/body/div/div[5]/span.0
    const lString16 targetXpath = ldomXPointer(targetNode, 0).toString();

    // We return false when it can't be a footnote.
    // We return true when it is surely a footnote, and when
    // there is no need to go further, neither to extend the footnote.
    // We set likelyFootnote=true when it looks like it could be a
    // footnote, and continue checking conditions, and go on to see
    // if extending the target is needed
    reason = "";
    extendedStopReason = "trusted container, no need"; // for when we return true early

    bool likelyFootnote = false;
    if (flags & 0x0001) {
        likelyFootnote = true;
    }

    // For details about detection and flags, see ReaderLink:showAsFootnotePopup()
    // in frontend/apps/reader/modules/readerlink.lua
    bool trusted_source_xpointer = flags & 0x0002;

    // Trust -cr-hint: noteref noteref-ignore footnote footnote-ignore
    if (trusted_source_xpointer) {
        css_style_ref_t sourceNodeStyle = sourceNode->getStyle();
        if ( STYLE_HAS_CR_HINT(sourceNodeStyle, NOTEREF) ) {
            reason = "source has -cr-hint: noteref";
            return true;
        }
        else if ( STYLE_HAS_CR_HINT(sourceNodeStyle, NOTEREF_IGNORE) ) {
            reason = "source has -cr-hint: noteref-ignore";
            return false;
        }
    }
    css_style_ref_t targetNodeStyle = targetNode->getStyle();
    if ( STYLE_HAS_CR_HINT(targetNodeStyle, FOOTNOTE) ) {
        reason = "target has -cr-hint: footnote";
        return true;
    }
    else if ( STYLE_HAS_CR_HINT(targetNodeStyle, FOOTNOTE_IGNORE) ) {
        reason = "target has -cr-hint: footnote-ignore";
        return false;
    }


    if (flags & 0x0004) { // Trust role= and epub:type= attributes
        // About epub:type, see:
        //   http://apex.infogridpacific.com/df/epub-type-epubpackaging8.html
        //   http://www.idpf.org/epub/profiles/edu/structure/
        // Should epub:type="glossterm" epub:type="glossdef" be considered
        // as footnotes?
        // And other like epub:type="chapter" that probably are not footnotes?
        //
        // We also trust that the target is the whole footnote container, and
        // so there is no need to extend it.
        // These attributes value may contain multiple values separated by space
        // Source
        if (trusted_source_xpointer) {
            // epub:type=
            // (Looks like crengine has no support for alternate namesepace prefix
            // set with xmlns:zzz="http://www.idpf.org/2007/ops")
            lString16 type = sourceNode->getAttributeValue("epub", "type");
            if (type.empty()) { // Fallback to any type= or zzz:type=
                type = sourceNode->getAttributeValue("type");
            }
            if (!type.empty()) {
                type.lowercase();
                lString16Collection types;
                types.parse(type, ' ', true);
                for (int i=0; i<types.length(); i++) {
                    lString16 type = types[i];
                    if (type == "noteref") {
                        reason = "source has epub:type=" + type;
                        return true;
                    }
                    if (type == "link") {
                        reason = "source has epub:type=" + type;
                        return false;
                    }
                }
            }
            // role=
            lString16 role = sourceNode->getAttributeValue("role");
            if (!role.empty()) {
                role.lowercase();
                lString16Collection roles;
                roles.parse(role, ' ', true);
                for (int i=0; i<roles.length(); i++) {
                    lString16 role = roles[i];
                    if (role == "doc-noteref") {
                        reason = "source has role=" + role;
                        return true;
                    }
                    if (role == "doc-link") {
                        reason = "source has role=" + role;
                        return false;
                    }
                }
            }
        }
        // Target
        // (Note that calibre first gets the block container of targetNode if
        // targetNode is not a block element, and test these attribute on it.
        // Which seems strange: we should at best test that on both the original
        // targetNode, and its block parent.
        // Let's assume that if a publisher has set epub:type=footnote, it has
        // set it to the correct container, probably a <aside> tag.
        // epub:type=
        lString16 type = targetNode->getAttributeValue("epub", "type");
        if (type.empty()) { // Fallback to any type= or zzz:type=
            type = targetNode->getAttributeValue("type");
        }
        if (!type.empty()) {
            type.lowercase();
            lString16Collection types;
            types.parse(type, ' ', true);
            for (int i=0; i<types.length(); i++) {
                lString16 type = types[i];
                if (type == "note" || type == "footnote" || type == "rearnote" ) {
                    reason = "target has epub:type=" + type;
                    return true;
                }
            }
        }
        // role=
        lString16 role = targetNode->getAttributeValue("role");
        if (!role.empty()) {
            lString16Collection roles;
            roles.parse(role, ' ', true);
            for (int i=0; i<roles.length(); i++) {
                lString16 role = roles[i];
                if (role == "doc-note" || role == "doc-footnote" || role == "doc-rearnote") {
                    reason = "target has role=" + role;
                    return true;
                }
            }
        }
    }

    if (flags & 0x0008) { // Accept classic FB2 footnotes
        // Similar checks as this CSS would do:
        //    body[name="notes"] section,
        //    body[name="comments"] section {
        //        -cr-hint: footnote;
        //    }
        if ( targetNode->getNodeId() == doc->dom_doc->getElementNameIndex("section") ) {
            lUInt16 el_body = doc->dom_doc->getElementNameIndex("body");
            ldomNode * n = targetNode->getParentNode();
            while ( n && !n->isNull() ) {
                if ( n->getNodeId() == el_body ) {
                    lString16 name = n->getAttributeValue("name");
                    if (!name.empty()) {
                        name.lowercase();
                        if (name == "notes") {
                            reason = "target is FB2 footnote (body[name=notes] section)";
                            return true;
                        }
                        if (name == "comments") {
                            reason = "target is FB2 footnote (body[name=comments] section)";
                            return true;
                        }
                    }
                    break;
                }
                n = n->getParentNode();
            }
        }
    }

    if (flags & 0x0010) { // Target must have an anchor #id
        // We should be called only with internal links, so they should
        // all start with "#". But check that anyway.
        if ( target_xpointer[0] != '#' ) {
            reason = "target is not an internal link (not #something)";
            return false;
        }
        // For multiple internal files container like EPUB, internal links
        // may have the form:
        //   "#_doc_fragment_7_ References" when href="content7.html#Reference"
        //   "#_doc_fragment_5" when href="content5.html"
        // The former could be a footnote, but the later is not.
        if ( target_xpointer.pos("_ ") < 0 ) {
            reason = "target is missing an anchor (#someId)";
            return false;
        }
    }

    if (flags & 0x0020) { // Target must come after source in the book
        // We can check that even when not trusted_source_xpointer (the
        // incoherent XPointer seems to always be in the same paragraph
        // as the original one)
        if (sourceXP.compare(targetXP) > 0) {
            reason = "target does not come after source in book";
            return false;
        }
    }

    if (flags & 0x0040) { // Target must not be in the TOC
        // Walk the tree up and down, avoid the need for recursion.
        LVTocItem * item = doc->text_view->getToc();
        if (item->getChildCount() > 0) {
            int nextChildIndex = 0;
            item = item->getChild(nextChildIndex);
            while (true) {
                // Do the item processing only the first time we met a node
                // (nextChildIndex == 0) and not when we get back to it from
                // a child to process next sibling
                if (nextChildIndex == 0) {
                    // printf("%d %d %s %s\n", item->getLevel(), item->getIndex(),
                    //   UnicodeToLocal(item->getPath()).c_str(), UnicodeToLocal(item->getName()).c_str());
                    // TOC entries already had their #someId translated to a DOM xpath
                    if (item->getPath() == targetXpath) {
                        reason = "target also appears in TOC";
                        return false;
                    }
                }
                // Process next child
                if (nextChildIndex < item->getChildCount()) {
                    item = item->getChild(nextChildIndex);
                    nextChildIndex = 0;
                    continue;
                }
                // No more child, get back to parent and have it process our sibling
                nextChildIndex = item->getIndex() + 1;
                item = item->getParent();
                if (!item) // all done and back to root node which has no parent
                    break;
            }
        }
    }

    // Source link must not be empty content, and must not be the only content of
    // its parent final node (this could mean it's a chapter title in an inline ToC)
    if (flags & 0x0100 && trusted_source_xpointer) {
        ldomNode * finalNode = sourceXP.getFinalNode();
        lString16 sourceText = sourceNode->getText();
        if ( sourceText.empty() ) {
            // (Empty links may have already been filtered out.)
            // This will also discard a link containing a single image pointing
            // to a bigger size image (it could also be a small image linking
            // to a footnote, but well...)
            reason = "source has no text content";
            return false;
        }
        if ( finalNode && !finalNode->isNull() ) {
            if ( sourceText == finalNode->getText() ) {
                reason = "source is the only content of its parent block";
                return false;
            }
        }
    }

    // Source may have all content shifted by vertical-align:
    if (flags & 0x0200 && trusted_source_xpointer && !likelyFootnote) {
        // We must see some text, otherwise it could be an image (see above)
        // surrounded by space-only text and elements
        bool seen_non_empty_text = false;
        bool is_only_footnote_likely_vertical_align = true;
        ldomXPointerEx endText = sourceXP; // copy;
        endText.lastInnerTextNode(true);
        // Walk all text nodes till endText
        ldomXPointerEx curText = sourceXP; // copy
        ldomNode * finalNode = sourceXP.getFinalNode();
        while ( curText.nextText() && curText.compare(endText) <= 0 ) {
            // Ignore empty or space-only text nodes
            lString16 nodeText = curText.getText();
            int textLen = nodeText.length();
            if ( textLen == 0 || (textLen == 1 && nodeText[0] == ' ' ) )
                continue;
            seen_non_empty_text = true;
            // vertical-align being non-inherited, we need to check it for
            // all the parents of this text node up to a final node.
            // If any such parent has a vertical align shift, this text node
            // has a vertical align shift (which could be cancelled by another
            // parent vertical-align, but too complicated to check from here).
            // For simplicity, assume any vertical-align shift (so, other
            // than 'baseline' or a 0 length value), even small, may likely
            // be a footnote.
            bool is_vertically_shifted = false;
            ldomNode * parent = curText.getNode()->getParentNode();
            while (parent && !parent->isNull()) {
                css_style_ref_t style = parent->getStyle();
                css_length_t vertical_align = style->vertical_align;
                if (vertical_align.type == css_val_unspecified) {
                    css_vertical_align_t va = (css_vertical_align_t)vertical_align.value;
                    if (va != css_va_inherit && va != css_va_baseline) {
                        is_vertically_shifted = true;
                        break;
                    }
                }
                else {
                    // We would prefer to check if shift is > 20%, but that's
                    // not easy from here
                    if (vertical_align.value != 0) {
                        is_vertically_shifted = true;
                        break;
                    }
                }
                if (parent == finalNode)
                    break;
                parent = parent->getParentNode();
            }
            if ( !is_vertically_shifted ) {
                is_only_footnote_likely_vertical_align = false;
                break;
            }
        }
        if ( seen_non_empty_text && is_only_footnote_likely_vertical_align ) {
            if ( !reason.empty() ) reason += "; ";
            reason += "source has all content shifted by vertical-align";
            likelyFootnote = true;
        }
        else {
            // Also check if any of the 2 first parents are <sup> or <sub>
            // (which may have been tweaked with CSS and not have the expected
            // vertical-align:)
            lUInt16 el_sup = doc->dom_doc->getElementNameIndex("sup");
            lUInt16 el_sub = doc->dom_doc->getElementNameIndex("sub");
            ldomNode * n = sourceNode->getParentNode();
            for ( int i=0; i<2; i++ ) {
                if ( !n || n->isNull() )
                    break;
                if ( n->getNodeId() == el_sup || n->getNodeId() == el_sub ) {
                    if ( !reason.empty() ) reason += "; ";
                    reason += "source is child or grandchild of <sup> or <sub>";
                    likelyFootnote = true;
                    break;
                }
                n = n->getParentNode();
            }
            if ( !likelyFootnote ) {
                // Also check if all direct child nodes are <sup> or <sub>
                // (which may have been tweaked with CSS and not have the expected
                // vertical-align:)
                bool hasOnlySupSub = false;
                for ( int i=0; i<sourceNode->getChildCount(); i++ ) {
                    n = sourceNode->getChildNode(i);
                    if ( n->isText() ) {
                        lString16 nodeText = n->getText();
                        int textLen = nodeText.length();
                        if ( textLen == 0 || (textLen == 1 && nodeText[0] == ' ' ) ) {
                            continue;
                        }
                        else { // non empty text node, test failed
                            hasOnlySupSub = false;
                            break;
                        }
                    }
                    else {
                        if ( n->getNodeId() == el_sup || n->getNodeId() == el_sub ) {
                            hasOnlySupSub = true;
                        }
                        else { // other tag
                            hasOnlySupSub = false;
                            break;
                        }
                    }
                }
                if ( hasOnlySupSub ) {
                    if ( !reason.empty() ) reason += "; ";
                    reason += "source has only <sup> or <sub> children";
                    likelyFootnote = true;
                }
            }
        }
    }

    // Source node text (punctuation stripped) is only numbers (3 digits max,
    // to avoid catching years ... but only years>1000)
    // Source node text (punctuation stripped) is 1 to 2 letters, with 0 to 2
    // numbers (a, z, ab, 1a, B2) - or 1 to 10 roman numerals
    if ( (flags & 0x0400 || flags & 0x0800) && trusted_source_xpointer && !likelyFootnote) {
        lString16 sourceText = sourceNode->getText();
        int nbDigits = 0;
        int nbAlpha = 0;
        int nbOthers = 0;
        int nbRomans = 0;
        for (int i=0 ; i<sourceText.length(); i++) {
            if ( !lStr_isWordSeparator(sourceText[i]) ) { // ignore space, punctuations...
                int props = lGetCharProps(sourceText[i]);
                if (props & CH_PROP_DIGIT)
                    nbDigits += 1;
                else if (props & CH_PROP_ALPHA) {
                    nbAlpha += 1;
                    // also check for roman numerals (i v x l c d m)
                    lChar16 c = sourceText[i];
                    if (c == 'i' || c == 'v' || c == 'x' || c == 'l' || c == 'c' || c == 'd' || c == 'm' ||
                        c == 'I' || c == 'V' || c == 'X' || c == 'L' || c == 'C' || c == 'D' || c == 'M' ) {
                            nbRomans += 1;
                    }
                }
                else
                    nbOthers += 1; // CJK, other alphabets...
            }
        }
        if (flags & 0x0400 && nbDigits >= 1 && nbDigits <= 3 && nbAlpha==0 && nbOthers==0) {
            if (!reason.empty()) reason += "; ";
            reason += "source text is only 1 to 3 digits";
            likelyFootnote = true;
        }
        if (flags & 0x0800 && nbAlpha >= 1 && nbAlpha <= 2 && nbDigits >= 0 && nbDigits <= 2 && nbOthers==0) {
            // (should we only allow lowercase alpha?)
            if (!reason.empty()) reason += "; ";
            reason += "source text is 1 to 2 letters with 0 to 2 digits";
            likelyFootnote = true;
        }
        else if (flags & 0x0800 && nbRomans >= 1 && nbRomans <= 10 && nbRomans == nbAlpha && nbDigits==0 && nbOthers==0) {
            if (!reason.empty()) reason += "; ";
            reason += "source text is 1 to 10 roman numerals";
            likelyFootnote = true;
        }
    }

    // Target must not contain, or be contained in, H1..H6
    if (flags & 0x1000) {
        // We expect h1..h6 to stay consecutive and ascending in crengine/include/fb2def.h
        lUInt16 el_h1 = doc->dom_doc->getElementNameIndex("h1");
        lUInt16 el_h6 = doc->dom_doc->getElementNameIndex("h6");
        // Check parents
        ldomNode * n = targetNode;
        while ( n && !n->isNull() ) {
            // printf("< %s\n", UnicodeToLocal(ldomXPointerEx(n, 0).toString()).c_str());
            if ( n->getNodeId() >= el_h1 && n->getNodeId() <= el_h6 ) {
                reason = "target is, or is inside, a <h1>...<h6>";
                return false;
            }
            n = n->getParentNode();
        }
        // Check all descendant elements
        ldomXPointerEx curXP = targetXP; // copy
        ldomXPointerEx endXP = targetXP; // copy
        endXP.lastInnerNode();
        while (!curXP.isNull() && curXP.compare(endXP) <= 0) {
            // printf("> %s\n", UnicodeToLocal(curXP.toString()).c_str());
            lUInt16 id = curXP.getNode()->getNodeId();
            if ( id >= el_h1 && id <= el_h6 ) {
                reason = "target contains a <h1>...<h6>";
                return false;
            }
            if (!curXP.nextElement())
                break;
        }
        // It may also happen with a link to a chapter that the target has
        // a H1..H6 as its next sibling. But catching that may lead to
        // missing the last footnote in a chapter on other books.

    }

    // Try to extend footnote
    if (flags & 0x4000) {
        // With not well formatted books, the target node might just be
        // the first line or paragraph among multiple paragraphs that
        // make up this footnote complete text.
        // We try to gather as much paragraphs (final nodes) after the
        // linked one, and stop when we meet:
        //   - a new <DocFragment> or <body>, or any of <h1>...<h6>
        //   - (before) a node with page-break-before: always/left/right
        //   - (after) a node with page-break-after: always/left/right
        //   - a node with an id= attribute, which may be the start of
        //     another footnote (calibre additionally verifies that
        //     the new id= found is actually a referenced target, that
        //     there is somewhere in the book a <a href="#thatId"> ;
        //     we can't do that quickly, so we don't).
        //
        // We start looking at elements after targetXP "final" parent.
        bool do_extend = true;
        ldomXPointerEx extendedStart;
        ldomXPointerEx curPos;
        ldomNode * firstFinalNode = targetXP.getFinalNode();
        if (firstFinalNode && !firstFinalNode->isNull()) {
            // The target is an inline element, and we got its containing
            // final block.
            extendedStart = ldomXPointerEx(firstFinalNode, 0);
            curPos = extendedStart; // copy
            // We can't just go looking at next final nodes, there
            // may be block containers that have page-break styles
            // or an ID= and are not part of any final node.
            // We need to start inspecting from the node just after
            // this firstFinalNode.
            do_extend = curPos.nextOuterElement();
            // if no next elements, this was the last final node
            // in the book, so nothing to find further
        }
        else {
            // The target is an empty element not rendered (so not part
            // of any final node), and there is a final node after it.
            // Or it is an outer block that may contain a final node, in
            // which case we assume it's a proper container of 1 or more
            // final nodes that fully represent the footnote content,
            // and we won't extend it further.
            curPos = targetXP;
            ldomXPointerEx endPos = curPos; // copy
            while ( endPos.lastChild() ) {} // get last grand children
            bool has_final_child = false;
            while ( curPos.nextElement() && curPos.compare(endPos) <= 0 ) {
                if ( curPos.isFinalNode() ) {
                    has_final_child = true;
                    extendedStopReason = "contains 1 or more final nodes, trusting container";
                    do_extend = false;
                    // We could go on extending from this final node if we
                    // decide to not trust such containers to be proper.
                    // firstFinalNode = curNode;
                    break;
                }
            }
            if (!has_final_child) {
                // We will not inspect the first final node we see after
                // our target node: it's probably the footnote content
                extendedStart = targetXP; // start range from original targer anyway
                curPos = targetXP;
                do_extend = false;
                if ( curPos.nextOuterElement() ) { // skip the node we just inspected
                    do {
                        if ( curPos.isFinalNode() ) {
                            // This one is our first final node, step to the
                            // next one if there is one to go on with
                            do_extend = curPos.nextOuterElement();
                            break;
                        }
                    }
                    while ( curPos.nextElement() );
                }
            }
        }
        if (do_extend) {
            // Check all coming elements until we meet one that can't
            // be part of current footnote: its final container too
            // can't be part of current footnote
            lUInt16 el_DocFragment = doc->dom_doc->getElementNameIndex("DocFragment");
            lUInt16 el_body = doc->dom_doc->getElementNameIndex("body");
            lUInt16 el_h1 = doc->dom_doc->getElementNameIndex("h1");
            lUInt16 el_h6 = doc->dom_doc->getElementNameIndex("h6");
            lUInt16 el_a = doc->dom_doc->getElementNameIndex("a");
            ldomNode * goodFinalNode = NULL;
            ldomNode * curFinalNode = NULL;
            ldomXPointerEx notAfter;
            lString16 extStopReason;
            extStopReason = "End of document met";
            // printf("[start: %s\n", UnicodeToLocal(curPos.toString()).c_str());
            while (true) {
                ldomNode * newFinalNode = curPos.getFinalNode();
                if (newFinalNode != curFinalNode) {
                    // New final node. We didn't stop in the previous finalNode,
                    // so it is fully usable to extend our footnote to include it.
                    if (curFinalNode && !curFinalNode->isNull())
                        goodFinalNode = curFinalNode;
                    curFinalNode = newFinalNode;
                    // printf("new final node\n");
                }
                ldomNode * node = curPos.getNode();
                lUInt16 nodeId = node->getNodeId();
                // We should stop on specific occasions:
                // A footnote can not span <body> or <DocFragment>
                if ( nodeId == el_body || nodeId == el_DocFragment ) {
                    extStopReason = "end of document fragment met";
                    break;
                }
                // A footnote can not span headings
                if ( nodeId >= el_h1 && nodeId <= el_h6 ) {
                    extStopReason = "H1..H6 met";
                    break;
                }
                // A footnote can not span page breaks (set with CSS properties)
                css_style_ref_t style = node->getStyle();
                css_page_break_t pb_before = style->page_break_before;
                css_page_break_t pb_after = style->page_break_after;
                if ( pb_before == css_pb_always || pb_before == css_pb_left || pb_before == css_pb_right ) {
                    extStopReason = "page-break-before met";
                    break;
                }
                if ( pb_after == css_pb_always || pb_after == css_pb_left || pb_after == css_pb_right ) {
                    ldomXPointerEx tmpPos = curPos;
                    // printf("[pbafter at %s\n", UnicodeToLocal(notAfter.toString()).c_str());
                    if ( tmpPos.nextOuterElement() ) {
                        notAfter = tmpPos;
                        // printf("[notAfter %s\n", UnicodeToLocal(notAfter.toString()).c_str());
                    }
                }
                // When we meet another final block containing a node with an ID= attribute,
                // it's probably another footnote.
                // (In the first final block, it's possible to have multiple nodes with
                // different ID, which could mean there are multiple terms or synonyms...)
                lString16 id = node->getAttributeValue("id");
                if ( !id.empty() ) {
                    // printf("id=%s\n", UnicodeToLocal(id).c_str());
                    extStopReason = "node with 'id=' attr met";
                    break;
                }
                else if ( nodeId == el_a ) {
                    // With <a>, crengine may use name= as its id=, so do as well.
                    lString16 name = node->getAttributeValue("name");
                    if ( !name.empty() ) {
                        extStopReason = "node A with 'name=' attr met";
                        break;
                    }
                }
                // Done checking
                if ( !curPos.nextElement() ) {
                    extStopReason = "end of document met";
                    break;
                }
                // printf("[...: %s\n", UnicodeToLocal(curPos.toString()).c_str());
                if ( !notAfter.isNull() && curPos.compare(notAfter) >= 0 ) {
                    extStopReason = "page-break-after met";
                    if ( curFinalNode && !curFinalNode->isNull() )
                        goodFinalNode = curFinalNode;
                    break;
                }
            } // end of while (true)
            extendedStopReason = extStopReason;
            if ( goodFinalNode && !goodFinalNode->isNull() ) {
                // printf("GOOD final node\n");
                ldomXPointerEx extendedEnd = ldomXPointerEx(goodFinalNode, 0);
                extendedEnd.lastInnerNode(true); // We may miss a trailing image
                extendedRange = ldomXRange(extendedStart, extendedEnd);
            }
            // If we'd get multiple <LI> in multiple final nodes, we'll
            // be requesting the HTML from the common parent, and if it
            // is a <OL>, we'll start numbering the <LI> from "1", which
            // may not be the original numbering in the document.
            // Howerver, this should not happen with documents using <LI id=...>
            // as the container for each footnote (like Wikipedia EPUBs), as
            // the ID= check will then prevent us from including multiple <LI>
            // in our extended range: the root node will be the <LI>, that we
            // will mask with CSS "body > li { list-style-type: none; }".
        }
    }

    // Target text must be less than the provided maxTextSize
    if (flags & 0x8000) {
        int size = 0;
        ldomXPointerEx curText;
        ldomXPointerEx endText;
        if ( !extendedRange.isNull() ) {
            curText = extendedRange.getStart();
            endText = extendedRange.getEnd();
        }
        else {
            ldomNode * finalNode = targetXP.getFinalNode();
            if ( finalNode && !finalNode->isNull() )
                curText = ldomXPointerEx(finalNode, 0);
            else
                curText = targetXP;
            endText = curText; // copy
            endText.lastInnerTextNode();
        }
        // Walk all text nodes till endText
        while (curText.nextText() && curText.compare(endText) <= 0) {
            lString16 nodeText = curText.getText();
            size += nodeText.length();
            if (size > maxTextSize) {
                reason = "target text is too large";
                return false;
                // If we checked the extended one, should we try again
                // on the non-extended one?
            }
        }
        // printf("target size is %d\n", size);
    }

    if ( likelyFootnote ) {
        if ( reason.empty() ) {
            reason = "no decision, default to be a footnote";
        }
        return true;
    }

    if ( !reason.empty() ) reason += "; ";
    reason += "no decision made, default to not a footnote";
    return false;
}

static int isLinkToFootnote(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char* source_xpointer = luaL_checkstring(L, 2);
    const char* target_xpointer = luaL_checkstring(L, 3);
    const int flags = (int)luaL_checkint(L, 4);
    const int max_text_size = (int)luaL_optint(L, 5, 10000); // default: 10 000 chars

    lString16 reason;
    lString16 extendedStopReason;
    ldomXRange extendedRange;
    bool isFootnote = _isLinkToFootnote(doc, lString16(source_xpointer), lString16(target_xpointer),
            flags, max_text_size, reason, extendedStopReason, extendedRange);
    int stackLength = 2;
    lua_pushboolean(L, isFootnote);
    lua_pushstring(L, UnicodeToLocal(reason).c_str());
    if (!extendedStopReason.empty()) {
        stackLength += 1;
        lua_pushstring(L, UnicodeToLocal(extendedStopReason).c_str());
    }
    if (!extendedRange.isNull()) {
        stackLength += 2;
        lua_pushstring(L, UnicodeToLocal(extendedRange.getStart().toString()).c_str());
        lua_pushstring(L, UnicodeToLocal(extendedRange.getEnd().toString()).c_str());
    }
    return stackLength;
}

static int highlightXPointer(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    ldomXRangeList & sel = doc->text_view->getDocument()->getSelections();

    if (lua_isstring(L, 2)) { // if xpointer provided, highlight it
        const char* xp = luaL_checkstring(L, 2);
        ldomXPointer nodep = doc->dom_doc->createXPointer(lString16(xp));
        if (nodep.isNull())
            return 0;
        ldomNode * node = nodep.getNode();
        if (node->isNull())
            return 0;
        ldomXRange * fullNodeRange = new ldomXRange(node, true);
        fullNodeRange->setFlags(0x11); // draw segmented adjusted selection
        sel.add( fullNodeRange ); // highlight it
        lua_pushboolean(L, true);
        return 1;
    }
    // if no xpointer provided, clear all highlights
    sel.clear();
    lua_pushboolean(L, true);
    return 1;
}

static int getNormalizedXPointer(lua_State *L) {
    CreDocument *doc = (CreDocument*) luaL_checkudata(L, 1, "credocument");
    const char* xp = luaL_checkstring(L, 2);
    ldomXPointer nodep = doc->dom_doc->createXPointer(lString16(xp));
        // When gDOMVersionRequested >= DOM_VERSION_WITH_NORMALIZED_XPOINTERS,
        // it will use internally createXPointerV2(), otherwise createXPointerV1().

    if ( nodep.isNull() ) {
        // XPointer not found in document
        lua_pushboolean(L, false);
    }
    else {
        // Force the use of toStrinV2() to get a normalized xpointer
        lua_pushstring(L, UnicodeToLocal(nodep.toStringV2()).c_str());
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
	bool invert_images = false; // set to true when in night mode
	if (lua_isboolean(L, 4)) {
		invert_images = lua_toboolean(L, 4);
	}
	bool smooth_scaling = false; // set to true when smooth image scaling is enabled
	if (lua_isboolean(L, 5)) {
		smooth_scaling = lua_toboolean(L, 5);
	}
	bool dithering = false; // set to true when SW dithering is enabled
	if (lua_isboolean(L, 6)) {
		dithering = lua_toboolean(L, 6);
	}

	int w = bb->w;
	int h = bb->h;

	int drawn_images_count;
	int drawn_images_surface;

	doc->text_view->Resize(w, h);
	doc->text_view->Render();
	if (color) {
		/* Use Color buffer - caller should have provided us with a
		 * Blitbuffer.TYPE_BBRGB32, see CreDocument:drawCurrentView */
		LVColorDrawBuf drawBuf(w, h, bb->data, 32);
		drawBuf.setInvertImages(invert_images);
		drawBuf.setSmoothScalingImages(smooth_scaling);
		doc->text_view->Draw(drawBuf, false);
		drawn_images_count = drawBuf.getDrawnImagesCount();
		drawn_images_surface = drawBuf.getDrawnImagesSurface();
	}
	else {
		/* Set DrawBuf to 8bpp */
		LVGrayDrawBuf drawBuf(w, h, 8, bb->data);
		drawBuf.setInvertImages(invert_images);
		drawBuf.setSmoothScalingImages(smooth_scaling);
		drawBuf.setDitherImages(dithering);
		doc->text_view->Draw(drawBuf, false);
		drawn_images_count = drawBuf.getDrawnImagesCount();
		drawn_images_surface = drawBuf.getDrawnImagesSurface();
	}

	lua_pushinteger(L, drawn_images_count);
	lua_pushnumber(L, (float)drawn_images_surface/(w*h));
	return 2;
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

    ldomXPointer xp = doc->dom_doc->createXPointer(lString16(xpointer_str));
    bool found = !xp.isNull();
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
    {"getTextLangStatus", getTextLangStatus},
    {"getLatestDomVersion", getLatestDomVersion},
    {"getDomVersionWithNormalizedXPointers", getDomVersionWithNormalizedXPointers},
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
    {"getPageOffsetX", getPageOffsetX},
    {"getPageStartY", getPageStartY},
    {"getPageHeight", getPageHeight},
    {"getFullHeight", getFullHeight},
    {"getFontSize", getFontSize},
    {"getFontFace", getFontFace},
    {"getPageMargins", getPageMargins},
    {"getHeaderHeight", getHeaderHeight},
    {"getToc", getTableOfContent},
    {"getVisiblePageCount", getVisiblePageCount},
    {"getNextVisibleWordStart", getNextVisibleWordStart},
    {"getNextVisibleWordEnd", getNextVisibleWordEnd},
    {"getPrevVisibleWordStart", getPrevVisibleWordStart},
    {"getPrevVisibleWordEnd", getPrevVisibleWordEnd},
    {"getPrevVisibleChar", getPrevVisibleChar},
    {"getNextVisibleChar", getNextVisibleChar},
    {"getTextFromXPointers", getTextFromXPointers},
    {"compareXPointers", compareXPointers},
    /*--- set methods ---*/
    {"setIntProperty", setIntProperty},
    {"setStringProperty", setStringProperty},
    {"setViewMode", setViewMode},
    {"setViewDimen", setViewDimen},
    {"setHeaderInfo", setHeaderInfo},
    {"setHeaderFont", setHeaderFont},
    {"setHeaderProgressMarks", setHeaderProgressMarks},
    {"setFontFace", setFontFace},
    {"setAsPreferredFontWithBias", setAsPreferredFontWithBias},
    {"setFontSize", setFontSize},
    {"setDefaultInterlineSpace", setDefaultInterlineSpace},
    {"setStyleSheet", setStyleSheet},
    {"setEmbeddedStyleSheet", setEmbeddedStyleSheet},
    {"setEmbeddedFonts", setEmbeddedFonts},
    {"setBackgroundColor", setBackgroundColor},
    {"setBackgroundImage", setBackgroundImage},
    {"setPageMargins", setPageMargins},
    {"setVisiblePageCount", setVisiblePageCount},
    {"adjustFontSizes", adjustFontSizes},
    {"setBatteryState", setBatteryState},
    {"setCallback", setCallback},
    /* --- control methods ---*/
    {"isBuiltDomStale", isBuiltDomStale},
    {"hasCacheFile", hasCacheFile},
    {"invalidateCacheFile", invalidateCacheFile},
    {"getCacheFilePath", getCacheFilePath},
    {"getStatistics", getStatistics},
    {"getUnknownEntities", getUnknownEntities},
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
    {"getDocumentFileContent", getDocumentFileContent},
    {"getTextFromXPointer", getTextFromXPointer},
    {"getHTMLFromXPointer", getHTMLFromXPointer},
    {"getHTMLFromXPointers", getHTMLFromXPointers},
    {"getPageLinks", getPageLinks},
    {"isLinkToFootnote", isLinkToFootnote},
    {"highlightXPointer", highlightXPointer},
    {"getNormalizedXPointer", getNormalizedXPointer},
    {"getCoverPageImageData", getCoverPageImageData},
    {"gotoLink", gotoLink},
    {"goBack", goBack},
    {"goForward", goForward},
    {"clearSelection", clearSelection},
    {"hasPageMap", hasPageMap},
    {"getPageMap", getPageMap},
    {"getPageMapSource", getPageMapSource},
    {"getPageMapFirstPageLabel", getPageMapFirstPageLabel},
    {"getPageMapLastPageLabel", getPageMapLastPageLabel},
    {"getPageMapCurrentPageLabel", getPageMapCurrentPageLabel},
    {"getPageMapXPointerPageLabel", getPageMapXPointerPageLabel},
    {"getPageMapVisiblePageLabels", getPageMapVisiblePageLabels},
    {"readDefaults", readDefaults},
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
