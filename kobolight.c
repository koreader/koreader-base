/*
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
#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

typedef struct {
	int ld;
	int brightness;
	int isOn;
} LightInfo;

static int openLightDevice(lua_State *L) {
	LightInfo *light = (LightInfo*) lua_newuserdata(L, sizeof(LightInfo));
	luaL_getmetatable(L, "lightdev");
	
	light->ld = open("/dev/ntx_io", O_RDWR);
	printf("opening file\n");
	if (light->ld == -1) {
		return luaL_error(L, "cannot open light device");
	}
	return 1;
}

static int closeLightDevice(lua_State *L) {
	LightInfo *light = (LightInfo*) lua_newuserdata(L, sizeof(LightInfo));
	close(light->ld);
	return 0;
}

static int setBrightness(lua_State *L) {
	LightInfo *light = (LightInfo*) luaL_checkudata(L, 1, "lightdev");
	int brightness = luaL_optint(L, 2, 0)*100/24;

	if (brightness < 0 || brightness > 100) {
		return luaL_error(L, "Wrong brightness value %d given!", brightness);
	}

	if (ioctl(light->ld, 241, brightness)) {
		return luaL_error(L, "cannot change brightess value");
	}
	light->brightness = brightness;
	return 0;
}

static int toggleLight(lua_State *L) {
	LightInfo *light = (LightInfo*) luaL_checkudata(L, 1, "lightdev");
	
	if (light->isOn) {
		if (ioctl(light->ld, 241, 0)) {
			return luaL_error(L, "cannot turn off the light");
		}
		light->isOn = 0;
		return 0;
	}
	else {
		if (ioctl(light->ld, 241, light->brightness)) {
			return luaL_error(L, "cannot turn on the light");
		}
		light->isOn = 1;
		return 1;
	}
}

static const struct luaL_Reg kobolight_func[] = {
	{"open", openLightDevice},
	{NULL, NULL}
};

static const struct luaL_Reg kobolight_meth[] = {
	{"close", closeLightDevice},
	{"__gc", closeLightDevice},
	{"toggle", toggleLight},
	{"setBrightness", setBrightness},
	{NULL, NULL}
};

int luaopen_kobolight(lua_State *L) {
	luaL_newmetatable(L, "kobolight");
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);
	lua_settable(L, -3);
	luaL_register(L, NULL, kobolight_meth);
	luaL_register(L, "kobolight", kobolight_func);

	return 1;
}
