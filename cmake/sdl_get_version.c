#include <stdio.h>

int SDL_GetVersion(void);

int main(void) {
    int version = SDL_GetVersion();
    printf("%d.%d.%d", version / 1000000, version / 1000 % 1000, version % 1000);
    return 0;
}
