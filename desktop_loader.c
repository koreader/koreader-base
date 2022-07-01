/* Entry point for the desktop SDL application

It detects the binary path, jumps to it, jumps to assets path, setups a few env variables and executes "reader.lua" passing all arguments.

It is useful mostly on MacOS, where it is required to run as a standalone app bundle and makes possible to use XCode instruments for profiling.
On Linux it enforces that the name & icon set in SDL are the ones used by the desktop environment.

*/

#include <stdio.h>          // for fprintf, stderr, printf
#include <stdlib.h>         // for exit, setenv, EXIT_FAILURE
#include <stdint.h>         // for uint32_t
#include <string.h>         // for strerror, strncpy
#include <unistd.h>         // for chdir, readlink
#include <libgen.h>         // for dirname

#define LOGNAME "Desktop loader"
#define LANGUAGE "en_US.UTF-8"
#define PLATFORM "KO_MULTIUSER"
#define LUA_ERROR "failed to run lua chunk: %s\n"
#define MAGIC_RESTART 85

#if __APPLE__
#include <sys/errno.h>
#include <mach-o/dyld.h>
#include <sys/syslimits.h>
#define ASSETS_PATH "../koreader"
#elif __linux__
#include <limits.h>
#define ASSETS_PATH "../lib/koreader"
#else
#   error "unsupported platform"
#endif

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

char *executablePath() {
    char buffer[PATH_MAX];
    static char path[PATH_MAX];
    ssize_t len;

#if __APPLE__
    uint32_t size = sizeof(buffer);
    if (_NSGetExecutablePath(buffer, &size) != 0) {
        fprintf(stderr, "[%s]: unable to get executable path", LOGNAME);
        exit(EXIT_FAILURE);
    }
    len = readlink(buffer, path, sizeof(path) - 1);
    if (len == -1) {
        if (errno != EINVAL) {
            fprintf(stderr, "[%s]: %s\n", LOGNAME, strerror(errno));
            exit(EXIT_FAILURE);
        } else {
            strncpy(path, buffer, sizeof(buffer));
        }
    } else {
        // SDL will fail to detect that we're a bundle if this binary is called using a symbolic link
        fprintf(stderr, "[%s]: symbolic links not allowed\n", LOGNAME);
        fprintf(stderr, "[%s]: please append %s to your PATH\n", LOGNAME, dirname(path));
        exit(EXIT_FAILURE);
    }
#elif __linux__
    len = readlink("/proc/self/exe", buffer, sizeof(buffer) - 1);
    if (len == -1) {
        printf("[%s]: unable to get executable path", LOGNAME);
        exit(EXIT_FAILURE);
    }
    strncpy(path, buffer, sizeof(buffer));
#endif
    return path;
}

int main(int argc, const char * argv[]) {
    int retval;
    char buffer[PATH_MAX];
    char assetsPath[PATH_MAX];
    char *binPath;
    lua_State *L;

    binPath = executablePath();
    if (!(chdir(dirname(binPath)) == 0 && chdir(ASSETS_PATH) == 0)) {
        fprintf(stderr, "[%s]: chdir to koreader assets failed!\n", LOGNAME);
        exit(EXIT_FAILURE);
    }

    if (getcwd(assetsPath, sizeof(assetsPath)) == NULL) {
        fprintf(stderr, "[%s]: unable to obtain koreader assets path!\n", LOGNAME);
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
