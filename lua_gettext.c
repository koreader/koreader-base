/*
    KOReader-base: gettext module for Lua
    Copyright (C) 2013 Qingping Hou <qingping.hou@gmail.com>

    adapted from:
    www.it.freebsd.org/ports/local-distfiles/philip/lua_gettext.c%3frev=1.15

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

#include <locale.h>
#include "lua_gettext.h"

extern int _nl_msg_cat_cntr;

static int lua_gettext_init(lua_State *L) {
	const char* locale_dir = luaL_checkstring(L, 1);
	const char* package = luaL_checkstring(L, 2);

	setlocale(LC_ALL, "");
	bindtextdomain(package, locale_dir);
	textdomain(package);

	return(0);
}

static int lua_gettext_translate(lua_State *L) {
	lua_pushstring(L, gettext(luaL_checkstring(L, 1)));

	return(1);
}

static int lua_gettext_change_lang(lua_State *L) {
	setenv("LANGUAGE", luaL_checkstring(L, 1), 1);
	++_nl_msg_cat_cntr;

	return(0);
}


static const luaL_reg lua_gettext_func[] = {
	{"init", lua_gettext_init},
	{"translate", lua_gettext_translate},
	{"change_lang", lua_gettext_change_lang},
	{NULL, NULL}
};


int luaopen_luagettext(lua_State *L) {
	luaL_register(L, "lua_gettext", lua_gettext_func);

	return 1;
}
