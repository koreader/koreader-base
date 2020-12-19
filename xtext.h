// xtext.cpp
// Lua interface to wrap a utf8 string into a XText object
// that provides various text shaping and layout methods
// with the help of Fribidi, Harfbuzz and libunibreak.

#ifndef _XTEXT_H
#define _XTEXT_H

extern "C"
{
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

// Symbol visibility
#define DLL_PUBLIC __attribute__((visibility("default")))
#define DLL_LOCAL  __attribute__((visibility("hidden")))

DLL_PUBLIC int luaopen_xtext(lua_State *L);
#endif
