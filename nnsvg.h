// nnsvg.cpp
// Lua interface to wrap nanosvg.

#ifndef _NNSVG_H
#define _NNSVG_H

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

// Symbol visibility
#define DLL_PUBLIC __attribute__((visibility("default")))
#define DLL_LOCAL  __attribute__((visibility("hidden")))

DLL_PUBLIC int luaopen_nnsvg(lua_State *L);
#endif
