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

int luaopen_xtext(lua_State *L);
#endif
