/* Entry point for the desktop application */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/syslimits.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "desktop_platform.h"

#define PLATFORM "KO_MULTIUSER"
#define LANGUAGE "en_US.UTF-8"
#define USER_CONFIG ".config/koreader/settings/desktop.lua"

#define ENV_TOP "KOREADER_WINDOW_POS_Y"
#define ENV_LEFT "KOREADER_WINDOW_POS_X"
#define ENV_WIDTH "EMULATE_READER_W"
#define ENV_HEIGHT "EMULATE_READER_H"

#define ERROR_ARGS "failed setting arguments: %s\n"
#define ERROR_FILE "failed running lua script: %s\n"

struct Window {
    int top, left, width, height;
};

const char* getConfigFile(void) {
    static char path[PATH_MAX];
    char *homedir = getenv("HOME");
    if (homedir != NULL) {
        sprintf(path, "%s/%s", homedir, USER_CONFIG);
        return (const char*)path;
    }
    return NULL;
}

void setEnv(const char *name, int n) {
    if (n > 0) {
        char value[8];
        sprintf(value, "%d", n);
        setenv(name, value, 1);
    }
}

int getInt(lua_State *L, const char *key) {
    int value = 0;
    if (lua_istable(L, -1)) {
        lua_pushstring(L, key);
        lua_gettable(L, -2);
        value = lua_tonumber(L, -1);
        lua_pop(L, 1);
    }
    return value;
}

struct Window loadWindow(lua_State *L, const char *file) {
    struct Window w = { 0, 0, 0, 0 };
    int err = luaL_dofile(L, file);
    if (!err) {
        w.top = getInt(L, "top");
        w.left = getInt(L, "left");
        w.width = getInt(L, "width");
        w.height = getInt(L, "height");
    }
    lua_pop(L, 1);
    return w;

}

int fitsInScreen(struct Window w, struct ScreenSize s) {
    if ((w.top + w.height <= s.height) && (w.left + w.width <= s.width)) {
        return 1;
    }
    return 0;
}

void logAndDie(const char* msg) {
    fprintf(stderr, "[%s]: %s\n", LOGNAME, msg);
    exit(EXIT_FAILURE);
}


int main(int argc, const char * argv[]) {
    int appImage = isAppImage();

    if (!appImage) {
        char *binary_dir = binaryPath();
        if (binary_dir == NULL)
            logAndDie("unable to get executable path");

        char *assets_dir = assetsDir();
        if (assets_dir == NULL)
            logAndDie("unable to get assets path");

        if (chdir(binary_dir) != 0)  
            logAndDie("unable to chdir to executable path");
        
        if (chdir(assets_dir) != 0)
            fprintf(stdout, "[%s]: unable to chdir to assets, using cwd\n", LOGNAME);

        if (setenv(PLATFORM, "1", 1) != 0)
            logAndDie("unable to set environment for desktop platforms");
    }	
   
    if (setenv("LC_ALL", LANGUAGE, 1) != 0)
        logAndDie("unable to set language, please check your locales");

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);

    int windowFits = 0;

    const char* luaFile = getConfigFile();
    if (luaFile != NULL) {

        struct Window w;
        struct ScreenSize s;

        w = loadWindow(L, luaFile);
        s = getScreenSize();

        windowFits = fitsInScreen(w, s);

        if (windowFits) {
            setEnv(ENV_TOP, w.top);
            setEnv(ENV_LEFT, w.left);
            setEnv(ENV_WIDTH, w.width);
            setEnv(ENV_HEIGHT, w.height);
        }
    }

    int retval;
    if (argc == 1) {
        retval = luaL_dostring(L, "arg = { os.getenv('HOME') }");
        if (retval) {
            fprintf(stderr, ERROR_ARGS, lua_tostring(L, -1));
            goto quit;
        }

    } else {
        retval = luaL_dostring(L, "arg = {}");
        if (retval) {
            fprintf(stderr, ERROR_ARGS, lua_tostring(L, -1));
            goto quit;
        }
        char buffer[PATH_MAX];
        for (int i = 1; i < argc; ++i) {
            if (snprintf(buffer, PATH_MAX, "table.insert(arg, '%s')", argv[i]) >= 0) {
                retval = luaL_dostring(L, buffer);
                if (retval) {
                    fprintf(stderr, ERROR_ARGS, lua_tostring(L, -1));
                    goto quit;
                }
            }
        }
    }

    retval = luaL_dofile(L, "reader.lua");
    if (retval)
        fprintf(stderr, ERROR_FILE, lua_tostring(L, -1));

    goto quit;

quit:
    lua_close(L);
    unsetenv("LC_ALL");
    if (!appImage)
        unsetenv(PLATFORM);

    if (windowFits) {
        unsetenv(ENV_TOP);
        unsetenv(ENV_LEFT);
        unsetenv(ENV_WIDTH);
        unsetenv(ENV_HEIGHT);
    }

    return retval;
}
