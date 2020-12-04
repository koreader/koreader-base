// nnsvg.cpp
// Lua interface to wrap nanosvg.

#ifndef _NNSVG_H
#define _NNSVG_H

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

// Don't leak NanoSVG's own symbols, this is the only symbol
// that is needed to use this library from Lua.
// When compiled with '-fvisibility=hidden', this will be
// the only one visible.
__attribute__((visibility("default"))) int luaopen_nnsvg(lua_State *L);
#endif
