#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <mupdf/fitz.h>

static void try_hook(void *user, const char *message) {
	fz_context *ctx = user;
	if (ctx->error.top == ctx->error.stack) {
		luaL_error((lua_State*)ctx->user, "%s", message);
	} else {
		fprintf(stderr, "mupdf error: %s\n", message);
	}
}

static int try_wrapper(lua_State *L) {
	fz_context *ctx = (void*)(intptr_t)lua_tonumber(L, 1);
	ctx->user = L;
	ctx->error.print_user = ctx;
	ctx->error.print = try_hook;
	lua_call(L, lua_gettop(L) - 2, LUA_MULTRET);
	return lua_gettop(L) - 1;
}

int luaopen_mupdf(lua_State *L) {
	luaL_loadstring(L,
	"local try_wrapper = ..."
	"local ffi = require('ffi')\n"
	"local mupdf = ffi.load('libs/libmupdf.so')\n"
	"local intptr_t = ffi.typeof('intptr_t')"
	"ffi.metatype('fz_context', {\n"
	"	__index = function(ct, k)\n"
	"		return function(ctx,...)\n"
	"			return try_wrapper(tonumber(ffi.cast(intptr_t, ctx)), mupdf[k], ctx, ...)\n"
	"		end\n"
	"	end\n"
	"})\n"
	"return mupdf\n");
	lua_pushcfunction(L, try_wrapper);
	lua_call(L, 1, 1);
	return 1;
}

