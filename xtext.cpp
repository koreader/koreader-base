// xtext.cpp
// Lua interface to wrap a utf8 string into a XText object
// that provides various text shaping and layout methods
// with the help of Fribidi, Harfbuzz and libunibreak.

// We do many things similarly to how they are done in crengine,
// and took and adapted much code from it.
// For many links and notes about the concepts and libraries used,
// see: https://github.com/koreader/crengine/issues/307

#include <assert.h>

extern "C"
{
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include "xtext.h"
}

// Harfbuzz
#include <hb.h>
#include <hb-ft.h>

// FriBiDi
#include <fribidi.h>

// Freetype
#include <freetype/ftmodapi.h>
#include <freetype/ftsizes.h>

// libunibreak
#include <wordbreak.h>
#include <linebreak.h>
    // linebreakdef.h is not wrapped by this, unlike linebreak.h
    // (not wrapping it results in "undefined symbol" with the
    // original function name kinda obfuscated)
    #ifdef __cplusplus
    extern "C" {
    #endif
#include <linebreakdef.h>
    #ifdef __cplusplus
    }
    #endif

// luajit doesn't provide lua_set/getuservalue (unless compiled
// with LUAJIT_ENABLE_LUA52COMPAT) but these are equivalents
// for our purpose
#if LUA_VERSION_NUM < 502
#define lua_setuservalue lua_setfenv
#define lua_getuservalue lua_getfenv
#endif

// Some names, as they should be known to Lua
#define XTEXT_LIBNAME "xtext"
#define XTEXT_METATABLE_NAME "luaL_XText"
#define XTEXT_HB_FONT_DATA_METATABLE_NAME "luaL_XText_HB_Font_Data"
#define XTEXT_LUA_HB_FONT_DATA_TABLE_KEY_NAME "_hb_font_data"
#define XTEXT_LUA_FONT_GETFONT_CALLBACK_NAME "getFallbackFont"

// Max unicode chars per shaped (visual) line
#define MAX_LINE_CHARS 4096
// Max returned glyphs per line (usually less glyphs than chars,
// but allow for more just in case some fonts don't come with many
// glyphs and combine many diacritics to form a unicode char).
#define MAX_LINE_GLYPHS 2*MAX_LINE_CHARS

// Max number of fonts (main + fallbacks)
// (main + 15 fallback fonts should be enough)
#define MAX_FONT_NUM 16

#define NOT_MEASURED INT_MIN
#define REPLACEMENT_CHAR 0xFFFD
#define ELLIPSIS_CHAR 0x2026
#define ZERO_WIDTH_JOINER_CHAR 0x200D
#define SOFTHYPHEN_CHAR 0x00AD
#define REALHYPHEN_CHAR 0x002D

// Helpers with font metrics (units are 1/64 px)
// #define FONT_METRIC_FLOOR(x)    ((x) & -64)
// #define FONT_METRIC_CEIL(x)     (((x)+63) & -64)
// #define FONT_METRIC_ROUND(x)    (((x)+32) & -64)
// #define FONT_METRIC_TRUNC(x)    ((x) >> 6)
#define FONT_METRIC_TO_PX(x)    (((x)+32) >> 6) // ROUND + TRUNC

// Uncomment for debugging text measurement and line shaping:
// #define DEBUG_MEASURE_TEXT
// #define DEBUG_SHAPE_LINE

// ==============================================
// Utility functions

inline bool is_unicodepoint_rtl(uint32_t c) {
    // Try to detect if this unicode codepoint is a RTL char
    // Looking at fribidi/lib/bidi-type.tab.i and its rules for tagging
    // a char as RTL, only the following ranges will trigger it:
    //   0590>08FF      Hebrew, Arabic, Syriac, Thaana, Nko, Samaritan...
    //   200F 202B      Right-To-Left mark/embedding control chars
    //   202E 2067      Right-To-Left override/isolate control chars
    //   FB1D>FDFF      Hebrew and Arabic presentation forms
    //   FE70>FEFF      Arabic presentation forms
    //   10800>10FFF    Other rare scripts possibly RTL
    //   1E800>1EEBB    Other rare scripts possibly RTL
    // (There may be LTR chars in these ranges, but we're ok with false
    // positives: we'll invoke fribidi, which will say there's no bidi.)
    // Try to balance the searches
    bool is_rtl = false;
    if ( c >= 0x0590 ) {
        if ( c <= 0x2067 ) {
            if ( c <= 0x08FF ) is_rtl = true;
            else if ( c >= 0x200F ) {
                if ( c == 0x200F || c == 0x202B || c == 0x202E || c == 0x2067 ) is_rtl = true;
            }
        }
        else if ( c >= 0xFB1D ) {
            if ( c <= 0xFDFF ) is_rtl = true;
            else if ( c <= 0xFEFF ) {
                if ( c >= 0xFE70) is_rtl = true;
            }
            else if ( c <= 0x1EEBB ) {
                if (c >= 0x1E800) is_rtl = true;
                else if ( c <= 0x10FFF && c >= 0x10800 ) is_rtl = true;
            }
        }
    }
    return is_rtl;
}

// Fribidi provides fribidi_charset_to_unicode(FRIBIDI_CHAR_SET_UTF8,...)
// but it expects valid utf8, and we want to support broken UTF-8 and WTF-8.
// So we implement Utf8ToUnicode(), which can be called twice:
// - once with dst=NULL, to quickly count the number of Unicode chars,
// - then with a non-null dst (malloc'ed to the previously obtained size)
//   to decode and fill it with the Unicode chars.

// adapted from crengine/src/lvstring.cpp
#define HEAD_CHECK(mask, expect) ((s[0] & mask) == expect)
#define HEAD_BYTE(mask, shift) (((uint32_t)(s[0]) & mask) << shift)
#define CONT_BYTE(index, shift) (((uint32_t)(s[index]) & 0x3F) << shift)
#define HAS_FOLLOWUP(n) (s+n < ends)
#define IS_FOLLOWING(index) ((s[index] & 0xC0) == 0x80)
int Utf8ToUnicode(const char * src,  int srclen, uint32_t * dst, int dstlen, bool &is_valid, bool &has_rtl)
{
    is_valid = true; // until invalid found
    // Trust the provided has_rtl, and avoid expensive check if provided as true
    // has_rtl = false; // until RTL found
    const char * s = src;
    const char * ends = s + srclen;
    bool do_decode = false; // otherwise, only count
    int ucount = 0; // nb of unicode char found
    uint32_t * p = NULL;
    uint32_t * endp = NULL;
    if ( dst != NULL ) {
        do_decode = true;
        p = dst;
        endp = p + dstlen;
    }
    while ( s < ends ) {
        if ( do_decode && p >= endp ) {
            // safety check: avoid writing outside what's been allocated
            break;
        }
        bool valid = false;
        if ( HEAD_CHECK(0x80, 0) ) {
            if ( do_decode )
                *p = (uint32_t)(*s);
            s++;
            valid = true;
        }
        else if ( HEAD_CHECK(0xE0, 0xC0) ) {
            if ( HAS_FOLLOWUP(1) && IS_FOLLOWING(1) ) {
                if ( do_decode )
                    *p = HEAD_BYTE(0x1F, 6) | CONT_BYTE(1,0);
                s += 2;
                valid = true;
            }
        }
        else if ( HEAD_CHECK(0xF0, 0xE0) ) {
            if ( HAS_FOLLOWUP(2) && IS_FOLLOWING(1) && IS_FOLLOWING(2) ) {
                if ( do_decode )
                    *p = HEAD_BYTE(0x0F, 12) | CONT_BYTE(1,6) | CONT_BYTE(2,0);
                s += 3;
                valid = true;
                // We don't check for WTF-8 when counting, but only when decoding.
                // (We may then get a string a bit smaller that what was allocated, but well...)
                if ( do_decode ) {
                    // Supports WTF-8 : https://en.wikipedia.org/wiki/UTF-8#WTF-8
                    // a superset of UTF-8, that includes UTF-16 surrogates
                    // in UTF-8 bytes (forbidden in well-formed UTF-8).
                    // Also see:
                    //   https://unicodebook.readthedocs.io/issues.html#non-strict-utf-8-decoder-overlong-byte-sequences-and-surrogates
                    //   https://unicodebook.readthedocs.io/unicode_encodings.html#utf-16-surrogate-pairs
                    // We may get them from JSON encoded strings, when the JSON
                    // decoder does not decode them correctly (in JSON, high codepoints can't be
                    // directly encoded, and are so encoded with the help of such surrogates.)
                    if ( *p >= 0xD800 && *p <= 0xDBFF && HAS_FOLLOWUP(2) ) {
                        // What we wrote is a high surrogate, and there's a possible low surrogate following
                        if ( HEAD_CHECK(0xF0, 0xE0) && IS_FOLLOWING(1) && IS_FOLLOWING(2) ) { // is a valid 3-bytes sequence
                            uint32_t next = HEAD_BYTE(0x0F, 12) | CONT_BYTE(1,6) | CONT_BYTE(2,0);
                            if (next >= 0xDC00 && next <= 0xDFFF) { // is a low surrogate: valid surrogates sequence
                                // Override what we wrote with the codepoint for this high+low surrogates sequence
                                *p = 0x10000 + ((*p & 0x3FF)<<10) + (next & 0x3FF);
                                s += 3;
                            }
                        }
                    }
                    // todo: deal with invalide surrotage sequences
                }
            }
        }
        else if ( HEAD_CHECK(0xF8, 0xF0) ) {
            if ( HAS_FOLLOWUP(3) && IS_FOLLOWING(1) && IS_FOLLOWING(2) && IS_FOLLOWING(3) ) {
                if ( do_decode )
                    *p = HEAD_BYTE(0x07, 18) | CONT_BYTE(1,12) | CONT_BYTE(2,6) | CONT_BYTE(3,0);
                s += 4;
                valid = true;
            }
        }
        // else: invalid first byte in UTF-8 sequence

        if ( !valid ) {
            if (do_decode)
                *p = REPLACEMENT_CHAR;
            s++;
            is_valid = false;
        }
        if ( do_decode ) {
	    // Try to detect if we have RTL chars, so that if we don't have any,
	    // we don't need to invoke expensive fribidi processing.
	    if ( !has_rtl )
                has_rtl = is_unicodepoint_rtl(*p);
            p++;
        }
        ucount++;
    }
    return ucount;
}

// ==============================================
// Flags, data structures, and global variables

#define HINT_DIRECTION_IS_RTL   0x0001 /// segment direction is RTL
#define HINT_BEGINS_PARAGRAPH   0x0002 /// segment is at start of paragraph
#define HINT_ENDS_PARAGRAPH     0x0004 /// segment is at end of paragraph

#define CHAR_CAN_WRAP_AFTER              0x0001
#define CHAR_MUST_BREAK_AFTER            0x0002
#define CHAR_SKIP_ON_BREAK               0x0004
#define CHAR_CAN_EXTEND_WIDTH            0x0008
#define CHAR_CAN_EXTEND_WIDTH_FALLBACK   0x0010 // Fallback if no space: extend CJK chars
#define CHAR_IS_CLUSTER_TAIL             0x0020
#define CHAR_IS_RTL                      0x0040
#define CHAR_SCRIPT_CHANGE               0x0080
#define CHAR_IS_PARA_START               0x0100
#define CHAR_IS_PARA_END                 0x0200
#define CHAR_PARA_IS_RTL                 0x0400 /// to know the line with this char is part
                                                /// of a paragraph with main dir RTL
#define CHAR_IS_UNSAFE_TO_BREAK_BEFORE   0x0800 /// from HarfBuzz (set when kerning or on arabic when
                                                /// initial/medial/final char forms are involved)
#define CHAR_IS_TAB                      0x1000 /// char is '\t'

// Info, after measure(), about each m_text char
typedef struct {
    unsigned short flags;
    signed short   width;
} xtext_charinfo_t;

// Glyph info when shaping a line (to be returned to Lua as a table of tables)
// (16 bytes, making our static s_shape_result[MAX_LINE_GLYPHS] a 128Kb buffer)
typedef struct {
    int text_index;    // original index in m_text
    uint16_t glyph;    // glyph index in font
    unsigned char font_num;
    unsigned is_rtl:1;
    unsigned can_extend:1;
    unsigned can_extend_fallback:1;
    unsigned is_tab:1;
    unsigned _unused:4;
    signed short  x_advance;
    signed short  x_offset;
    signed short  y_offset;
    unsigned char cluster_len;
    unsigned is_cluster_start:1;
} xtext_shapeinfo_t;

// Holder of HB data structures per font, to be stored as a userdata
// in the Lua font table
typedef struct {
    FT_Size        ft_size;
    hb_font_t *    hb_font;
    hb_buffer_t *  hb_buffer;
    hb_feature_t * hb_features;
    int            hb_features_nb;
} xtext_hb_font_data;

// Global direction and language
static bool default_para_direction_rtl = false;
static char * default_lang = NULL;
static hb_language_t default_lang_hb_language = HB_LANGUAGE_INVALID;

// ==============================================
// Our main class
// (We would have liked to have it pure C++, but we do use and push
// things to the Lua stack, to avoid some indirection and overhead).
class XText {
private:
    // Shared by all XText instances. Should not be used
    // across calls to shapeLine()
    static xtext_shapeinfo_t s_shape_result[MAX_LINE_GLYPHS];
    static bool s_libunibreak_init_done;
public:
    lua_State * m_L; // updated by each Lua method proxy
    int m_length;    // nb of unicode codepoints
    bool m_no_longer_usable; // to prevent using it between dealloc & Lua gc
    bool m_is_valid; // input was valid UTF-8
    bool m_is_measured;
    bool m_para_direction_rtl;  // paragraph direction
    bool m_auto_para_direction; // auto-detect paragraph direction
    bool m_has_rtl;
    bool m_has_bidi;
    bool m_has_multiple_scripts; // true when multiple unicode scripts detected
    char * m_lang;
    hb_language_t m_hb_language;

    int m_width; // measured full width
    int m_hyphen_width; // width of the hyphen char found first among the fonts
    uint32_t *           m_text;        // array of unicode chars
    xtext_charinfo_t *   m_charinfo;    // info about each of these unicode chars
    FriBidiCharType *    m_bidi_ctypes; // FriBiDi internal helper structures
    FriBidiBracketType * m_bidi_btypes;
    FriBidiLevel *       m_bidi_levels;

    XText()
       :m_L(NULL)
       ,m_length(0)
       ,m_no_longer_usable(false)
       ,m_is_valid(false)
       ,m_is_measured(false)
       ,m_para_direction_rtl(false)
       ,m_auto_para_direction(false)
       ,m_has_rtl(false)
       ,m_has_bidi(false)
       ,m_has_multiple_scripts(false)
       ,m_lang(NULL)
       ,m_hb_language(HB_LANGUAGE_INVALID)
       ,m_width(NOT_MEASURED)
       ,m_hyphen_width(NOT_MEASURED)
       ,m_text(NULL)
       ,m_charinfo(NULL)
       ,m_bidi_ctypes(NULL)
       ,m_bidi_btypes(NULL)
       ,m_bidi_levels(NULL)
    {
        // printf("XText created\n");
        // printf("%ld\n", sizeof(xtext_shapeinfo_t));
    }

    ~XText() {
        deallocate();
        // printf("XText destroyed\n");
    }

    void allocate() {
        // We allocate one slot more than m_length, for the case we would have to
        // truncate with an ellipsis the last char and we need to actually use a
        // ZERO_WIDTH_JOINER before the ELLIPSIS (which might be needed with Arabic)
        size_t size = m_length + 1;
        m_charinfo = (xtext_charinfo_t *)calloc(size, sizeof(*m_charinfo)); // set all flags to 0
        if ( m_has_rtl ) {
            m_bidi_ctypes = (FriBidiCharType *)malloc(size * sizeof(*m_bidi_ctypes));
            m_bidi_btypes = (FriBidiBracketType *)malloc(size * sizeof(*m_bidi_btypes));
            m_bidi_levels = (FriBidiLevel *)malloc(size * sizeof(*m_bidi_levels));
        }
    }
    void deallocate() {
        if (m_text)        { free(m_text);        m_text = NULL;   }
        if (m_charinfo)    { free(m_charinfo);    m_charinfo = NULL; }
        if (m_bidi_ctypes) { free(m_bidi_ctypes); m_bidi_ctypes = NULL; }
        if (m_bidi_btypes) { free(m_bidi_btypes); m_bidi_btypes = NULL; }
        if (m_bidi_levels) { free(m_bidi_levels); m_bidi_levels = NULL; }
        if (m_lang)        { delete[] m_lang;     m_lang = NULL; }
        m_no_longer_usable = true;
    }

    void setLanguage(const char * lang) {
        m_lang = new char[strlen(lang)+1];
        strcpy(m_lang, lang);
        m_hb_language = hb_language_from_string(m_lang, -1);
    }

    // Get UTF-32 m_text from the provided UTF-8
    void setTextFromUTF8String(const char * utf8_text, int utf8_len) {
        // We call Utf8ToUnicode() twice: a 1st phase to quickly
        // count the number of unicode codepoints, before allocating m_text,
        // and a 2nd to actually do the conversion and fill m_text.
        m_length = Utf8ToUnicode(utf8_text, utf8_len, NULL, 0, m_is_valid, m_has_rtl);
        size_t size = m_length + 1; // (one slot more, see above)
        m_text = (uint32_t *)malloc(size * sizeof(*m_text));

        // m_has_rtl is only detected in the 2nd phase.
        // If m_para_direction_rtl is true, set m_has_rtl=true in all case
        // to force checkBidi(), and avoid some work in Utf8ToUnicode().
        m_has_rtl = false;
        if ( m_para_direction_rtl )
            m_has_rtl = true;
        m_length = Utf8ToUnicode(utf8_text, utf8_len, m_text, m_length, m_is_valid, m_has_rtl);
    }

    // Get UTF-32 m_text from a Lua array of individual UTF-8 strings,
    // as made by frontend/util.lua util.splitToChars(text) and
    // hold as InputType.charlist, which is given to TextBoxWidget.
    // We need this because:
    // There are multiple ways to handle invalid UTF-8 (like WTF-8,
    // and whether 1 replacement char per invalid byte or per sequence
    // of invalid bytes).
    // Our setTextFromUTF8String() may not always give a m_text
    // equivalent to InputType.charlist - but we need them to be sync'ed
    // for correct cursor positioning and text insertion/deletion.
    // So, we allow XText to handle such input: this avoid having to sync
    // both utf8 decoding algorithms (but we can aim later at having
    // a single good one).
    void setTextFromUTF8CharsLuaArray(lua_State * L, int n) {
        m_length = (int) lua_objlen(L, n); // NOTE: size_t -> int, as that's what both FriBidi & HarfBuzz expect.
        size_t size = m_length + 1; // (one slot more, see above)
        m_text = (uint32_t *)malloc(size * sizeof(*m_text));
        m_is_valid = true; // assume it is valid if coming from Lua array
        m_has_rtl = false;
        // If m_para_direction_rtl is true, set m_has_rtl=true in all case
        // to force checkBidi(), and avoid is_unicodepoint_rtl() check below.
        if ( m_para_direction_rtl )
            m_has_rtl = true;

        for (int i = 0; i < m_length; i++) {
            lua_rawgeti(L, n, i+1); // (Lua indices start at 1)
            size_t len;
            const unsigned char * s = (const unsigned char*) luaL_checklstring(L, -1, &len);
            lua_pop ( L, 1 ); // clean stack
            // Should be similar to base/util.lua util.utf8charcode(charstring)
            uint32_t u;
            if (len == 1) {
                u = s[0] & 0x7F;
            }
            else if (len == 2) {
                u = ((s[0] & 0x1F)<<6) + (s[1] & 0x3F);
            }
            else if (len == 3) {
                u = ((s[0] & 0x0F)<<12) + ((s[1] & 0x3F)<<6) + (s[2] & 0x3F);
            }
            else if (len == 4) {
                u = ((s[0] & 0x07)<<18) + ((s[1] & 0x3F)<<12) + + ((s[2] & 0x3F)<<6) + (s[3] & 0x3F);
            }
            else {
                u = REPLACEMENT_CHAR;
            }
            m_text[i] = u;
            if ( !m_has_rtl && is_unicodepoint_rtl(u) )
                m_has_rtl = true;
        }
    }

    void checkBidi() {
        if ( !m_has_rtl ) // No need for expensive bidi work
            return;

        FriBidiParType specified_para_bidi_type;
        if ( m_auto_para_direction) {
            if ( m_para_direction_rtl )
                specified_para_bidi_type = FRIBIDI_PAR_WRTL; // Weak RTL
            else
                specified_para_bidi_type = FRIBIDI_PAR_WLTR; // Weak LTR
        }
        else {
            if ( m_para_direction_rtl )
                specified_para_bidi_type = FRIBIDI_PAR_RTL; // Strong RTL
            else
                specified_para_bidi_type = FRIBIDI_PAR_LTR; // Strong LTR
        }

        // Compute bidi levels
        fribidi_get_bidi_types((const FriBidiChar*)m_text, m_length, m_bidi_ctypes);
        fribidi_get_bracket_types((const FriBidiChar*)m_text, m_length, m_bidi_ctypes, m_bidi_btypes);

        // We would have simply done:
        //   int max_level = fribidi_get_par_embedding_levels_ex(m_bidi_ctypes, m_bidi_btypes,
        //                     m_length, (FriBidiParType*)&m_para_bidi_type, m_bidi_levels);
        // But unfortunately, fribidi_get_par_embedding_levels_ex() only works on a single
        // paragraph, and will set bogus levels for the text following the
        // first \n (or other Unicode Block Separators, BS).
        // FriBiDi expects us to work only on individual paragraphs. But we
        // still want to process the whole text here so that we're done with it.
        // So, split on BS and call fribidi_get_par_embedding_levels_ex() on
        // each segment - hoping doing it that way is OK...
        int max_level = 0;
        int s_start = 0;
        int i = 0;
        while ( i <= m_length ) {
            if ( i == m_length || m_bidi_ctypes[i] == FRIBIDI_TYPE_BS ) {
                int s_length = i - s_start;
                if (i < m_length)
                    s_length += 1; // include BS at i in segment
                FriBidiParType    para_bidi_type = specified_para_bidi_type;
                FriBidiCharType *    bidi_ctypes = (FriBidiCharType *)   (m_bidi_ctypes + s_start);
                FriBidiBracketType * bidi_btypes = (FriBidiBracketType *)(m_bidi_btypes + s_start);
                FriBidiLevel *       bidi_levels = (FriBidiLevel *)      (m_bidi_levels + s_start);
                int this_max_level = fribidi_get_par_embedding_levels_ex(bidi_ctypes, bidi_btypes,
                                                            s_length, &para_bidi_type, bidi_levels);
                /* To see resulting bidi levels:
                printf("par_type %d , max_level %d\n", para_bidi_type, this_max_level);
                for (int j=s_start; j<i; j++)
                    printf("%x %c %d\n", m_text[j], m_text[j], m_bidi_levels[j]);
                */
                if ( this_max_level > max_level )
                    max_level = this_max_level;
                // we set a flag on all chars part of this segment so we can know what
                // is the paragraph direction of the paragraph this char is in.
                if ( para_bidi_type == FRIBIDI_PAR_RTL || para_bidi_type == FRIBIDI_PAR_WRTL ) {
                    for ( int j=s_start; j<i; j++ ) {
                        m_charinfo[j].flags |= CHAR_PARA_IS_RTL;
                    }
                    // Also set it on the \n/FRIBIDI_TYPE_BS char
                    if (i < m_length) {
                        m_charinfo[i].flags |= CHAR_PARA_IS_RTL;
                    }
                }
                s_start = i+1;
            }
            i++;
        }

        // If computed max level == 1, we are in plain and only LTR,
        // so no need for more bidi work later.
        if ( max_level > 1 )
            m_has_bidi = true;
    }

    // Get HB font data structures for font #num (create them and store them in the
    // Lua font object, or get the previously created and stored ones)
    // This must be a method of our XText object, as it uses the uservalue that has
    // been associated with the userdata that is wrapping this XText instance.
    xtext_hb_font_data * getHbFontData(int num) {
        if ( num > MAX_FONT_NUM )
            return NULL;
        // This uses the stack for C <-> Lua interaction, but we should put this
        // stack back in its original state, as it may carry additional arguments
        // to the original function that was called.
        int stack_orig_top = lua_gettop(m_L);
        // The uservalue (the Lua font face_obj table) has been put at 1 on the stack
        // by check_XText().
        // Get the Lua font table for fallback font #num, by calling
        // the Lua callback function: font.getFallbackFont(num).
        lua_getfield(m_L, 1, XTEXT_LUA_FONT_GETFONT_CALLBACK_NAME);
        lua_pushinteger(m_L, num);
        lua_pcall(m_L, 1, 1, 0); // 1 argument, 1 returned value
        if ( !lua_istable(m_L, -1) ) { // No #num font (we got "false")
            lua_settop(m_L, stack_orig_top); // restore stack / drop our added work stuff
            return NULL;
        }

        // We have a font, we'll be able to return something.
        xtext_hb_font_data * hb_data;

        // We got our font table. See if we already have the hb stuff stored
        // as a userdata under the key '_hb_font_data'
        lua_getfield(m_L, -1, XTEXT_LUA_HB_FONT_DATA_TABLE_KEY_NAME);
        if ( lua_isuserdata(m_L, -1) ) {
            // We do: just return the pointer to it (that we stored as the userdata)
            hb_data = (xtext_hb_font_data *)luaL_checkudata(m_L, -1, XTEXT_HB_FONT_DATA_METATABLE_NAME);
            lua_settop(m_L, stack_orig_top); // restore stack / drop our added work stuff
            return hb_data;
        }
        lua_pop(m_L, 1); // remove nil

        // Not previously stored: we have to create it and store it

        // Get the 'ftsize' Freetype FFI wrapped object
        lua_getfield(m_L, -1, "ftsize");
        // printf("face type: %d %s\n", lua_type(m_L, -1), lua_typename(m_L, lua_type(m_L, -1)));
        // We expect it to be a luajit ffi cdata, but the C API does not have a #define for
        // that type. But it looks like its value is higher than the greatest LUA_T* type.
        if ( lua_type(m_L, -1) <= LUA_TTHREAD ) {// Higher plain Lua datatype (lua.h)
            luaL_typerror(m_L, -1, "cdata");
        }
        // Get the usable (for Harfbuzz) FT_Size object
        FT_Size size = *(FT_Size *)lua_topointer(m_L, -1);
        lua_pop(m_L, 1); // remove ftsize object

        // Create a Lua userdata that will keep the reference to our hb_data
        // (alloc/free of this userdata is managed by Lua, but not the cleanup
        // of the Harfbuzz stuff allocated and stored in it. So, we have set
        // to its metatable a __gc function, so it is called when the userdata
        // is gc()'ed by Lua, so we can free these Harfbuzz structures).
        hb_data = (xtext_hb_font_data *)lua_newuserdata(m_L, sizeof(xtext_hb_font_data));
        luaL_getmetatable(m_L, XTEXT_HB_FONT_DATA_METATABLE_NAME);
        lua_setmetatable(m_L, -2);
        // Set this userdata as the '_hb_font_data' key of our Lua font table
        lua_setfield(m_L, -2, XTEXT_LUA_HB_FONT_DATA_TABLE_KEY_NAME);

        ++*(int *)size->generic.data;
        FT_Activate_Size(size);
        hb_data->ft_size = size;
        FT_Reference_Library((FT_Library)size->face->generic.data);
        hb_data->hb_font = hb_ft_font_create_referenced(size->face);
        // These flags should be sync'ed with freetype.lua FT_Load_Glyph_flags:
        // hb_ft_font_set_load_flags(hb_data->hb_font, FT_LOAD_TARGET_LIGHT | FT_LOAD_FORCE_AUTOHINT);
        // No hinting, as it would mess synthetized bold.
        hb_ft_font_set_load_flags(hb_data->hb_font, FT_LOAD_TARGET_LIGHT | FT_LOAD_NO_AUTOHINT | FT_LOAD_NO_HINTING);

        hb_data->hb_buffer = hb_buffer_create();
        hb_data->hb_features_nb = 0;
        hb_data->hb_features = NULL;
        // We can set what OTF features to use from Lua
        lua_getfield(m_L, -1, "hb_features");
        if ( lua_istable(m_L, -1) ) {
            lua_pushnil(m_L);  /* first key */
            while ( lua_next(m_L, -2) != 0 ) {
                if ( lua_isstring(m_L, -1) ) {
                    size_t len;
                    const char * feature = lua_tolstring(m_L, -1, &len);
                    // printf("hbfont feature: %s\n", feature);
                    hb_feature_t f;
                    if ( hb_feature_from_string(feature, len, &f) ) {
                        hb_data->hb_features_nb++;
                        hb_data->hb_features = (hb_feature_t*)realloc( hb_data->hb_features,
                                                    hb_data->hb_features_nb * sizeof(hb_feature_t) );
                        if ( hb_data->hb_features )
                            hb_data->hb_features[hb_data->hb_features_nb-1] = f;
                    }
                }
                lua_pop(m_L, 1); // remove fetched value, but keep key for next iteration
            }
        }
        // printf("hbfont #features: %d\n", hb_data->hb_features_nb);

        lua_settop(m_L, stack_orig_top); // restore stack / drop our added work stuff
        return hb_data;
    }

    int getHyphenWidth() {
        if ( m_hyphen_width != NOT_MEASURED )
            return m_hyphen_width;
        for ( int font_num=0; font_num < MAX_FONT_NUM; font_num++ ) {
            xtext_hb_font_data * hb_data = getHbFontData(font_num);
            if ( !hb_data ) { // No such font (so, no more fallback font)
                m_hyphen_width = 0;
                break;
            }
            FT_Activate_Size(hb_data->ft_size);
            hb_font_t * _hb_font = hb_data->hb_font;
            hb_codepoint_t glyph_id;
            if ( hb_font_get_glyph(_hb_font, REALHYPHEN_CHAR, 0, &glyph_id) ) {
                hb_position_t x, y;
                hb_font_get_glyph_advance_for_direction(_hb_font, glyph_id, HB_DIRECTION_LTR, &x, &y);
                m_hyphen_width = FONT_METRIC_TO_PX(x);
                break;
            }
        }
        return m_hyphen_width;
    }

    void measure() {
        if ( m_is_measured )
            return;

        if ( m_length == 0 ) {
            // Nothing to allocate nor measure
            m_width = 0;
            m_is_measured = true;
            return;
        }

        allocate();
        checkBidi();

        if ( !s_libunibreak_init_done ) {
            s_libunibreak_init_done = true;
            init_linebreak();
        }
        struct LineBreakContext lbCtx;

        int final_width = 0;
        int prev_para_start = 0;
        int start = 0; // start of segment to be measured
        FriBidiLevel last_bidi_level = 0;
        FriBidiLevel new_bidi_level = 0;
        hb_unicode_funcs_t* unicode_funcs = hb_unicode_funcs_get_default();
        hb_script_t prev_script = HB_SCRIPT_COMMON;

        for ( int i=0; i<=m_length; i++ ) {
            bool end_of_text = i == m_length;

            // Bidi handling
            bool bidi_level_changed = false;
            int last_direction = 1; // LTR if no bidi found
            if ( m_has_bidi ) {
                new_bidi_level = i < m_length ? m_bidi_levels[i] : last_bidi_level;
                if ( i == 0 )
                    last_bidi_level = new_bidi_level;
                else if ( new_bidi_level != last_bidi_level )
                    bidi_level_changed = true;
                if ( FRIBIDI_LEVEL_IS_RTL(last_bidi_level) )
                    last_direction = -1; // RTL
            }

            // Text Unicode script change
            // Arabic surrounded by hebrew chars would not get its letters joined
            // if they were all shaped as a single segment. This may probably happen
            // too with some complex LTR scripts like indic surrounded by latin.
            // Note: libraqm and Lua library https://github.com/luapower/tr do
            // a bit more than that by trying to make neutral paired characters part
            // of a same script segment (_raqm_resolve_scripts(), using a stack, so
            // probably costly and needing another pass). We don't do that for now.
            bool script_changed = false;
            if ( i < m_length ) {
                hb_script_t script = hb_unicode_script(unicode_funcs, m_text[i]);
                if ( script != HB_SCRIPT_COMMON && script != HB_SCRIPT_INHERITED && script != HB_SCRIPT_UNKNOWN ) {
                    if ( prev_script != HB_SCRIPT_COMMON && script != prev_script ) {
                        m_charinfo[i].flags |= CHAR_SCRIPT_CHANGE;
                        script_changed = true;
                        m_has_multiple_scripts = true;
                    }
                    prev_script = script;
                }
                // Note: as we have here guessed the script of what's to be measured
                // next, we could store it in m_charinfo (an additional int32...),
                // so we can pass it to getHbFontData() (or use it and check
                // ourselves here), to skip fallback fonts that do not support
                // this script - if fonts announce the scripts they support (I think
                // I have seen that in some font tables, may be OTF only?).
            }

            // Line breaking and wrapping
            bool line_break = false;
            if ( i == 0 ) {
                lb_init_break_context(&lbCtx, m_text[i], m_lang ? m_lang : default_lang);
            }
            else {
                // When at end of m_text, add a letter ('Z') so a trailing \n can be
                // flagged as CHAR_MUST_BREAK_AFTER, so we can show an empty line
                // and allow the cursor to be positioned after that last \n.
                int ch = i < m_length ? m_text[i] : 'Z';
                int brk = lb_process_next_char(&lbCtx, ch);
                // This tells us about a break between previous char and this 'ch'.
                // printf("between <%c%c>: brk %d\n", m_text[i-1], m_text[i], brk);
                // Note: LINEBREAK_ALLOWBREAK is set on the last space in a sequence
                // of multiple consecutive spaces.
                if ( m_text[i-1] == '\t' ) {
                    // Previous note also applies to tabs: but allow break
                    // after any tab (so, between any consecutive tabs)
                    m_charinfo[i-1].flags |= CHAR_CAN_WRAP_AFTER;
                    m_charinfo[i-1].flags |= CHAR_SKIP_ON_BREAK; // skip when at end of line
                    m_charinfo[i-1].flags |= CHAR_CAN_EXTEND_WIDTH; // (frontend can ignore that)
                    m_charinfo[i-1].flags |= CHAR_IS_TAB;
                }
                else if ( brk == LINEBREAK_ALLOWBREAK ) {
                    // Happens between a space (at i-1) and its following non-space
                    // char, or after each CJK char.
                    m_charinfo[i-1].flags |= CHAR_CAN_WRAP_AFTER;
                    // We trust libunibreak to not set it on non-break spaces, but
                    // we have to manually check for spaces that we can skip on break
                    // and those with a not-fixed width that we can extend when justifying
                    // text. List of space chars at http://jkorpela.fi/chars/spaces.html
                    uint32_t pch = m_text[i-1];
                    if ( pch == ' ' || pch == 0x3000 || (pch >= 0x2000 && pch <= 0x200B) ){
                        m_charinfo[i-1].flags |= CHAR_SKIP_ON_BREAK; // skip when at end of line
                        if ( pch == ' ' ) { // others have a fixed width, and not for IDEOGRAPHIC SPACE
                            m_charinfo[i-1].flags |= CHAR_CAN_EXTEND_WIDTH; // for text justification
                        }
                    }
                    // In case there's no space (pure CJK line), and we want text
                    // justification, allow extending width of all allowbreak chars
                    // (we could check if pch is really a CJK one, but let's take
                    // this shortcut for now). This can be ignored in frontend if
                    // it looks ugly or is not wanted by CJK readers.
                    m_charinfo[i-1].flags |= CHAR_CAN_EXTEND_WIDTH_FALLBACK;
                }
                else if ( brk == LINEBREAK_MUSTBREAK ) {
                    // Happens between "\n" (at i-1) and its follow up char
                    m_charinfo[i-1].flags |= CHAR_MUST_BREAK_AFTER;
                    m_charinfo[i-1].flags |= CHAR_SKIP_ON_BREAK;
                    line_break = true;
                }
                else if ( m_text[i-1] == 0x00A0 ) { // regular no-break-space with a non-fixed width
                    m_charinfo[i-1].flags |= CHAR_CAN_EXTEND_WIDTH; // for text justification
                }
            }

            if ( i>start && (bidi_level_changed || script_changed || line_break || end_of_text) ) {
                int hints = 0;
                if ( start == prev_para_start ) {
                    hints |= HINT_BEGINS_PARAGRAPH;
                    // We set this fact in m_charinfo too, so it's available to shapeLine()
                    m_charinfo[start].flags |= CHAR_IS_PARA_START;
                }
                if ( line_break || i == m_length ) {
                    hints |= HINT_ENDS_PARAGRAPH;
                    if ( line_break && i-2 >= start) {
                        m_charinfo[i-2].flags |= CHAR_IS_PARA_END;
                    }
                    else {
                        m_charinfo[i-1].flags |= CHAR_IS_PARA_END;
                    }
                }
                if ( last_direction < 0 ) {
                    hints |= HINT_DIRECTION_IS_RTL;
                }
                int end = line_break ? i-1 : i;
                int w = measureSegment(0, start, end, hints); // measure with font #0
                if ( w != NOT_MEASURED )
                    final_width += w;
                start = i;
                if ( line_break )
                    prev_para_start = i;
            }
            last_bidi_level = new_bidi_level;
        }

        m_width = final_width;
        m_is_measured = true;
    }

    // Based on crengine/src/lvfntman.cpp measureText() with _kerningMode == KERNING_MODE_HARFBUZZ
    // Changes:
    // - we work on the full m_text/m_charinfo, with absolute indices start and end (end excluded)
    // - we don't use cumulative widths: we store individual char widths (to store them in 16 bits
    //   in m_charinfo, instead of needing a full 32 bits int for each char)
    int measureSegment(int font_num, int start, int end, int hints) {
        if ( font_num > MAX_FONT_NUM )
            return NOT_MEASURED;

        #ifdef DEBUG_MEASURE_TEXT
            char indent[32];
            int n = 0;
            for (; n<font_num; n++) {
                indent[n*2] = ' ';
                indent[n*2+1] = ' ';
            }
            indent[n*2] = 0;
        #endif

        int len = end - start;
        if ( len <= 0 )
            return NOT_MEASURED;

        xtext_hb_font_data * hb_data = getHbFontData(font_num);
        if ( !hb_data ) // No such font (so, no more fallback font)
            return NOT_MEASURED;

        FT_Activate_Size(hb_data->ft_size);

        hb_font_t *    _hb_font     = hb_data->hb_font;
        hb_buffer_t *  _hb_buffer   = hb_data->hb_buffer;
        hb_feature_t * _hb_features = hb_data->hb_features;
        int _hb_features_nb = hb_data->hb_features_nb;

        // Fill HarfBuzz buffer
        hb_buffer_clear_contents(_hb_buffer);
        // for (int i = start; i < end; i++) {
        //     hb_buffer_add(_hb_buffer, (hb_codepoint_t)(m_text[i]), i);
        // }
        hb_buffer_add_codepoints(_hb_buffer, (hb_codepoint_t*)m_text, m_length, start, end-start);
        hb_buffer_set_content_type(_hb_buffer, HB_BUFFER_CONTENT_TYPE_UNICODE);

        // If we are provided with direction and hints, let harfbuzz know
        if ( hints & HINT_DIRECTION_IS_RTL )
            hb_buffer_set_direction(_hb_buffer, HB_DIRECTION_RTL);
        else
            hb_buffer_set_direction(_hb_buffer, HB_DIRECTION_LTR);
        int hb_flags = HB_BUFFER_FLAG_DEFAULT; // (hb_buffer_flags_t won't let us do |= )
        if ( hints & HINT_BEGINS_PARAGRAPH )
            hb_flags |= HB_BUFFER_FLAG_BOT;
        if ( hints & HINT_ENDS_PARAGRAPH )
            hb_flags |= HB_BUFFER_FLAG_EOT;
        hb_buffer_set_flags(_hb_buffer, (hb_buffer_flags_t)hb_flags);

        // If we got a specified language or a default one, let harfbuzz know
        if ( m_lang )
            hb_buffer_set_language(_hb_buffer, m_hb_language);
        else if (default_lang)
            hb_buffer_set_language(_hb_buffer, default_lang_hb_language);

        // Let HB guess what's not been set (script, direction, language)
        hb_buffer_guess_segment_properties(_hb_buffer);
        // printf("HBlanguage: %s\n", hb_language_to_string(hb_buffer_get_language(_hb_buffer)));

        // Shape
        hb_shape(_hb_font, _hb_buffer, _hb_features, _hb_features_nb);

        // Harfbuzz has guessed and set a direction even if we did not provide one.
        bool is_rtl = false;
        if ( hb_buffer_get_direction(_hb_buffer) == HB_DIRECTION_RTL ) {
            is_rtl = true;
            // "For buffers in the right-to-left (RTL) or bottom-to-top (BTT) text
            // flow direction, the directionality of the buffer itself is reversed
            // for final output as a matter of design. Therefore, HarfBuzz inverts
            // the monotonic property: client programs are guaranteed that
            // monotonically increasing initial cluster values will be returned as
            // monotonically decreasing final cluster values."
            // hb_buffer_reverse_clusters() puts the advance on the last char of a
            // cluster, unlike hb_buffer_reverse() which puts it on the first, which
            // looks more natural (like it happens when LTR).
            // But hb_buffer_reverse_clusters() is required to have the clusters
            // ordered as our text indices, so we can map them back to our text.
            hb_buffer_reverse_clusters(_hb_buffer);
        }

        int glyph_count = hb_buffer_get_length(_hb_buffer);
        hb_glyph_info_t *     glyph_info = hb_buffer_get_glyph_infos(_hb_buffer, 0);
        hb_glyph_position_t * glyph_pos  = hb_buffer_get_glyph_positions(_hb_buffer, 0);

        #ifdef DEBUG_MEASURE_TEXT
            printf("%sMSHB >>> measureSegment start=%d len=%d is_rtl=%d [font#%d]\n",
                                                indent, start, len, is_rtl, font_num);
            for (int i = 0; i < (int)glyph_count; i++) {
                char glyphname[32];
                hb_font_get_glyph_name(_hb_font, glyph_info[i].codepoint, glyphname, sizeof(glyphname));
                printf("%sMSHB g%d c%d(=t:%x) [%x %s]\tadvance=(%d,%d)", indent, i, glyph_info[i].cluster,
                            m_text[glyph_info[i].cluster], glyph_info[i].codepoint, glyphname,
                            FONT_METRIC_TO_PX(glyph_pos[i].x_advance), FONT_METRIC_TO_PX(glyph_pos[i].y_advance));
                if (glyph_pos[i].x_offset || glyph_pos[i].y_offset)
                    printf("\toffset=(%d,%d)", FONT_METRIC_TO_PX(glyph_pos[i].x_offset), FONT_METRIC_TO_PX(glyph_pos[i].y_offset));
                printf("\n");
            }
            printf("%sMSHB ---\n", indent);
        #endif

        // We need to set widths and flags on our original text.
        // hb_shape() has modified buffer to contain glyphs, and text
        // and buffer may desync (because of clusters, ligatures...)
        // in both directions in a same run.
        // Also, a cluster must not be cut, so we want to set the same
        // width to all our original text chars that are part of the
        // same cluster (so 2nd+ chars in a cluster will get a 0-width,
        // and, when splitting lines, will fit on a line with the
        // cluster leading char).
        // So run along our original text (chars, t), and try to follow
        // harfbuzz buffer (glyphs, hg), putting the advance of all
        // the glyphs that belong to the same cluster (hcl) on the
        // first char that started that cluster (and 0-width on the
        // followup chars).
        // It looks like Harfbuzz makes a cluster of combined glyphs
        // even when the font does not have any or all of the required
        // glyphs:
        // When meeting a not-found glyph (codepoint=0, name=".notdef"),
        // we record the original starting t of that cluster, and
        // keep processing (possibly other chars with .notdef glyphs,
        // giving them the width of the 'tofu' char), until we meet a char
        // with a found glyph. We then hold on on this one, while we go
        // measureSegment() the previous segment of text (that got .notdef
        // glyphs) with a fallback font, and update the wrong widths
        // and flags.

        int final_width = 0;
        int cur_cluster = 0;
        int hg = 0;  // index in glyph_info/glyph_pos
        int hcl = 0; // cluster number of glyph at hg
        bool cur_cluster_unsafe_to_break = false;
        int t_notdef_start = -1;
        int t_notdef_end = -1;
        int notdef_width = 0;
        for ( int t = start; t < end; t++ ) {
            #ifdef DEBUG_MEASURE_TEXT
                printf("%sMSHB t%d (=%x) ", indent, t, m_text[t]);
            #endif
            // Grab all glyphs that do not belong to a cluster greater that our char position
            int cur_width = 0; // current cluster width
            while ( hg < glyph_count ) {
                hcl = glyph_info[hg].cluster;
                if ( hcl <= t ) { // glyph still part of a previous cluster
                    int advance = 0;
                    if ( glyph_info[hg].codepoint != 0 ) { // Codepoint found in this font
                        #ifdef DEBUG_MEASURE_TEXT
                            printf("(found cp=%x) ", glyph_info[hg].codepoint);
                        #endif
                        // Note: in crengine, we needed to add the following additional condition
                        // to only process past notdef when the first glyph of a cluster is found.
                        // This strangely seems not needed here (the thai sample that caused issues
                        // with crengine displays fine in xtext), but let's add it for consistency.
                        if ( t_notdef_start >= 0 && hcl > cur_cluster ) {
                            // We have a segment of previous ".notdef", and this glyph starts a new cluster
                            t_notdef_end = t;

                            // Let a fallback font replace the wrong values in widths and flags
                            // No-op if there is no more fallback font
                            #ifdef DEBUG_MEASURE_TEXT
                                printf("%s[...]\n%sMSHB ### measuring past failures with fallback font %d>%d\n",
                                                        indent, indent, t_notdef_start, t_notdef_end);
                            #endif
                            // Drop BOT/EOT flags if this segment is not at start/end
                            int fb_hints = hints;
                            if ( t_notdef_start > 0 )
                                fb_hints &= ~HINT_BEGINS_PARAGRAPH;
                            if ( t_notdef_end < len )
                                fb_hints &= ~HINT_ENDS_PARAGRAPH;
                            int fallback_width = measureSegment( font_num+1, t_notdef_start, t_notdef_end, fb_hints );
                            if ( fallback_width != NOT_MEASURED ) {
                                // The individual char widths will have been updated,
                                // but we need to correct final_width where we kept
                                // adding notdef widths
                                final_width = final_width - notdef_width + fallback_width;
                            }
                            #ifdef DEBUG_MEASURE_TEXT
                                printf("%sMSHB ### measured past failures > W= %d\n%s[...]",
                                                                indent, fallback_width, indent);
                            #endif

                            t_notdef_start = -1;
                            notdef_width = 0;
                            // And go on with the found glyph now that we fixed what was before
                        }
                        // Glyph found in this font
                        advance = FONT_METRIC_TO_PX(glyph_pos[hg].x_advance);
                    }
                    else {
                        #ifdef DEBUG_MEASURE_TEXT
                            printf("(glyph not found) ");
                        #endif
                        // Keep the advance of .notdef/tofu in case there is no fallback font to correct them
                        advance = FONT_METRIC_TO_PX(glyph_pos[hg].x_advance);
                        if ( t_notdef_start < 0 ) {
                            t_notdef_start = t;
                        }
                    }
                    #ifdef DEBUG_MEASURE_TEXT
                        printf("c%d+%d ", hcl, advance);
                    #endif
                    cur_width += advance;
                    cur_cluster = hcl;
                    hb_glyph_flags_t flags = hb_glyph_info_get_glyph_flags(&glyph_info[hg]);
                    cur_cluster_unsafe_to_break = flags & HB_GLYPH_FLAG_UNSAFE_TO_BREAK;
                    hg++;
                    continue; // keep grabbing glyphs
                }
                break;
            }
            // Done grabbing clustered glyphs: they contributed to cur_width.
            if ( t > cur_cluster ) {
                // Our char is part of a cluster that started on a previous char
                m_charinfo[t].width = 0;
                m_charinfo[t].flags |= CHAR_IS_CLUSTER_TAIL;
                // todo: see at using HB_GLYPH_FLAG_UNSAFE_TO_BREAK to
                // set this flag instead/additionally
            }
            else {
                // We're either a single char cluster, or the start
                // of a multi chars cluster.
                m_charinfo[t].width = cur_width; // get all the width
                final_width += cur_width;
                // It seems each soft-hyphen is in its own cluster, of length 1 and width 0,
                // so HarfBuzz must already deal correctly with soft-hyphens.
                if ( t_notdef_start >= 0 ) {
                    // If we had one glyph not found, we'll measure the whole cluster with
                    // a fallback font, so add the full cluster advance to notdef_width,
                    // that we'll remove from final_width if we measure sucessfully with
                    // a fallback font.
                    notdef_width += cur_width;
                }
            }
            if ( is_rtl )
                m_charinfo[t].flags |= CHAR_IS_RTL;
            if ( cur_cluster_unsafe_to_break )
                m_charinfo[t].flags |= CHAR_IS_UNSAFE_TO_BREAK_BEFORE;

            #ifdef DEBUG_MEASURE_TEXT
                printf("=> %d (flags=%d) => W=%d\n", cur_width, m_charinfo[t].flags, final_width);
            #endif
        } // process next char t

        // Process .notdef glyphs at end of text (same logic as above)
        if ( t_notdef_start >= 0 ) {
            t_notdef_end = end;
            #ifdef DEBUG_MEASURE_TEXT
                printf("%s[...]\n%sMSHB ### measuring past failures at EOT with fallback font %d>%d\n",
                                        indent, indent, t_notdef_start, t_notdef_end);
            #endif
            // Drop BOT flag if this segment is not at start (it is at end)
            int fb_hints = hints;
            if ( t_notdef_start > 0 )
                fb_hints &= ~HINT_BEGINS_PARAGRAPH;
            int fallback_width = measureSegment( font_num+1, t_notdef_start, t_notdef_end, fb_hints );
            if ( fallback_width != NOT_MEASURED ) {
                // printf("%sMSHB ### final_width=%d - notdef_width=%d + fallback_width=%d > W= %d\n%s[...]",
                //   indent, final_width, notdef_width, fallback_width, final_width - notdef_width + fallback_width, indent);
                final_width = final_width - notdef_width + fallback_width;
            }
            #ifdef DEBUG_MEASURE_TEXT
                printf("%sMSHB ### measured past failures at EOT > W= %d\n%s[...]", indent, final_width, indent);
            #endif
        }

        #ifdef DEBUG_MEASURE_TEXT
            printf("%sMSHB <<< W=%d [font#%d]\n", indent, final_width, font_num);
            printf("%sMSHB dwidths[]: ", indent);
            for (int t = start; t < end; t++)
                printf("%d:%d ", t, m_charinfo[t].width);
            printf("\n");
        #endif

        return final_width;
    }

    // Get 'end' offset and other info for a line starting at offset 'start' for
    // a max 'targeted_width', using widths and flags found out by measure().
    // No bidi involved: this works with chars in logical order.
    // Returns onto the Lua stack a table with various information about the line.
    // (no_line_breaking_rules=true is just used by TextWidget to truncate its text to max_width)
    void makeLine(int start, int targeted_width, bool no_line_breaking_rules, int tabstop_width, int expansion_pct_rather_than_hyphen) {
        // Notes:
        // - Given how TextBoxWidget functions work, end_offset is
        //   inclusive: the line spans offset to end_offset included.
        // - we can ignore as part of lines at most 1 char
        //   between a line and the next line (between end_offset
        //   and next_line_start_offset): it should be either
        //   the \n that caused a hard break, or the space the
        //   wrap happened on. We must then also ignore its glyph
        //   width in the returned line width.
        int next_line_start_offset = -1;
        int candidate_end = -1;
        int candidate_line_width = 0;
        int extendable_width = 0;
        bool candidate_is_soft_hyphen = true; // If the first candidate is a soft-hyphen allow it to be used
        bool forced_break = false;
        bool has_tabs = false;
        int line_width = 0;
        int i = start;
        while ( i < m_length ) {
            forced_break = false;
            int flags;
            if ( no_line_breaking_rules )
                flags = m_charinfo[i].flags | CHAR_CAN_WRAP_AFTER; // Allow cutting on any char
            else
                flags = m_charinfo[i].flags;
            int new_line_width = line_width + m_charinfo[i].width;
            if ( flags & CHAR_IS_TAB ) {
                has_tabs = true;
                if ( tabstop_width > 0 ) {
                    // Account for tabstops in current width
                    new_line_width -= m_charinfo[i].width; // remove the tab glyph width just added
                    int nb_tabstops = new_line_width / tabstop_width; // tabstops passed by
                    nb_tabstops++; // next tabstop
                    new_line_width = nb_tabstops * tabstop_width; // update current width up to that tabstop
                }
            }
            bool exceeding = new_line_width > targeted_width;
            // printf("%x %d %x %x\n", m_text[i], m_charinfo[i].width, flags, flags & CHAR_MUST_BREAK_AFTER);
            if ( flags & CHAR_CAN_WRAP_AFTER || flags & CHAR_MUST_BREAK_AFTER ) {
                if ( flags & CHAR_SKIP_ON_BREAK ) {
                    // line_width and i-1 fitted if we are here
                    candidate_line_width = line_width;
                    candidate_end = i > start ? i-1 : start;
                    next_line_start_offset = i+1;
                    candidate_is_soft_hyphen = false;
                }
                else if ( m_text[i] == SOFTHYPHEN_CHAR ) {
                    bool avoid = false;
                    if ( !exceeding && expansion_pct_rather_than_hyphen > 0 ) {
                        // We consider a soft-hyphen a candidate only if:
                        // - the previous candidate is not a soft-hyphen, and its width with all
                        //   spaces expanded by this percent would be exceeding (meaning we will
                        //   be fine with this candidate and justification will expand the spaces
                        //   but not too much)
                        // - or previous candidate is a soft-hyphen, and as we have already
                        //   started hyphenating, we don't need to avoid a better one.
                        if ( !candidate_is_soft_hyphen &&
                                candidate_line_width + extendable_width * expansion_pct_rather_than_hyphen / 100 >= targeted_width ) {
                            avoid = true;
                        }
                    }
                    // A soft-hyphen has a width of 0. But if we end this line on it,
                    // it should be rendered as a real hyphen with a width.
                    // So, to consider it a candidate for end, be sure we still won't
                    // exceed the targeted width when it is replaced.
                    if ( !exceeding && !avoid ) {
                        int hyphen_width = getHyphenWidth();
                        exceeding = new_line_width + hyphen_width > targeted_width;
                        if ( !exceeding ) {
                            // If we really end this line with this, the line width will include
                            // a visible hyphen (but we don't touch line_width / new_line_width,
                            // measured with the 0-width softhyphen, which will be used when
                            // processing next chars).
                            candidate_line_width = new_line_width + hyphen_width;
                            candidate_end = i;
                            next_line_start_offset = i+1;
                            candidate_is_soft_hyphen = true;
                        }
                    }
                }
                else { // CJK char, or non-last space in a sequence of consecutive spaces
                    if ( !exceeding ) {
                        candidate_line_width = new_line_width;
                        candidate_end = i;
                        next_line_start_offset = i+1;
                        candidate_is_soft_hyphen = false;
                    }
                }
                if ( flags & CHAR_MUST_BREAK_AFTER ) {
                    forced_break = true;
                    break;
                }
            }
            // todo: deal with non-last spaces among consecutive spaces
            // (CHAR_SKIP_ON_BREAK but !CHAR_CAN_WRAP_AFTER). When at end
            // of line, we should keep them when editing text, but text
            // justification should ignore them.
            if ( exceeding ) {
                break;
            }
            line_width = new_line_width;
            if ( flags & CHAR_CAN_EXTEND_WIDTH ) {
                extendable_width += m_charinfo[i].width;
            }
            i += 1;
            // printf("%d < %d && %d <= %d ?\n", i, m_length, line_width, targeted_width);
        }
        bool can_be_justified = true;
        bool no_allowed_break_met = false;
        if ( forced_break ) {
            can_be_justified = false;
            if ( i==start ) { // \n at start: empty line with no glyph
                candidate_end = start - 1; // TextBoxWidget does that on standalone newlines
                candidate_line_width = 0;
            }
        }
        else if ( candidate_end < 0 || i == m_length ) {
            // Excess but No CAN_/MUST_BREAK found, or end of text
            candidate_end = i-1;
            candidate_line_width = line_width;
            next_line_start_offset = i;
            if ( i == m_length ) {
                can_be_justified = false; // no justification on last line
            }
            else {
                no_allowed_break_met = true;
            }
        }
        // We could have used some indirection to make that more
        // generic, but let's push a table suitable to be added
        // directly to TextBoxWidget.vertical_string_list
        lua_createtable(m_L, 0, 5); // 5 hash fields for sure

        lua_pushstring(m_L, "offset");
        lua_pushinteger(m_L, start+1); // (Lua indices start at 1)
        lua_rawset(m_L, -3);

        lua_pushstring(m_L, "end_offset");
        lua_pushinteger(m_L, candidate_end+1); // (Lua indices start at 1)
        lua_rawset(m_L, -3);

        lua_pushstring(m_L, "can_be_justified");
        lua_pushboolean(m_L, can_be_justified);
        lua_rawset(m_L, -3);

        lua_pushstring(m_L, "width");
        lua_pushinteger(m_L, candidate_line_width);
        lua_rawset(m_L, -3);

        lua_pushstring(m_L, "targeted_width");
        lua_pushinteger(m_L, targeted_width);
        lua_rawset(m_L, -3);

        if ( no_allowed_break_met ) {
            lua_pushstring(m_L, "no_allowed_break_met");
            lua_pushboolean(m_L, true);
            lua_rawset(m_L, -3);
        }

        if ( has_tabs ) {
            lua_pushstring(m_L, "has_tabs");
            lua_pushboolean(m_L, true);
            lua_rawset(m_L, -3);
        }

        if ( next_line_start_offset >= 0 && next_line_start_offset < m_length ) {
            // next_start_offset is to be nil if end of text
            lua_pushstring(m_L, "next_start_offset");
            lua_pushinteger(m_L, next_line_start_offset+1); // (Lua indices start at 1)
            lua_rawset(m_L, -3);
        }
        else if ( forced_break && next_line_start_offset == m_length ) {
            lua_pushstring(m_L, "hard_newline_at_eot");
            lua_pushboolean(m_L, true);
            lua_rawset(m_L, -3);
        }
    }

    // Based on crengine/src/lvfntman.cpp drawTextString() with _kerningMode == KERNING_MODE_HARFBUZZ
    // and crengine/src/lvtextfm.cpp addLine()
    // Changes:
    // - we don't need to re-order the original m_text/m_charinfo: Harfbuzz will work
    //   on it in logical order, and we'll give it segments of consecutive chars in
    //   the same level
    void shapeLine(int start, int end, int idx_to_substitute_with_ellipsis=-1) {
        // We may substitute a char from text with an ellipsis or a real hyphen.
        // We'll backup and restore the original item from m_text and m_charinfo when done.
        int idx_substituted = -1;
        uint32_t orig_idx_char;
        unsigned short orig_idx_charinfo_flags; // .width is not used, no need to update it
        FriBidiCharType orig_idx_bidi_ctype = 0;
        FriBidiLevel orig_idx_bidi_level = 0;
        // We may have to substitute a second char (ZWJ + Eliipsis)
        int idx2_substituted = -1;
        uint32_t orig_idx2_char;
        unsigned short orig_idx2_charinfo_flags; // .width is not used, no need to update it
        FriBidiCharType orig_idx2_bidi_ctype = 0;
        FriBidiLevel orig_idx2_bidi_level = 0;

        if ( idx_to_substitute_with_ellipsis >= 0 && idx_to_substitute_with_ellipsis < m_length ) {
            // If the char we're substituting has "unsafe to break (from previous char)", there
            // may be some kerning between these chars (which is not an issue), or it could be
            // some arabic (or other script) char: the previous char (that we are not replacing)
            // may have an arabic initial or medial form because it is not final; when replacing
            // the next one with an ellipsis, it could get an isolated or final form, which could
            // change the meaning of the truncated word, or make it longer (and have the ellipsis
            // overflowing the target width).
            // To avoid this, we need to add a ZERO WIDTH JOINER before the ellipsis (we hope
            // this won't cause any issue with other scripts or occurences of "unsafe to break").
            // (All this applies similarly with an ellipsis at start, considering the next char.)
            bool ellipsis_at_end = idx_to_substitute_with_ellipsis == end-1 && end-2 >= start;
            bool ellipsis_at_start = idx_to_substitute_with_ellipsis == start && start+1 <= end-1;
            int idx_to_mimic_bidi = -1;
            int idx_to_substitute_with_zwj = -1;
            if ( ellipsis_at_end ) {
                // Set the bidi level of our ellipsis (and our zwj) to be the same as the
                // neighbour we keep, so it's not moved away from it
                idx_to_mimic_bidi = idx_to_substitute_with_ellipsis - 1;
                if ( m_charinfo[idx_to_substitute_with_ellipsis].flags & CHAR_IS_UNSAFE_TO_BREAK_BEFORE ) {
                    idx_to_substitute_with_zwj = idx_to_substitute_with_ellipsis;
                    idx_to_substitute_with_ellipsis = idx_to_substitute_with_ellipsis + 1;
                    end = end + 1; // include that additional replaced char in the segment to shape
                    // We made sure to have all our buffers be m_length+1, so we can hack one slot
                    // away from m_length if idx_to_substitute_with_ellipsis = end-1 = m_length-1
                }
            }
            else if ( ellipsis_at_start ) {
                idx_to_mimic_bidi = idx_to_substitute_with_ellipsis + 1;
                if ( m_charinfo[idx_to_mimic_bidi].flags & CHAR_IS_UNSAFE_TO_BREAK_BEFORE ) {
                    // Unlike when at end, we don't have a slot to add both the ellipsis
                    // and a zwj if start=0, so don't add it (this is rather rarely used
                    // by frontend, so we should be fine).
                    if ( idx_to_substitute_with_ellipsis > 0 ) {
                        idx_to_substitute_with_zwj = idx_to_substitute_with_ellipsis;
                        idx_to_substitute_with_ellipsis = idx_to_substitute_with_ellipsis - 1;
                        start = start - 1;
                    }
                }
            }
            else {
                // Standalone ellipsis: just substitute it, nothing else special to do
            }

            // Substitute the ellipsis
            idx_substituted = idx_to_substitute_with_ellipsis;
            orig_idx_char = m_text[idx_substituted];
            orig_idx_charinfo_flags = m_charinfo[idx_substituted].flags;
            m_text[idx_substituted] = ELLIPSIS_CHAR;
            m_charinfo[idx_substituted].flags &= ~CHAR_CAN_EXTEND_WIDTH;
            m_charinfo[idx_substituted].flags &= ~CHAR_CAN_EXTEND_WIDTH_FALLBACK;
            m_charinfo[idx_substituted].flags &= ~CHAR_SCRIPT_CHANGE; // ellipsis is script neutral
                                                // Looks like we can keep all other flags as is
            if ( m_has_bidi ) {
                // Be sure UAX#9 rules I1, I2, L1 to L4 don't move the ellipsis away from its neighbour
                orig_idx_bidi_ctype = m_bidi_ctypes[idx_substituted];
                orig_idx_bidi_level = m_bidi_levels[idx_substituted];
                m_bidi_levels[idx_substituted] = m_bidi_levels[idx_to_mimic_bidi];
                // Also get the real bidi type of our ellipsis (if it is replacing a space,
                // we don't want it to be FRIBIDI_MASK_WS as fribidi_reorder_line() could
                // then move it at start or end in visual order)
                fribidi_get_bidi_types((const FriBidiChar*)(m_text+idx_substituted), 1,
                                         (FriBidiCharType*)(m_bidi_ctypes+idx_substituted));
            }

            // Substitute the zwj if any
            if ( idx_to_substitute_with_zwj >= 0 ) {
                idx2_substituted = idx_to_substitute_with_zwj;
                orig_idx2_char = m_text[idx2_substituted];
                orig_idx2_charinfo_flags = m_charinfo[idx2_substituted].flags;
                m_text[idx2_substituted] = ZERO_WIDTH_JOINER_CHAR;
                m_charinfo[idx2_substituted].flags &= ~CHAR_CAN_EXTEND_WIDTH;
                m_charinfo[idx2_substituted].flags &= ~CHAR_CAN_EXTEND_WIDTH_FALLBACK;
                m_charinfo[idx2_substituted].flags &= ~CHAR_SCRIPT_CHANGE;
                if ( m_has_bidi ) {
                    orig_idx2_bidi_ctype = m_bidi_ctypes[idx2_substituted];
                    orig_idx2_bidi_level = m_bidi_levels[idx2_substituted];
                    m_bidi_levels[idx2_substituted] = m_bidi_levels[idx_to_mimic_bidi];
                    fribidi_get_bidi_types((const FriBidiChar*)(m_text+idx2_substituted), 1,
                                             (FriBidiCharType*)(m_bidi_ctypes+idx2_substituted));
                }
            }
        }
        else if ( m_text[end-1] == SOFTHYPHEN_CHAR ) {
            // If the last char in logical order is a soft hyphen, we had the line cut
            // here and we should show a real hyphen. This is also what we have to do
            // if this logical end is not the visual end (a LTR word hyphenated among
            // RTL text may happen in the middle of a line, and the hyphen should show
            // there).
            idx_substituted = end-1;
            orig_idx_char = m_text[idx_substituted];
            orig_idx_charinfo_flags = m_charinfo[idx_substituted].flags;
            m_text[idx_substituted] = REALHYPHEN_CHAR;
            m_charinfo[idx_substituted].flags &= ~CHAR_SCRIPT_CHANGE; // have it script neutral
            if ( m_has_bidi ) {
                // Mostly as done above for the ellipsis
                orig_idx_bidi_ctype = m_bidi_ctypes[idx_substituted];
                orig_idx_bidi_level = m_bidi_levels[idx_substituted];
                // Be sure the real hyphen has the bidi level of its preceding character
                if ( idx_substituted > 0 )
                    m_bidi_levels[idx_substituted] = m_bidi_levels[idx_substituted-1];
                // Looks like we can't keep the bidi type (control char, boundary neutral)
                // of the soft hyphen, as it could be forwarded to start/end of line.
                // We could pick the type of the previous char, but it could be anything.
                // It may be safer to get the bidi type of the real hyphen (European
                // Number Separator), even if it is ambiguous: the BiDi algo may just do
                // the right/best thing with it.
                fribidi_get_bidi_types((const FriBidiChar*)(m_text+idx_substituted), 1,
                                         (FriBidiCharType*)(m_bidi_ctypes+idx_substituted));
            }
        }

        // If m_has_bidi, we need the help of fribidi to visually reorder
        // the text, before feeding segments (of possible different
        // directions) to Harfbuzz.
        //
        // From fribidi documentation:
        //   fribidi_reorder_line() reorders the characters in a line of text
        //   from logical to final visual order. Note:
        //   - the embedding levels may change a bit
        //   - the bidi types and embedding levels are not reordered
        //   - last parameter is a map of string indices which is reordered to
        //     reflect where each glyph ends up
        //
        // For re-ordering, we need some temporary buffer.
        // We use a static buffer of a small size for shaping each line.
        // (4096, if some glyphs spans 4 composing unicode codepoints, would
        // make 1000 glyphs, which with a small font of width 4px, would
        // allow them to be displayed on a 4000px screen.
        // Increase that if not enough.)
        static FriBidiStrIndex bidi_indices_map[MAX_LINE_CHARS];
                // Map of string indices which is reordered to reflect where each
                // glyph ends up. Note that fribidi will access it starting
                // from 0 (and not from 'start'): this would need us to allocate
                // it the size of the full m_text (instead of MAX_LINE_CHARS)!
                // But we can trick that by providing a fake start address,
                // shifted by 'start' (which is ugly and could cause a segfault
                // if some other part than [start:end] would be accessed, but
                // we know fribid doesn't - by contract as it shouldn't reorder
                // any other part except between start:end).

        int len = end - start;
        if ( len > MAX_LINE_CHARS ) {
            // Show a warning and truncate to avoid a segfault.
            printf("XTEXT WARNING: shapeLine text too wide, truncating (%d>%d)\n", end-start, MAX_LINE_CHARS);
            end = start + MAX_LINE_CHARS;
            len = MAX_LINE_CHARS;
        }

        int nb_glyphs = 0;
        bool do_straight_shaping = true;

        if ( m_has_bidi ) {
            // The paragraph direction (set or detected if m_auto_para_direction=true)
            // has been flagged on all chars part of that paragraph, so it's the same
            // for all chars part of this line.
            // We need to use the correct one for the visual re-ordering (on a full RTL
            // line, a sentence final period would be on the left of line only if para
            // direction is RTL - while it should be on the right if para direction
            // is LTR, even if the line is only made of RTL letters).
            bool para_direction_rtl = m_charinfo[start].flags & CHAR_PARA_IS_RTL;
            FriBidiParType para_bidi_type = para_direction_rtl ? FRIBIDI_PAR_RTL : FRIBIDI_PAR_LTR;

            for ( int i=start; i<end; i++ ) {
                bidi_indices_map[i-start] = i;
            }
            FriBidiStrIndex * _virtual_bidi_indices_map = bidi_indices_map - start;
            FriBidiFlags bidi_flags = 0;
                // We're not using bidi_flags=FRIBIDI_FLAG_REORDER_NSM (which is mostly
                // needed for code drawing the resulting reordered result) as it would
                // mess with our indices map, and the final result would be messy.
            int max_level = fribidi_reorder_line(bidi_flags, m_bidi_ctypes, end-start, start,
                                para_bidi_type, m_bidi_levels, NULL, _virtual_bidi_indices_map);

            if ( max_level > 1 ) {
                do_straight_shaping = false;
                // We must do multiple individual shapings of segments of chars with
                // the same level.
                // We iterate over the chars in visual order, and attempt to find segments
                // of consecutive original indices, that we shape individually.
                int v = 0; // index in bidi_indices_map (visual order)
                // Indices prefixed with t_ are indices (in logical order) in m_text, m_charinfo, m_bidi_levels
                int t = bidi_indices_map[v];
                int t_prev = t;
                int t_start = t; // start of an individual segment to shape
                int t_end;       // end of an individual segment to shape
                FriBidiLevel last_bidi_level = m_bidi_levels[t];
                FriBidiLevel new_bidi_level;
                // We also need to shape when Unicode script changes
                hb_unicode_funcs_t* unicode_funcs = hb_unicode_funcs_get_default();
                hb_script_t prev_script = HB_SCRIPT_COMMON;

                while ( v < len ) {
                    v++;
                    t = v<len ? bidi_indices_map[v] : t_prev;
                    new_bidi_level = v<len ? m_bidi_levels[t] : last_bidi_level;
                    // On bidi level change and at end of visual order, but also if any
                    // index shift larger than +/- 1 among text original indices in a same
                    // level (this happens), or when script changes: shape previous segment.
                    bool is_segment_rtl = FRIBIDI_LEVEL_IS_RTL(last_bidi_level);
                    bool process_segment = false;
                    if ( new_bidi_level != last_bidi_level || v == len ) {
                        process_segment = true;
                    }
                    else {
                        if ( is_segment_rtl ) {
                            // We should see original text indices linearly decreasing
                            if ( t != t_prev-1 ) {
                                process_segment = true;
                                printf("XTEXT WARNING: index skip in same bidi RTL level (%d) %d -> %d\n", last_bidi_level, t_prev, t);
                            }
                        }
                        else {
                            // We should see original text indices linearly increasing
                            if ( t != t_prev+1 ) {
                                process_segment = true;
                                printf("XTEXT WARNING: index skip in same bidi LTR level (%d) %d -> %d\n", last_bidi_level, t_prev, t);
                            }
                        }
                        if ( !process_segment ) {
                            // Also check if there is a script change at this position
                            // With the bidi re-ordering, we need to re-detect that as we
                            // can't trust m_charinfo.flags' CHAR_SCRIPT_CHANGE anymore.
                            hb_script_t script = hb_unicode_script(unicode_funcs, m_text[t]);
                            if ( script != HB_SCRIPT_COMMON && script != HB_SCRIPT_INHERITED &&
                                                               script != HB_SCRIPT_UNKNOWN ) {
                                if ( prev_script != HB_SCRIPT_COMMON && script != prev_script ) {
                                    process_segment = true;
                                }
                                prev_script = script;
                            }

                        }
                    }
                    if ( process_segment ) {
                        int hints = 0;
                        if ( is_segment_rtl ) {
                            hints |= HINT_DIRECTION_IS_RTL;
                            // Harfbuzz expects RTL text in logical order, and will do itself
                            // the reordering for the final glyphs. So, in RTL, t_start (in visual
                            // order) should be greater than our current ending t_prev
                            if (t_start < t_prev)
                                printf("XTEXT WARNING: invalid RTL segment order %d -> %d\n", t_start, t_prev);
                            t_end = t_start+1;
                            t_start = t_prev;
                        }
                        else {
                            if (t_start > t_prev)
                                printf("XTEXT WARNING: invalid LTR segment order %d -> %d\n", t_start, t_prev);
                            t_end = t_prev+1;
                        }
                        if ( m_charinfo[t_start].flags & CHAR_IS_PARA_START )
                            hints |= HINT_BEGINS_PARAGRAPH;
                        if ( m_charinfo[t_end-1].flags & CHAR_IS_PARA_END )
                            hints |= HINT_ENDS_PARAGRAPH;
                        shapeSegment(0, t_start, t_end, hints, nb_glyphs);
                        t_start = t;
                        last_bidi_level = new_bidi_level;
                        prev_script = HB_SCRIPT_COMMON;
                    }
                    t_prev = t;
                }
            }
        }

        if ( do_straight_shaping ) {
            if ( m_has_multiple_scripts ) { // Multiple LTR segments
                int t_start = start;
                for ( int i=start; i<=end; i++ ) {
                    if ( i > t_start && (i == end || m_charinfo[i].flags & CHAR_SCRIPT_CHANGE) ) {
                        int hints = 0;
                        if ( m_charinfo[t_start].flags & CHAR_IS_PARA_START )
                            hints |= HINT_BEGINS_PARAGRAPH;
                        if ( m_charinfo[i-1].flags & CHAR_IS_PARA_END )
                            hints |= HINT_ENDS_PARAGRAPH;
                        shapeSegment(0, t_start, i, hints, nb_glyphs);
                        t_start = i;
                    }
                }
            }
            else { // Simple, only one LTR segment
                int hints = 0;
                if ( m_charinfo[start].flags & CHAR_IS_PARA_START )
                    hints |= HINT_BEGINS_PARAGRAPH;
                if ( m_charinfo[end-1].flags & CHAR_IS_PARA_END )
                    hints |= HINT_ENDS_PARAGRAPH;
                shapeSegment(0, start, end, hints, nb_glyphs);
            }
        }

        // todo: do something about spaces at end? may be, just mark them
        // and provide a width_without_trailing_spaces, so text justification
        // can ignore them.

        // Restore the char(s) (and their properties) that we replaced
        if ( idx_substituted >=0 ) {
            m_text[idx_substituted] = orig_idx_char;
            m_charinfo[idx_substituted].flags = orig_idx_charinfo_flags;
            if ( m_has_bidi ) {
                m_bidi_ctypes[idx_substituted] = orig_idx_bidi_ctype;
                m_bidi_levels[idx_substituted] = orig_idx_bidi_level;
            }
        }
        if ( idx2_substituted >=0 ) {
            m_text[idx2_substituted] = orig_idx2_char;
            m_charinfo[idx2_substituted].flags = orig_idx2_charinfo_flags;
            if ( m_has_bidi ) {
                m_bidi_ctypes[idx2_substituted] = orig_idx2_bidi_ctype;
                m_bidi_levels[idx2_substituted] = orig_idx2_bidi_level;
            }
        }

        // Convert out s_shape_result to a Lua array.
        // We will add some global metrics as table keys/values.
        int total_advance = 0;
        int nb_can_extend = 0;
        int nb_can_extend_fallback = 0;
        bool has_tabs = false;

        lua_createtable(m_L, nb_glyphs, 3); // array of glyphs, pre-sized
        for(int i = 0; i < nb_glyphs; i++) {
            xtext_shapeinfo_t * s = &s_shape_result[i];

            total_advance += s->x_advance;
            if (s->can_extend)
                nb_can_extend++;
            if (s->can_extend_fallback)
                nb_can_extend_fallback++;

            lua_createtable(m_L, 0, 11); // key/value table of info about a single glyph, at least 11 fields

            lua_pushstring(m_L, "font_num");
            lua_pushinteger(m_L, s->font_num);
            lua_rawset(m_L, -3);

            lua_pushstring(m_L, "glyph");
            lua_pushinteger(m_L, s->glyph);
            lua_rawset(m_L, -3);

            lua_pushstring(m_L, "text_index");
            lua_pushinteger(m_L, s->text_index + 1); // (Lua indices start at 1)
            lua_rawset(m_L, -3);

            lua_pushstring(m_L, "x_advance");
            lua_pushinteger(m_L, s->x_advance);
            lua_rawset(m_L, -3);

            lua_pushstring(m_L, "x_offset");
            lua_pushinteger(m_L, s->x_offset);
            lua_rawset(m_L, -3);

            lua_pushstring(m_L, "y_offset");
            lua_pushinteger(m_L, s->y_offset);
            lua_rawset(m_L, -3);

            lua_pushstring(m_L, "is_rtl");
            lua_pushboolean(m_L, s->is_rtl);
            lua_rawset(m_L, -3);

            if ( m_has_bidi ) {
                lua_pushstring(m_L, "bidi_level");
                lua_pushinteger(m_L, m_bidi_levels[s->text_index]);
                lua_rawset(m_L, -3);
            }

            lua_pushstring(m_L, "is_cluster_start");
            lua_pushboolean(m_L, s->is_cluster_start);
            lua_rawset(m_L, -3);

            lua_pushstring(m_L, "cluster_len");
            lua_pushinteger(m_L, s->cluster_len);
            lua_rawset(m_L, -3);

            lua_pushstring(m_L, "can_extend");
            lua_pushboolean(m_L, s->can_extend);
            lua_rawset(m_L, -3);

            lua_pushstring(m_L, "can_extend_fallback");
            lua_pushboolean(m_L, s->can_extend_fallback);
            lua_rawset(m_L, -3);

            if ( s->is_tab ) {
                lua_pushstring(m_L, "is_tab");
                lua_pushboolean(m_L, true);
                lua_rawset(m_L, -3);
                has_tabs = true;
            }

            lua_rawseti(m_L, -2, i+1); // add table to array (Lua indices start at 1)
        }

        // Add some global line metrics as keys/values
        lua_pushstring(m_L, "width");
        lua_pushinteger(m_L, total_advance);
        lua_rawset(m_L, -3);

        lua_pushstring(m_L, "nb_can_extend");
        lua_pushinteger(m_L, nb_can_extend);
        lua_rawset(m_L, -3);

        lua_pushstring(m_L, "nb_can_extend_fallback");
        lua_pushinteger(m_L, nb_can_extend_fallback);
        lua_rawset(m_L, -3);

        if (m_charinfo[start].flags & CHAR_PARA_IS_RTL) {
            lua_pushstring(m_L, "para_is_rtl");
            lua_pushboolean(m_L, true);
            lua_rawset(m_L, -3);
        }

        if ( has_tabs ) {
            lua_pushstring(m_L, "has_tabs");
            lua_pushboolean(m_L, true);
            lua_rawset(m_L, -3);
        }

        // Note: instead of returning an array table, we could allocate
        // a shapedLine object now that we know the number of glyphs,
        // copy from the static s_shape_result and return it
        // as a userdata with __index and __gc metamethods.
        // But better to return a table and allow frontend code to
        // add some adjusted glyph metrics as keys to each table.
    }

    // Based on crengine/src/lvfntman.cpp drawTextString() with _kerningMode == KERNING_MODE_HARFBUZZ
    // and crengine/src/lvtextfm.cpp addLine()
    void shapeSegment(int font_num, int start, int end, int hints, int & nb_glyphs) {
        if ( font_num > MAX_FONT_NUM )
            return;
            // No need to add a tofu char to s_shape_result: font_num
            // should have been checked before calling us, and if
            // no fallback font, our caller shapeSegment should add
            // it itself.

        #ifdef DEBUG_SHAPE_LINE
            char indent[32];
            int n = 0;
            for (; n<font_num; n++) {
                indent[n*2] = ' ';
                indent[n*2+1] = ' ';
            }
            indent[n*2] = 0;
        #endif

        xtext_hb_font_data * hb_data = getHbFontData(font_num);
        if ( !hb_data ) // No such font (so, no more fallback font)
            return;

        FT_Activate_Size(hb_data->ft_size);

        hb_font_t *    _hb_font     = hb_data->hb_font;
        hb_buffer_t *  _hb_buffer   = hb_data->hb_buffer;
        hb_feature_t * _hb_features = hb_data->hb_features;
        int _hb_features_nb = hb_data->hb_features_nb;

        // Fill HarfBuzz buffer
        hb_buffer_clear_contents(_hb_buffer);
        // for (int i = start; i < end; i++) {
        //     hb_buffer_add(_hb_buffer, (hb_codepoint_t)(m_text[i]), i);
        // }
        int extra = (end > m_length) ? 1 : 0; // in case we added ZWJ+Ellipsis at end
        hb_buffer_add_codepoints(_hb_buffer, (hb_codepoint_t*)m_text, m_length+extra, start, end-start);
        hb_buffer_set_content_type(_hb_buffer, HB_BUFFER_CONTENT_TYPE_UNICODE);

        // If we are provided with direction and hints, let harfbuzz know
        if ( hints & HINT_DIRECTION_IS_RTL )
            hb_buffer_set_direction(_hb_buffer, HB_DIRECTION_RTL);
        else
            hb_buffer_set_direction(_hb_buffer, HB_DIRECTION_LTR);
        int hb_flags = HB_BUFFER_FLAG_DEFAULT; // (hb_buffer_flags_t won't let us do |= )
        if ( hints & HINT_BEGINS_PARAGRAPH )
            hb_flags |= HB_BUFFER_FLAG_BOT;
        if ( hints & HINT_ENDS_PARAGRAPH )
            hb_flags |= HB_BUFFER_FLAG_EOT;
        hb_buffer_set_flags(_hb_buffer, (hb_buffer_flags_t)hb_flags);

        // If we got a specified language or a default one, let harfbuzz know
        if ( m_lang )
            hb_buffer_set_language(_hb_buffer, m_hb_language);
        else if ( default_lang )
            hb_buffer_set_language(_hb_buffer, default_lang_hb_language);

        // Let HB guess what's not been set (script, direction, language)
        hb_buffer_guess_segment_properties(_hb_buffer);
        // printf("HBlanguage: %s\n", hb_language_to_string(hb_buffer_get_language(_hb_buffer)));

        // Shape
        hb_shape(_hb_font, _hb_buffer, _hb_features, _hb_features_nb);

        // If direction is RTL, hb_shape() has reversed the order of the glyphs, so
        // they are in visual order and ready to be iterated and drawn. So,
        // we do not revert them, unlike in measureSegment().
        bool is_rtl = hb_buffer_get_direction(_hb_buffer) == HB_DIRECTION_RTL;

        int glyph_count = hb_buffer_get_length(_hb_buffer);
        hb_glyph_info_t *     glyph_info = hb_buffer_get_glyph_infos(_hb_buffer, 0);
        hb_glyph_position_t * glyph_pos  = hb_buffer_get_glyph_positions(_hb_buffer, 0);

        #ifdef DEBUG_SHAPE_LINE
            printf("%sSLHB >>> shapeSegment %d>%d is_rtl=%d [font#%d]\n",
                                    indent, start, end, is_rtl, font_num);
            for (int i = 0; i < (int)glyph_count; i++) {
                char glyphname[32];
                hb_font_get_glyph_name(_hb_font, glyph_info[i].codepoint, glyphname, sizeof(glyphname));
                printf("%sSLHB g%d c%d(=t:%x) [%x %s]\tadvance=(%d,%d)", indent, i, glyph_info[i].cluster,
                            m_text[glyph_info[i].cluster], glyph_info[i].codepoint, glyphname,
                            FONT_METRIC_TO_PX(glyph_pos[i].x_advance), FONT_METRIC_TO_PX(glyph_pos[i].y_advance));
                if (glyph_pos[i].x_offset || glyph_pos[i].y_offset)
                    printf("\toffset=(%d,%d)", FONT_METRIC_TO_PX(glyph_pos[i].x_offset), FONT_METRIC_TO_PX(glyph_pos[i].y_offset));
                printf("\n");
            }
            printf("%sSLHB ---\n", indent);
        #endif

        // We want to do just like in measureSegment(): drawing found glyphs with
        // this font, and .notdef glyphs with the fallback fonts, as a single segment,
        // once a defined glyph is found, before drawing that defined glyph.
        // The code is different from in measureSegment(), as the glyphs might be
        // inverted for RTL drawing, and we can't uninvert them. We also loop
        // thru glyphs here rather than chars.
        bool has_fallback_font = (bool) getHbFontData(font_num+1);

        // Cluster numbers may increase or decrease (if RTL) while we walk the glyphs.
        // We'll update fallback drawing text indices as we walk glyphs and clusters
        // (cluster numbers are boundaries in text indices, but it's quite tricky
        // to get right).
        int fb_t_start = start;
        int fb_t_end = end;
        int hg = 0;  // index in glyph_info/glyph_pos
        while ( hg < glyph_count ) { // hg is the start of a new cluster at this point
            bool shape_with_fallback = false;
            int hcl = glyph_info[hg].cluster;
            fb_t_start = hcl; // if fb drawing needed from this glyph: t[hcl:..]
                // /\ Logical if !is_rtl, but also needed if is_rtl and immediately
                // followed by a found glyph (so, a single glyph to draw with the
                // fallback font): = hclbad
            #ifdef DEBUG_SHAPE_LINE
                printf("%sSLHB g%d c%d: ", indent, hg, hcl);
            #endif
            int hg2 = hg;
            int hcl2 = -1; // needed when out of this 'while' to compute cluster_len if !is_rtl
            while ( hg2 < glyph_count ) {
                hcl2 = glyph_info[hg2].cluster;
                if ( hcl2 != hcl ) { // New cluster starts at hg2: we can draw hg > hg2-1
                    #ifdef DEBUG_SHAPE_LINE
                        printf("all found, ");
                    #endif
                    if ( is_rtl )
                        fb_t_end = hcl; // if fb drawing needed from next glyph: t[..:hcl]
                    break;
                }
                if ( glyph_info[hg2].codepoint != 0 || !has_fallback_font ) {
                    // Glyph found in this font, or not but we have no
                    // fallback font: we will draw the .notdef/tofu chars.
                    hg2++;
                    continue;
                }
                #ifdef DEBUG_SHAPE_LINE
                    printf("g%d c%d notdef, ", hg2, hcl2);
                #endif
                // Glyph notdef but we have a fallback font.
                // Go look ahead for a complete cluster, or segment of notdef,
                // so we can draw it all with the fallback font.
                shape_with_fallback = true;
                // We will update hg2 and hcl2 to be the last glyph of
                // a cluster/segment with notdef
                int hclbad = hcl2;
                int hclgood = -1;
                int hg3 = hg2+1;
                while ( hg3 < glyph_count ) {
                    int hcl3 = glyph_info[hg3].cluster;
                    if ( hclgood >=0 && hcl3 != hclgood ) {
                        // Found a complete cluster
                        // We can draw hg > hg2-1 with fallback font
                        #ifdef DEBUG_SHAPE_LINE
                            printf("c%d complete, need reshape up to g%d", hclgood, hg2);
                        #endif
                        if ( !is_rtl )
                            fb_t_end = hclgood; // fb drawing t[..:hclgood]
                        hg2 += 1; // set hg2 to the first ok glyph
                        break;
                    }
                    if ( glyph_info[hg3].codepoint == 0 || hcl3 == hclbad) {
                        #ifdef DEBUG_SHAPE_LINE
                            printf("g%d c%d -, ", hg3, hcl3);
                        #endif
                        // notdef, or def but part of uncomplete previous cluster
                        hcl2 = hcl3;
                        hg2 = hg3; // move hg2 to this bad glyph
                        hclgood = -1; // un'good found good cluster
                        hclbad = hcl3;
                        if ( is_rtl )
                            fb_t_start = hclbad; // fb drawing t[hclbad::..]
                        hg3++;
                        continue;
                    }
                    // Codepoint found, and we're not part of an uncomplete cluster
                    #ifdef DEBUG_SHAPE_LINE
                        printf("g%d c%d +, ", hg3, hcl3);
                    #endif
                    hclgood = hcl3;
                    hg3++;
                }
                if ( hg3 == glyph_count && hclgood >=0 ) { // last glyph was a good cluster
                    if ( !is_rtl )
                        fb_t_end = hclgood; // fb drawing t[..:hclgood]
                    hg2 += 1; // set hg2 to the first ok glyph (so, the single last one)
                    break;
                }
                if ( hg3 == glyph_count ) { // no good cluster met till end of text
                    hg2 = glyph_count; // get out of hg2 loop
                    if ( is_rtl )
                        fb_t_start = start;
                    else
                        fb_t_end = end;
                }
                break;
            }
            // Draw glyphs from hg to hg2 excluded
            if ( shape_with_fallback ) {
                #ifdef DEBUG_SHAPE_LINE
                    printf("[...]\n%sSLHB ### shaping past notdef with fallback font %d>%d ", indent, hg, hg2);
                    printf(" => %d > %d\n", fb_t_start, fb_t_end);
                #endif
                // Adjust hints
                int fb_hints = hints;
                // We must keep direction, but we should drop BOT/EOT flags
                // if this segment is not at start/end (this might be bogus
                // if the char at start or end is a space that could be drawn
                // with the main font).
                if ( fb_t_start > start )
                    fb_hints &= ~HINT_BEGINS_PARAGRAPH;
                if ( fb_t_end < end )
                    fb_hints &= ~HINT_ENDS_PARAGRAPH;
                shapeSegment(font_num+1, fb_t_start, fb_t_end, fb_hints, nb_glyphs);
                #ifdef DEBUG_SHAPE_LINE
                    printf("%sSLHB ### drawn past notdef\n[...]", indent);
                #endif
            }
            else {
                #ifdef DEBUG_SHAPE_LINE
                    printf("regular g%d>%d (cl%d>%d): ", hg, hg2, hcl, (hg2 < glyph_count ? hcl2 : end));
                #endif
                // Record shaped glyphs of this same cluster.
                // We don't request the full glyph info/metrics from Freetype
                // (frontend will do that), we just return the harfbuzz advance and
                // offsets (that will have to be added to Freetype metrics).
                for ( int i = hg; i < hg2; i++ ) {
                    if ( nb_glyphs >= MAX_LINE_GLYPHS )
                        continue; // Ignore exceeding glyph rather than segfault
                    xtext_shapeinfo_t * s = &s_shape_result[nb_glyphs++];
                    s->font_num = font_num;
                    s->glyph = glyph_info[i].codepoint;
                    s->text_index = hcl;
                    s->can_extend = (m_charinfo[hcl].flags & CHAR_CAN_EXTEND_WIDTH) ? 1 : 0;
                    s->can_extend_fallback = (m_charinfo[hcl].flags & CHAR_CAN_EXTEND_WIDTH_FALLBACK) ? 1 : 0;
                    s->is_tab = (m_charinfo[hcl].flags & CHAR_IS_TAB) ? 1 : 0;
                    s->is_rtl = is_rtl;

                    // Note that we get metrics in 1/64px here, and these are fractional
                    // pixels (not a strict multiple of 64).
                    // We can >>6 these metrics here as, when drawing, we use this advance
                    // directly and the offset are added to bitmap_left and _top which are
                    // already in pixel units (dunno if we could use metrics.horiBearingX
                    // and .horiBearingY instead in freetype.lua, so we can add do the
                    // rounding after having done the addition with HB offsets.)
                    s->x_advance = FONT_METRIC_TO_PX(glyph_pos[i].x_advance);
                    s->x_offset = FONT_METRIC_TO_PX(glyph_pos[i].x_offset);
                    s->y_offset = FONT_METRIC_TO_PX(glyph_pos[i].y_offset);

                    s->is_cluster_start = i == hg ? 1 : 0;
                    // What follows is tedious...
                    if ( is_rtl ) {
                        // For RTL, hcl is the text index of the right most glyph
                        // (so, the first char of the cluster in logical order)
                        // To avoid having to carry the previous cluster index
                        // (here and across calls to shapeSegment with a fallback
                        // font), we can just go peek at the previous shape result
                        // that we added in this shapeSegment() call.
                        if ( i == hg ) { // First (or single) glyph of this cluster
                            if ( hg == 0 ) { // First glyph of segment
                                // If start=0 and end=10, last text index is 9
                                // If visual line starts with "A" as a single cluster, hcl=9
                                // If visual line starts with "AB" as a single cluster, hcl=8
                                s->cluster_len = end - hcl;
                            }
                            else { // Previous glyph seen, part of a previous cluster, added to s_shape_result.
                                // (All glyphs from previous cluster have the same ->text_index, so
                                // we can get the previous one even if not the first in the cluster.)
                                s->cluster_len = s_shape_result[nb_glyphs-2].text_index - hcl;
                                    // (-2 as we did nb_glyphs++ above, and we want the one before us)
                            }
                        }
                        else { // Follow-up glyph in same cluster as previous glyph
                            // Just grab s->cluster_len from previous glyph
                            s->cluster_len = s_shape_result[nb_glyphs-2].cluster_len;
                        }
                    }
                    else {
                        // For LTR, we already got as hcl2 the cluster number of the next cluster
                        if ( hcl2 > hcl ) {
                            s->cluster_len = hcl2 - hcl;
                        }
                        else if ( hcl2 == hcl ) { // hcl2 was not updated when hcl is last cluster of segment
                            // If line ends with "a" as a single cluster, hcl=end-1: len should be 1
                            // If line ends with "ab" as a single cluster, hcl=end-2: len should be 2
                            s->cluster_len = end - hcl;
                        }
                        else {
                            printf("XTEXT WARNING: invalid clusters order in LTR segment %d !< %d\n", hcl, hcl2);
                            s->cluster_len = 1; // just in case
                        }
                    }
                }
                // Whole cluster shaped
            }
            hg = hg2;
            #ifdef DEBUG_SHAPE_LINE
                printf("\n");
            #endif
        }
    }

    // Get the offset in text, from which we can make a segment to
    // the end of string with the specified target_width.
    // (Could be named makeLineFromEnd(max_width), but we don't follow line
    // breaking rules, and this would allow making only one line: the last.)
    void getSegmentFromEnd(int targeted_width) {
        int last_cluster_start = 0;
        int last_width = 0;
        int width = 0;
        for ( int i=m_length-1; i>=0; i--) {
            width += m_charinfo[i].width;
            int flags = m_charinfo[i].flags;
            if ( flags & CHAR_IS_CLUSTER_TAIL )
                continue;
            // Start of cluster (we have walked its tail chars
            // of width 0, that would have fitted).
            if (width > targeted_width) // The whole cluster does not fit
                break;
            // This cluster fits
            last_width = width;
            last_cluster_start = i;
        }
        lua_pushinteger(m_L, last_cluster_start+1); // start offset (Lua indices start at 1)
        lua_pushinteger(m_L, last_width); // segment width
    }

    // Get (as a single UTF-8 string) the segment of m_text
    void getText(int start, int end) {
        // FriBiDi provides a unicode to UTF-8 conversion function, so use it.
        // Let's be cheap and not count the nb of bytes really needed to store the
        // UTF-8 encoding of each Unicode codepoint: go allocate for the max (4).
        int len = end - start;
        char * s_utf8 = (char *)malloc(len * 4*sizeof(char) + 1);
        fribidi_unicode_to_charset(FRIBIDI_CHAR_SET_UTF8, m_text+start, len, s_utf8);
        lua_pushstring(m_L, s_utf8);
        free(s_utf8);
    }

    // Get (as a single UTF-8 string) the segment of m_text, extended to include
    // the full words that may be cut at boundaries (start, end).
    void getSelectedWords(int start, int end, int context) {
        // Not much documentation about libunibreak word breaking,
        // some insight in:
        //  http://www.unicode.org/reports/tr29/tr29-25.html
        //  https://github.com/adah1972/libunibreak/issues/16
        //  https://stackoverflow.com/questions/40536156/cannot-distinguish-single-character-words-with-libunibreak/
        int ctx_start = start - context;
        if ( ctx_start < 0 )
            ctx_start = 0;
        int ctx_end = end + context;
        if ( ctx_end > m_length )
            ctx_end = m_length;
        int len = ctx_end - ctx_start;
        int offset = ctx_start;
        char * breaks = (char *)malloc(len * sizeof(*breaks));
        init_wordbreak();
        set_wordbreaks_utf32(m_text+ctx_start, len, m_lang ? m_lang : default_lang, breaks);
        #if 0
            for (int i=ctx_start; i < ctx_end; i++) {
                if (i == start) printf("[[[");
                printf("%c%d ", m_text[i], breaks[i-offset]);
                if (i == end) printf("]]]");
            }
            printf("\n");
        #endif

        // A brk flag set for index [i] says about a break between chars at [i] and [i+1]
        // (so, it is set to WORDBREAK_BREAK on the index of the last char of a word,
        // and on the index of the char preceeding the first char of a word).
        // WORDBREAK_BREAK is set on word break boundaries, which does
        // not help to distinguish if some char is a word or a space or
        // some punctuation:
        // For a single char word (a letter surrounded by spaces), the indices
        // for the preceeding space, the letter, and the following space are all
        // set to WORDBREAK_BREAK...
        // We would need to look at the char properties to really find out.
        // For now, we just don't: the following seems to work fine, it may just
        // grab some additional space or punctuation when our start or end indices
        // happen to be on the last char of a word, which is good enough as our
        // frontend code strips punctuation and spaces (but may be not all
        // punctuations in obscure scripts...)
        int wstart = start > 0 ? start-1 : 0;
        while ( wstart >= ctx_start ) {
            if ( breaks[wstart-offset] == WORDBREAK_BREAK ) {
                wstart++;
                break;
            }
            wstart--;
        }
        if ( wstart < 0 )
            wstart = 0;
        int wend = end;
        while ( wend < ctx_end ) {
            if ( breaks[wend-offset] == WORDBREAK_BREAK ) {
                wend++;
                break;
            }
            wend++;
        }

        // FriBiDi provides a unicode to UTF-8 conversion function, so use it.
        // Let's be cheap and not count the nb of bytes really needed to store the
        // UTF-8 encoding of each Unicode codepoint: go allocate for the max (4).
        // (As we're called to return user selected text, we shouldn't waste
        // too much - and we'll free it just below.)
        len = wend - wstart;
        char * s_utf8 = (char *)malloc(len * 4*sizeof(char) + 1);
        fribidi_unicode_to_charset(FRIBIDI_CHAR_SET_UTF8, m_text+wstart, len, s_utf8);
        lua_pushstring(m_L, s_utf8);
        #if 0
            printf("getWords: %d>%d #%s#\n", wstart, wend, s_utf8);
            lua_pushstring(m_L, ""); // prevent a dict lookup
        #endif
        free(s_utf8);
        free(breaks);
    }
};

// These static members have to be defined outside the class definition
// (otherwise: "undefined symbol" at runtime)
xtext_shapeinfo_t XText::s_shape_result[MAX_LINE_GLYPHS];
bool XText::s_libunibreak_init_done = false;


// ==============================================
// Lua wrapping functions

static int xtext_setDefaultParaDirection(lua_State *L) {
    bool direction_rtl = false;
    if (lua_isboolean(L,1)) {
        direction_rtl = lua_toboolean(L, 1);
    }
    default_para_direction_rtl = direction_rtl;
    return 0;
}

// Harfbuzz accepts BCP 47 language codes.
// See in harfbuzz/src/: gen-tag-table.py hb-ot-tag-table.hh hb-ot-name-language-static.hh hb-ot-tag.cc
// https://harfbuzz.freedesktop.narkive.com/1l03EBMh/how-to-use-locl-feature-of-noto-sans-cjk-with-harfbuzz#post3
// We'll use the same lang for libunibreak line breaking rules, which has
// some specific added rules only for: de en es fr ja ko ru zh.
// See if needed at allowing a 2nd optional parameter to specify a different
// language for libunibreak specifically (including NULL to disable the use
// of the main one).
static int xtext_setDefaultLang(lua_State *L) {
    const char * lang = luaL_checkstring(L, 1);
    default_lang = new char[strlen(lang)+1];
    strcpy(default_lang, lang);
    default_lang_hb_language = hb_language_from_string(default_lang, -1);
    return 0;
}

// Create a new XText C++ class instance and wrap it into a Lua userdata.
// Started from these examples on how to wrap a C++ class:
//  https://gist.github.com/kizzx2/1594905 XText.cpp
//  https://gist.github.com/Youka/2a6e69584672f7cb0331
static int xtext_new(lua_State *L) {
    // 1st argument should be the UTF8 string, but can be a Lua array
    // of UTF8 chars (to stay compatible with TextBoxWidget as used
    // by InputText).
    bool is_empty = true;
    size_t utf8_len = 0;
    const char * utf8_text = NULL;
    bool input_is_array = false;
    if ( lua_istable(L, 1) ) {
        input_is_array = true;
        if ( lua_objlen(L, 1) > 0 )
            is_empty = false;
    }
    else {
        utf8_text = luaL_checklstring(L, 1, &utf8_len);
        if ( utf8_len > 0 )
            is_empty = false;
    }

    // 2nd argument should be our Lua font object (face_obj), with
    // a getFallbackFont() callback.
    luaL_checktype(L, 2, LUA_TTABLE);
    lua_getfield(L, 2, XTEXT_LUA_FONT_GETFONT_CALLBACK_NAME);
    if ( !lua_isfunction(L, -1) ) {
        luaL_error(L, "provided font table lacks entry 'getFallbackFont' with a function");
    }
    // We'll set below this table as the uservalue/environment of our XText userdata,
    // so it can access and call that getFallbackFont function when needed.

    // We could add here a boolean parameter to enable/disable multiline work,
    // and avoid it when not needed (TextWidget, unlike TextBoxWidget).

    // 3rd optional boolean argument: force/auto-detect paragraph direction.
    // nil/false (default): force direction / true: auto-detect paragraph direction.
    // (If true, the para direction, default or specified via the 4th argument,
    // is used as a weak direction, otherwise as a strong direction)
    bool auto_para_direction = false;
    if (lua_isboolean(L,3)) {
        auto_para_direction = lua_toboolean(L, 3);
    }

    // 4th optional boolean argument: direction
    // nil: use default para direction (set with global setDefaultParaDirection()),
    // false: direction LTR, true: direction RTL
    bool para_direction_rtl = default_para_direction_rtl;
    if (lua_isboolean(L,4)) {
        para_direction_rtl = lua_toboolean(L, 4);
    }

    // 5th optional argument can be string a specifying the text language.
    // If not provided, the default language (set with setDefaultLang()) is used.
    const char * lang = NULL;
    if ( lua_isstring(L, 5) ) {
        lang = luaL_checkstring(L, 5);
    }

    // Create a Lua userdata to wrap a XText instance: we return it here,
    // and we'll get it as the first argument to each method call.
    XText ** udata = (XText **)lua_newuserdata(L, sizeof(XText *));
    // Tag this userdata as being a luaL_XText object, so we can check
    // it is really what these methods expect.
    luaL_getmetatable(L, XTEXT_METATABLE_NAME);
    lua_setmetatable(L, -2);

    // Set the font table (which has the getFallbackFont key/function) as the
    // uservalue (with Lua 5.2 - but fallback to environment with Lua 5.1)
    // of this new userdata.
    lua_pushvalue(L, 2); // get a copy of it on top of stack
    lua_setuservalue(L, -2);  // set it on our userdata (now at -2)

    // Instantiate a XText object, and set some of its properties.
    *udata = new XText();
    XText * xt = *udata;
    xt->m_L = L; // Each wrapping Lua method will re-set m_L with its own L.
    xt->m_para_direction_rtl = para_direction_rtl;
    xt->m_auto_para_direction = auto_para_direction;
    if (lang) {
        xt->setLanguage(lang);
    }
    if ( is_empty ) {
        xt->m_is_valid = true; // empty text is valid UTF-8
    }
    else if (input_is_array) {
        xt->setTextFromUTF8CharsLuaArray(L, 1); // table is still at 1 on stack
    }
    else {
        xt->setTextFromUTF8String(utf8_text, utf8_len);
    }

    return 1; // Return this new userdata
}

XText * check_XText(lua_State * L, int n, bool replace_with_uservalue=true, bool error_if_no_longer_usable=true) {
    // This checks that the thing at n on the stack is a correct XText
    // wrapping userdata (tagged with the "luaL_XText" metatable).
    XText * xt = *(XText **)luaL_checkudata(L, n, XTEXT_METATABLE_NAME);
    xt->m_L = L; // Replace previous m_L with this fresh one
    if ( replace_with_uservalue ) {
        // Replace (on the stack) the userdata (now that we got the object
        // from it) with its uservalue table, where we may fetch other stuff.
        lua_getuservalue(L, n);
        lua_replace(L, n);
    }
    if ( error_if_no_longer_usable && xt->m_no_longer_usable ) {
        lua_pushstring(L, "XText C instance already freed and no longer usable");
        lua_error(L);
    }
    return xt;
}

// ==============================================
// Lua wrapping methods
static int xtext_hb_font_data_destroy(lua_State *L) {
    // printf("xtext_hb_font_data_destroy called\n");
    xtext_hb_font_data * hb_data = (xtext_hb_font_data *)luaL_checkudata(L, -1, XTEXT_HB_FONT_DATA_METATABLE_NAME);
    FT_Face ft_face = hb_data->ft_size->face;
    FT_Library ft_lib = (FT_Library)ft_face->generic.data;
    int *refcount = (int *)hb_data->ft_size->generic.data;
    assert(*refcount > 0);
    if (!--*refcount) {
        free(refcount);
        FT_Done_Size(hb_data->ft_size);
        FT_Done_Face(ft_face);
        FT_Done_Library(ft_lib);
    }
    hb_font_destroy(hb_data->hb_font);
    FT_Done_Library(ft_lib);
    hb_buffer_destroy(hb_data->hb_buffer);
    if ( hb_data->hb_features )
        free(hb_data->hb_features);
    hb_data->ft_size = NULL;
    hb_data->hb_font = NULL;
    hb_data->hb_buffer = NULL;
    hb_data->hb_features = NULL;
    return 0;
}

// Called by Lua when garbage collecting: delete the object
static int XText_destroy(lua_State *L) {
    // Don't error if free() has already been called
    XText * xt = check_XText(L, 1, false, false);
    delete xt;
    return 0;
}

// Can be called before Lua garbage collection, to free possibly large malloc()'ed
// properties, while keeping the object alive until async Lua gc().
static int XText_free(lua_State *L) {
    // Don't error if free() has already been called (allow multiple calls
    // to free() by frontend widgets' :onCloseWidget() without failure)
    XText * xt = check_XText(L, 1, false, false);
    if ( !xt->m_no_longer_usable )
        xt->deallocate();
    return 0;
}

static int XText_length(lua_State *L) {
    XText * xt = check_XText(L, 1);
    lua_pushinteger(L, xt->m_length);
    return 1;
}

// Get codepoint of char at m_text[index]
// (We would have liked to have it behave as a table, but that
// would make the other methods interception complicated, and
// would add some overhead - so one has to call x:get(12)
// instead of x[12].)
static int XText_get(lua_State *L) {
    XText * xt = check_XText(L, 1);
    int index = luaL_checkint(L, 2);
    luaL_argcheck(L, index >= 1 && index <= xt->m_length, 2, "index out of range");
    index--; // Lua to C index
    // Return the unicode codepoint
    lua_pushinteger(L, xt->m_text[index]);
    return 1;
}

static int XText_is_valid(lua_State *L) {
    XText * xt = check_XText(L, 1);
    lua_pushboolean(L, xt->m_is_valid);
    return 1;
}

static int XText_hasRTL(lua_State *L) {
    XText * xt = check_XText(L, 1);
    lua_pushboolean(L, xt->m_has_rtl);
    return 1;
}

static int XText_measure(lua_State *L) {
    XText * xt = check_XText(L, 1);
    xt->measure();
    return 0;
}

static int XText_getWidth(lua_State *L) {
    XText * xt = check_XText(L, 1);
    xt->measure();
    int w = xt->m_width;
    if ( w == NOT_MEASURED )
        w = 0;
    lua_pushinteger(L, w);
    return 1;
}

static int XText_makeLine(lua_State *L) {
    XText * xt = check_XText(L, 1);
    int start = luaL_checkint(L, 2);
    luaL_argcheck(L, start >= 1 && start <= xt->m_length, 2, "index out of range");
    start--; // Lua to C index
    int width = luaL_checkint(L, 3);
    luaL_argcheck(L, width > 0, 3, "width must be strictly positive");
    bool no_line_breaking_rules = false;
    if (lua_isboolean(L,4)) {
        no_line_breaking_rules = lua_toboolean(L, 4);
    }
    int tabstop_width = 0;
    if (lua_isnumber(L,5)) {
        tabstop_width = luaL_checkint(L, 5);
    }
    int expansion_pct_rather_than_hyphen = 0;
    if (lua_isnumber(L,6)) {
        // If text is going to be justified, we can avoid small hyphenated
        // words by providing this non-zero. Ie, with 100:
        // when about to wrap on a soft hyphen, if a wrap on a previous non-hyphen
        // candidate would get justification to expand the spaces by less than 100%
        // (so, at most double width spaces), consider this expansion admissible
        // and better than this hyphen (which would probably make a small part
        // of a word hyphenated at end of this line).
        expansion_pct_rather_than_hyphen = luaL_checkint(L, 6);
    }
    xt->measure();
    xt->makeLine(start, width, no_line_breaking_rules, tabstop_width, expansion_pct_rather_than_hyphen);
    // makeLine() will have pushed onto the stack a table suitable
    // to be added to TextBoxWidget.vertical_string_list
    return 1;
}

static int XText_shapeLine(lua_State *L) {
    XText * xt = check_XText(L, 1);
    int start = luaL_checkint(L, 2);
    luaL_argcheck(L, start >= 1 && start <= xt->m_length, 2, "index out of range");
    start--; // Lua to C index
    int end = luaL_checkint(L, 3);
    luaL_argcheck(L, end >= 1 && end <= xt->m_length, 3, "index out of range");
    // end--; // Lua to C index, but we don't as end is excluded in our C code,
              // but it is expected to be included in the Lua call
    int idx_to_substitute_with_ellipsis = -1;
    if (lua_isnumber(L,4)) {
        idx_to_substitute_with_ellipsis = luaL_checkint(L, 4);
        luaL_argcheck(L, idx_to_substitute_with_ellipsis >= 1 &&
                idx_to_substitute_with_ellipsis <= xt->m_length, 4, "index out of range");
        idx_to_substitute_with_ellipsis--; // Lua to C index
    }
    xt->measure();
    xt->shapeLine(start, end, idx_to_substitute_with_ellipsis);
    // shapeLine() will have pushed a Lua table onto the stack
    return 1;
}

// Get the paragraph direction of the paragraph the char at idx is part
// of (and the one for the char at idx-1 too, as it might be useful).
// To be used with empty lines for cursor positioning, to get
// line.para_is_rtl (similar to what shapeLine() returns, but
// we can't call shapeLine() on empty lines).
// If no idx provided, get the specified (or default) direction
// used by this Xtext object.
static int XText_getParaDirection(lua_State *L) {
    XText * xt = check_XText(L, 1);
    if (!lua_isnumber(L,2)) { // no idx given
        lua_pushboolean(L, xt->m_para_direction_rtl);
        return 1;
    }
    int idx = luaL_checkint(L, 2);
    luaL_argcheck(L, idx >= 1 && idx <= xt->m_length, 2, "index out of range");
    idx--; // Lua to C index
    xt->measure();
    lua_pushboolean(L, (bool)(xt->m_charinfo[idx].flags & CHAR_PARA_IS_RTL));
    if (idx >= 1)
        lua_pushboolean(L, (bool)(xt->m_charinfo[idx-1].flags & CHAR_PARA_IS_RTL));
    else
        lua_pushnil(L);
    return 2;
}

// Get the offset in text, from which we can make a segment to
// the end of string with the specified target_width.
// (Could be named makeLineFromEnd(max_width), but we don't follow
// line breaking rules, and this allows making only one line.)
static int XText_getSegmentFromEnd(lua_State *L) {
    XText * xt = check_XText(L, 1);
    int width = luaL_checkint(L, 2);
    luaL_argcheck(L, width > 0, 2, "width must be strictly positive");
    xt->measure();
    xt->getSegmentFromEnd(width);
    // getSegmentFromEnd() will have pushed onto the stack 2 numbers:
    // the start offset, and the segment real width
    return 2;
}

// Get (as a single UTF-8 string) the segment of m_text.
static int XText_getText(lua_State *L) {
    XText * xt = check_XText(L, 1);
    int start = luaL_checkint(L, 2);
    luaL_argcheck(L, start >= 1 && start <= xt->m_length, 2, "index out of range");
    start--; // Lua to C index
    int end = luaL_checkint(L, 3);
    luaL_argcheck(L, end >= 1 && end <= xt->m_length, 3, "index out of range");
    // end--; // Lua to C index, but we don't as end is excluded in our C code,
              // but it is expected to be included in the Lua call
    xt->getText(start, end);
    // getText() will have pushed a Lua string onto the stack
    return 1;
}

// Get (as a single UTF-8 string) the segment of m_text, extended to include
// the full words that may be cut at boundaries (start, end).
static int XText_getSelectedWords(lua_State *L) {
    XText * xt = check_XText(L, 1);
    int start = luaL_checkint(L, 2);
    luaL_argcheck(L, start >= 1 && start <= xt->m_length, 2, "index out of range");
    start--; // Lua to C index
    int end = luaL_checkint(L, 3);
    luaL_argcheck(L, end >= 1 && end <= xt->m_length, 3, "index out of range");
    // end--; // Lua to C index, but we don't as end is excluded in our C code,
              // but it is expected to be included in the Lua call
    // 4th argument is the number of chars before start and after end
    // to inspect to find cut words' start/end.
    int context = luaL_checkint(L, 4);
    luaL_argcheck(L, context > 0, 3, "context must be strictly positive");
    xt->getSelectedWords(start, end, context);
    // getSelectedWords() will have pushed a Lua string onto the stack
    return 1;
}


// ==============================================
// Lua registration
static const struct luaL_Reg xtext_func[] = {
    {"setDefaultParaDirection", xtext_setDefaultParaDirection}, // false: LTR / true: RTL
    {"setDefaultLang", xtext_setDefaultLang},
    {"new", xtext_new},
    {NULL, NULL}
};

static const struct luaL_Reg xtext_meth[] = {
    {"__len", XText_length}, // so we can use #xtext
    {"get", XText_get},
    {"isValid", XText_is_valid},
    {"hasRTL", XText_hasRTL},
    {"measure", XText_measure},
    {"getWidth", XText_getWidth},
    {"makeLine", XText_makeLine},
    {"shapeLine", XText_shapeLine},
    {"getParaDirection", XText_getParaDirection},
    {"getSegmentFromEnd", XText_getSegmentFromEnd},
    {"getText", XText_getText},
    {"getSelectedWords", XText_getSelectedWords},
    { "free", XText_free },
    { "__gc", XText_destroy },
    {NULL, NULL}
};

static const struct luaL_Reg xtext_hb_font_data_meth[] = {
    { "__gc", xtext_hb_font_data_destroy },
    {NULL, NULL}
};

// Register this library as a Lua module.
// Called once, on the first 'require("libs/libkoreader-xtext")'
int luaopen_xtext(lua_State *L) {
    // Create a luaL metatable. This metatable is not exposed to Lua.
    // The "luaL_XText" label is used by luaL internally to identify things.
    luaL_newmetatable(L, XTEXT_METATABLE_NAME);

    // Set the "__index" field of the metatable to point to itself
    lua_pushstring(L, "__index");
    lua_pushvalue(L, -2); // duplicate XText metatable (which is at -2)
    lua_settable(L, -3);  // set key (at -2) and value (at -1) into table (at -3)
                          // so, meta.__index = meta itself

    // Register the C methods into the metatable we just created (which is now back at -1)
    luaL_register(L, NULL, xtext_meth);
    lua_pop(L, 1); // Get rid of that metatable

    // Create similarly a new metatable for our hb_font_data (holding
    // initialized Harfbuzz structures, so we don't have to re-init
    // it each time this font is used), that we will store as a userdata
    // into each of our Lua font object.
    luaL_newmetatable(L, XTEXT_HB_FONT_DATA_METATABLE_NAME);
    lua_pushstring(L, "__index");
    lua_pushvalue(L, -2);
    lua_settable(L, -3);
    luaL_register(L, NULL, xtext_hb_font_data_meth);
    lua_pop(L, 1);

    // Register the C library functions as module functions (this
    // sets it as a global variable with the name "xtext").
    luaL_register(L, XTEXT_LIBNAME, xtext_func);

        // To add to it some constants if needed:
        //   lua_pushinteger(L, XTEXT_PARA_DIRECTION_FORCE);
        //   lua_setfield(L, -2, "PARA_DIRECTION_FORCE");
        // See http://lua.sqlite.org/index.cgi/doc/bb4d13eba2/lsqlite3.c
        // for how to add multiple constants when there is a lot.

    return 1; // return that table
}

