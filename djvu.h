/*
    KindlePDFViewer: DjvuLibre abstraction for Lua
    Copyright (C) 2011 Hans-Werner Hilse <hilse@web.de>

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
#ifndef _DJVU_H
#define _DJVU_H

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

// Symbol visibility
#define DLL_PUBLIC __attribute__((visibility("default")))
#define DLL_LOCAL  __attribute__((visibility("hidden")))

DLL_PUBLIC int luaopen_djvu(lua_State *L);

#endif
