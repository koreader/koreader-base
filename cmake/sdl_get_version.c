#include <dlfcn.h>
#include <stdio.h>

int SDL_GetVersion(void);

int main(int argc, char *argv[]) {
    int (*get_version)();
    int version;
    void *lib;
    if (argc != 2)
        return 1;
    lib = dlopen(argv[1], RTLD_LAZY | RTLD_LOCAL);
    if (!lib) {
        fprintf(stderr, "dlopen(%s): %s\n", argv[1], dlerror());
        return 2;
    }
    get_version = dlsym(lib, "SDL_GetVersion");
    if (!get_version) {
        fprintf(stderr, "dsym(%s): %s\n", "SDL_GetVersion", dlerror());
        return 2;
    }
    version = get_version();
    printf("%d.%d.%d", version / 1000000, version / 1000 % 1000, version % 1000);
    return 0;
}
