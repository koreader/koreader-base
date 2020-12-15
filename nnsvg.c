// nsvg.cpp
// Lua interface to wrap nanosvg.

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <stdbool.h>

#include "nnsvg.h"
#include "blitbuffer.h"

#define NANOSVG_ALL_COLOR_KEYWORDS
#define NANOSVG_IMPLEMENTATION
#define NANOSVGRAST_IMPLEMENTATION
#include <nanosvg.h>
#include <nanosvgrast.h>

// Some names, as they should be known to Lua
// (nanosvg uses the NSVG* prefix, i.e. NSVGimage/nsvgParseFromFile,
// so let's use nn*)
#define NNSVG_LIBNAME "nnsvg"
#define NNSVG_METATABLE_NAME "luaL_nnSVGImage"

// ==============================================
// Lua wrapping functions

// Create a new NSVGimage instance from a file path or SVG data,
// and wrap it into a Lua userdata.
static int nnsvg_new(lua_State *L) {
    // First arg must be a string: a filepath, or some SVG markup
    const char * input = NULL;
    size_t len = 0;
    input = luaL_checklstring(L, 1, &len);

    // Second arg specified what the string is: by default, a filepath
    bool is_svg_data = false;
    if ( lua_isboolean(L, 2) ) {
        is_svg_data = lua_toboolean(L, 2);
    }

    // Third arg: DPI, defaults to 96
    const float dpi = (float)luaL_optnumber(L, 3, 96.0f);

    // Create a Lua userdata to wrap a NSVGimage instance: we return it here,
    // and we'll get it as the first argument to each method call.
    NSVGimage ** udata = (NSVGimage **)lua_newuserdata(L, sizeof(NSVGimage *));
    // Tag this userdata as being a luaL_nnSVGImage object, so we can check
    // it is really what these methods expect.
    luaL_getmetatable(L, NNSVG_METATABLE_NAME);
    lua_setmetatable(L, -2);

    // Get an instantiated NSVGimage struct from the parsed input
    // and store its address in our userdata
    if ( is_svg_data ) {
        *udata = nsvgParse((char*)input, "px", dpi);
    }
    else {
        *udata = nsvgParseFromFile(input, "px", dpi);
    }
    if ( !*udata ) {
        lua_pushstring(L, "Failed parsing SVG.");
        lua_error(L);
    }
    return 1; // Return this new userdata
}

NSVGimage * check_NSVGimage(lua_State * L, int n) {
    // This checks that the thing at n on the stack is a correct nnSVGImage
    // wrapping userdata (tagged with the "luaL_nnSVGImage" metatable).
    NSVGimage * image = *(NSVGimage **)luaL_checkudata(L, n, NNSVG_METATABLE_NAME);
    return image;
}

// ==============================================
// Lua wrapping methods

// Exported as :free() (to be called explicitely if we want to free
// the NSVGimage early) and as :__gc() (called by the async Lua GC).
static int nnSVGImage_free(lua_State *L) {
    NSVGimage ** udata = (NSVGimage **)luaL_checkudata(L, 1, NNSVG_METATABLE_NAME);
    // printf("nnSVGImage_free %p\n", *udata);
    if ( *udata )
        nsvgDelete(*udata);
    *udata = NULL;
    return 0;
}

// Get native width and height of SVG image
static int nnSVGImage_getSize(lua_State *L) {
    NSVGimage * image = check_NSVGimage(L, 1);
    lua_pushinteger(L, image->width);
    lua_pushinteger(L, image->height);
    return 2;
}

// Rasterize SVG image on the provided BlitBuffer (which should
// be already sized and allocated)
static int nnSVGImage_drawTo(lua_State *L) {
    NSVGimage * image = check_NSVGimage(L, 1);

    // 2nd argument should be a BlitBuffer instance
    // We expect it to be a luajit ffi cdata, but the C API does not have a #define for
    // that type. But it looks like its value is higher than the greatest LUA_T* type.
    if ( lua_type(L, 2) <= LUA_TTHREAD ) {// Higher plain Lua datatype (lua.h)
        luaL_typerror(L, -1, "BlitBuffer");
    }
    BlitBuffer * bb = (BlitBuffer*) lua_topointer(L, 2);
    // Make sure that the target bb is RGB32, because NanoSVG unconditionally outputs an RGBA pixmap.
    if ( GET_BB_TYPE(bb) != TYPE_BBRGB32 ) {
        lua_pushstring(L, "BlitBuffer BBRGB32 expected.");
        lua_error(L);
    }

    // nanosvg's rasterizer won't automatically scale the image
    // to adjust it to the target buffer w/h.
    // But it allows a scale factor that is applied to both axis
    // (so, it forces us to keep the original aspect ratio, we
    // can't have it stretch SVGs).
    // The positionning of the original (possibly scaled) SVG image
    // inside the already sized and allocated BlitBuffer has to be
    // done by caller, which may provide these optional arguments:
    const float scale_factor = (float)luaL_optnumber(L, 3, 1.0);
    const int offset_x = (int)luaL_optint(L, 4, 0);
    const int offset_y = (int)luaL_optint(L, 5, 0);

    NSVGrasterizer *rast = nsvgCreateRasterizer();
    if (rast == NULL) {
        lua_pushstring(L, "Could not init rasterizer.");
        lua_error(L);
    }
    nsvgRasterize(rast, image, offset_x, offset_y, scale_factor, bb->data, bb->w, bb->h, bb->stride);
    nsvgDeleteRasterizer(rast);
    return 0;
}

// ==============================================
// Lua registration
static const struct luaL_Reg nnsvg_func[] = {
    {"new", nnsvg_new},
    {NULL, NULL}
};

static const struct luaL_Reg nnsvg_meth[] = {
    {"getSize", nnSVGImage_getSize},
    {"drawTo", nnSVGImage_drawTo},
    { "free", nnSVGImage_free },
    { "__gc", nnSVGImage_free },
    {NULL, NULL}
};

// Register this library as a Lua module.
// Called once, on the first 'require("libs/libkoreader-nnsvg")'
int luaopen_nnsvg(lua_State *L) {
    // Create a luaL metatable. This metatable is not exposed to Lua.
    // The "luaL_nnSVGImage" label is used by luaL internally to identify things.
    luaL_newmetatable(L, NNSVG_METATABLE_NAME);

    // Set the "__index" field of the metatable to point to itself
    lua_pushstring(L, "__index");
    lua_pushvalue(L, -2); // duplicate nnSVGImage metatable (which is at -2)
    lua_settable(L, -3);  // set key (at -2) and value (at -1) into table (at -3)
                          // so, meta.__index = meta itself

    // Register the C methods into the metatable we just created (which is now back at -1)
    luaL_register(L, NULL, nnsvg_meth);
    lua_pop(L, 1); // Get rid of that metatable

    // Register the C library functions as module functions (this
    // sets it as a global variable with the name "nnsvg").
    luaL_register(L, NNSVG_LIBNAME, nnsvg_func);

    return 1; // return that table
}
