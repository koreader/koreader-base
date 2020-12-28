/* Entry point for the SDL OSX application

 SDL has some arcane magic that handles standalone apps (ie: apps without a bundle) and "normal" osx app bundles. 
 We use this binary to make SDL aware that we're running within an application bundle. It also allows us to use XCode Instruments for profiling.
 For some reason these things won't happen if the executable in the bundle is a shell/lua script.

 NOTE: SDL will fail to detect that we're a bundle if this binary is called using a symbolic link, so we prevent that here too */

#include <stdio.h>          // for fprintf, stderr, printf
#include <stdlib.h>         // for exit, setenv, EXIT_FAILURE
#include <stdint.h>         // for uint32_t
#include <string.h>         // for strerror, strncpy
#include <unistd.h>         // for chdir, readlink
#include <libgen.h>         // for dirname
#include <mach-o/dyld.h>    // for _NSGetExecutablePath
#include <sys/errno.h>      // for errno, EINVAL
#include <sys/syslimits.h>  // for PATH_MAX

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#define LOGNAME "OSX loader"
#define LANGUAGE "en_US.UTF-8"
#define PLATFORM "KO_MULTIUSER"
#define LUA_ERROR "failed to run lua chunk: %s\n"

int main(int argc, const char * argv[]) {
    int retval;
    lua_State *L;
    char path[PATH_MAX];
    char buffer[PATH_MAX];
    uint32_t size = sizeof(buffer);
    
    if (_NSGetExecutablePath(buffer, &size) != 0) {
        printf("[%s]: unable to get executable path", LOGNAME);
        exit(EXIT_FAILURE);
    }
    
    retval = readlink(buffer, path, sizeof(path));
    if (retval == -1) {
        if (errno != EINVAL) {
            fprintf(stderr, "[%s]: %s\n", LOGNAME, strerror(errno));
            exit(EXIT_FAILURE);
        } else {
            strncpy(path, buffer, sizeof(buffer));
        }
    } else {
        path[retval] = '\0';
        fprintf(stderr, "[%s]: symbolic links not allowed\n", LOGNAME);
        fprintf(stderr, "[%s]: please append %s to your PATH\n", LOGNAME, dirname(path));
        exit(EXIT_FAILURE);
    }
    
    if (!(chdir(dirname(path)) == 0 && chdir("../koreader") == 0)) {
        fprintf(stderr, "[%s]: chdir to koreader assets failed!\n", LOGNAME);
        exit(EXIT_FAILURE);
    }

    if (!((setenv("LC_ALL", LANGUAGE, 1) == 0) && (setenv(PLATFORM, "1", 1) == 0))) {
        fprintf(stderr, "[%s]: set environment variables failed!\n", LOGNAME);
        exit(EXIT_FAILURE);
    }

    L = luaL_newstate();
    luaL_openlibs(L);

    retval = luaL_dostring(L, "arg = {}");
    if (retval) {
        fprintf(stderr, LUA_ERROR, lua_tostring(L, -1));
        goto quit;
    }
    for (int i = 1; i < argc; ++i) {
        if (snprintf(buffer, PATH_MAX, "table.insert(arg, '%s')", argv[i]) >= 0) {
            retval = luaL_dostring(L, buffer);
            if (retval) {
                fprintf(stderr, LUA_ERROR, lua_tostring(L, -1));
                goto quit;
            }
        }
    }

    retval = luaL_dofile(L, "reader.lua");
    if (retval)
        fprintf(stderr, LUA_ERROR, lua_tostring(L, -1));

    goto quit;

quit:
    lua_close(L);
    unsetenv("LC_ALL");
    unsetenv("KO_MULTIUSER");
    return retval;
}
