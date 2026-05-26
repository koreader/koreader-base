#include <stdint.h>
#include <stddef.h>

typedef int FBKey;

struct InitMessageContents {
    FBKey framebufferKey;
    uint8_t framebufferType;
};

struct CustomInitMessageContents {
    FBKey framebufferKey;
    uint8_t framebufferType;
    uint16_t width;
    uint16_t height;
};

struct UpdateRegionMessageContents {
    int type;
    int x, y, w, h;
};

struct ClientMessage {
    uint8_t type;
    union {
        struct InitMessageContents init;
        struct UpdateRegionMessageContents update;
        struct CustomInitMessageContents customInit;
        int refreshMode;
    };
};

struct InitMessageResponseContents {
    int shmKeyDefined;
    size_t shmSize;
};

struct UserInputContents {
    int inputType;
    int devId;
    int x, y, d;
};

struct ServerMessage {
    uint8_t type;
    union {
        struct InitMessageResponseContents init;
        struct UserInputContents userInput;
    };
};

cdecl_type(FBKey)
cdecl_struct(InitMessageContents)
cdecl_struct(CustomInitMessageContents)
cdecl_struct(UpdateRegionMessageContents)
cdecl_struct(ClientMessage)
cdecl_struct(InitMessageResponseContents)
cdecl_struct(UserInputContents)
cdecl_struct(ServerMessage)
