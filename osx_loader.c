/* Entry point for the SDL desktop application */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <libgen.h>
#include <unistd.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#ifdef __APPLE__
    #include <mach-o/dyld.h>
#endif

int setenvOk(const char *key, const char *value) {
    if (setenv(key, value, 1) != 0) {
        printf("Unable to set environment variable %s\n", key);
        return 1;
    }
    return 0;
}

int chdirOk(const char *dir) {
    if (chdir(dir) != 0) {
        printf("Unable to change dir to %s\n", dir);
        return 1;
    }
    return 0;
}

int luaOk(lua_State *L, int retval) {
    if (retval != 0) {
        printf("failed to run lua chunk: %s\n", lua_tostring(L, -1));
        return 1;
    }
    return 0;
}

int main(int argc, const char * argv[]) {
    int retval;
    static char binpath[PATH_MAX];
    uint32_t size = sizeof(binpath);
#ifdef __APPLE__
    if (_NSGetExecutablePath(binpath, &size) != 0)
        goto quit;
#elif __linux__
    memset(path, 0, size);
    if (readlink("/proc/self/exe", path, &size) == -1)
        goto quit;
#else
    printf("unsupported platform");
    exit(EXIT_FAILURE);
#endif

    retval = chdirOk(dirname(binpath));
    if (retval != 0)
        goto quit;

#ifdef __APPLE__
    retval = chdirOk("../koreader");
#elif __linux__
    retval = chdirOk("../lib/koreader");
#endif
    if (retval != 0)
        goto quit;
    
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);

    retval = setenvOk("LC_ALL", "en_US.UTF-8");
    if (retval != 0)
        goto quit;
    
    retval = setenvOk("KO_MULTIUSER", "1");
    if (retval != 0)
        goto quit;
    
    retval = luaOk(L, luaL_dostring(L, "arg = { os.getenv('HOME') }"));
    if (retval != 0) {
        goto quit;
    }

    retval = luaOk(L, luaL_dofile(L, "reader.lua"));

    lua_close(L);
    unsetenv("LC_ALL");
    unsetenv("KO_MULTIUSER");
    return retval;

quit:
    unsetenv("LC_ALL");
    unsetenv("KO_MULTIUSER");
    return retval;
}
