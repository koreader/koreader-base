#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>

#ifdef __APPLE__
#include <mach-o/dyld.h>
#include <sys/errno.h>
#include <sys/syslimits.h>
#include <CoreGraphics/CGDirectDisplay.h>

#elif __linux__
#include <errno.h>
#include <limits.h>
#include <X11/Xlib.h>

#endif

#define LOGNAME "Desktop loader"

struct ScreenSize {
    int width, height;
};

struct ScreenSize getScreenSize(void) {
    struct ScreenSize screenSize = { 0 , 0 };
#ifdef __APPLE__
    CGDirectDisplayID id = CGMainDisplayID();
    screenSize.width = CGDisplayPixelsWide(id);
    screenSize.height = CGDisplayPixelsHigh(id);
#elif __LINUX
    Display *display = XOpenDisplay(NULL);
    if (display != NULL) {
        Screen *screen = XDefaultScreenOfDisplay(display);
        if (screen != NULL {
            screenSize.width = screen->width;
            screenSize.height = screen->height;
        }
        XCloseDisplay(display);
    }
#endif
    return screenSize;
}


int isAppImage(void) {
#ifdef __linux__
    if (getenv("APPIMAGE") != NULL)
        return 1;
    else
        return 0;
#else
    return 0;
#endif
}

char* assetsDir(void) {
#ifdef __APPLE__
    /* KOReader.app/Contents/MacOS -> KOReader.app/Contents/koreader */
    return "../koreader";
#elif __linux__
    /* /usr/bin -> /usr/lib/koreader
       /usr/local/bin -> /usr/local/lib/koreader
    */
    return "../lib/koreader";
#else
    return NULL;
#endif
}

char* binaryPath(void) {
    static char path[PATH_MAX];
#ifdef __APPLE__
    char buffer[PATH_MAX];
    uint32_t size = sizeof(buffer);
    if (_NSGetExecutablePath(buffer, &size) != 0) {
        return NULL;
    }
    int len = readlink(buffer, path, sizeof(path));
    if (len == -1) {
        if (errno != EINVAL) {
            fprintf(stderr, "[%s]: %s\n", LOGNAME, strerror(errno));
            return NULL;
        } else {
            strncpy(path, buffer, sizeof(buffer));
            return dirname(path);
        }
    } else {
        path[len] = '\0';
        fprintf(stderr, "[%s]: symbolic links not allowed\n", LOGNAME);
        fprintf(stderr, "[%s]: please append %s to your PATH\n", LOGNAME, dirname(path));
        return NULL;
    }
#elif __linux__
    int len = readlink("/proc/self/exe", path, sizeof(path));
    if (len == -1) {
        fprintf(stderr, "[%s]: %s\n", LOGNAME, strerror(errno));
        return NULL;
    } else {
        path[len] = '\0';
        return dirname(path);
    }
#else
    return NULL;
#endif
}
