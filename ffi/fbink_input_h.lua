-- Automatically generated with: ffi-cdecl -o ffi/fbink_input_h.lua -I build/arm-kindlepw2-linux-gnueabi/thirdparty/libfbink_input/source build/arm-kindlepw2-linux-gnueabi/thirdparty/libfbink_input/source/ffi/fbink_input_decl.c

local ffi = require("ffi")

ffi.cdef[[
typedef enum {
  INPUT_UNKNOWN = 0,
  INPUT_POINTINGSTICK = 1,
  INPUT_MOUSE = 2,
  INPUT_TOUCHPAD = 4,
  INPUT_TOUCHSCREEN = 8,
  INPUT_JOYSTICK = 16,
  INPUT_TABLET = 32,
  INPUT_KEY = 64,
  INPUT_KEYBOARD = 128,
  INPUT_ACCELEROMETER = 256,
  INPUT_POWER_BUTTON = 65536,
  INPUT_SLEEP_COVER = 131072,
  INPUT_PAGINATION_BUTTONS = 262144,
  INPUT_HOME_BUTTON = 524288,
  INPUT_LIGHT_BUTTON = 1048576,
  INPUT_MENU_BUTTON = 2097152,
  INPUT_DPAD = 4194304,
  INPUT_ROTATION_EVENT = 8388608,
  INPUT_SCALED_TABLET = 16777216,
  INPUT_VOLUME_BUTTONS = 33554432,
} __attribute__((packed)) INPUT_DEVICE_TYPE_E;
typedef uint32_t INPUT_DEVICE_TYPE_T;
typedef enum {
  SCAN_ONLY = 1,
  OPEN_BLOCKING = 2,
  MATCH_ALL = 4,
  EXCLUDE_ALL = 8,
  NO_RECAP = 16,
} __attribute__((packed)) INPUT_SETTINGS_TYPE_E;
typedef uint32_t INPUT_SETTINGS_TYPE_T;
typedef struct {
  INPUT_DEVICE_TYPE_T type;
  int fd;
  bool matched;
  char name[256];
  char path[4096];
} FBInkInputDevice;
FBInkInputDevice *fbink_input_scan(INPUT_DEVICE_TYPE_T, INPUT_DEVICE_TYPE_T, INPUT_SETTINGS_TYPE_T, size_t *);
FBInkInputDevice *fbink_input_check(const char *, INPUT_DEVICE_TYPE_T, INPUT_DEVICE_TYPE_T, INPUT_SETTINGS_TYPE_T);
]]
