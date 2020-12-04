// nnsvg.cpp
// Lua interface to wrap nanosvg.

#ifndef _NNSVG_H
#define _NNSVG_H

extern "C"
{
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

int luaopen_nnsvg(lua_State *L);
#endif
