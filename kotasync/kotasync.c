#include <lauxlib.h>
#include <lualib.h>

#include <stdio.h>
#include <stdlib.h>

static const char *bootstrap_script = (R""""(
local redirects = { ["libs/libkoreader-lfs"] = "lfs" }
for modulename in (')"""" LUA_MODULES R""""('):gmatch("[^ ]+") do
    local redir = modulename:gsub("/", "_")
    if redir ~= modulename then
        redirects[modulename] = redir
    end
end
table.insert(package.loaders, function (modulename)
    local redir = redirects[modulename]
    if redir then
        return function() return require(redir) end
    end
end)
require "kotasync"
)"""");


int main(int argc, char *argv[]) {
    lua_State *L;
    if (setenv("KOTASYNC_USE_XZ_LIB", "1", 0)) {
        perror("setenv");
        return 1;
    }
    L = lua_open();
    if (!L)
        return 1;
    // Setup `arg` table.
    lua_createtable(L, argc, 0);
    for (int i = 0; i < argc; ++i) {
        lua_pushstring(L, argv[i]);
        lua_rawseti(L, -2, i);
    }
    lua_setglobal(L, "arg");
    // Load standard library.
    luaL_openlibs(L);
    // And run bootstrap script.
    if (luaL_dostring(L, bootstrap_script)) {
        const char *msg = lua_tostring(L, -1);
        fprintf(stderr, "%s\n", msg);
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
