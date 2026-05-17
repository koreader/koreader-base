-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
typedef enum {
  INPUT_UNKNOWN = 0U,
  INPUT_POINTINGSTICK = 1U << 0U,
  INPUT_MOUSE = 1U << 1U,
  INPUT_TOUCHPAD = 1U << 2U,
  INPUT_TOUCHSCREEN = 1U << 3U,
  INPUT_JOYSTICK = 1U << 4U,
  INPUT_TABLET = 1U << 5U,
  INPUT_KEY = 1U << 6U,
  INPUT_KEYBOARD = 1U << 7U,
  INPUT_ACCELEROMETER = 1U << 8U,
  INPUT_POWER_BUTTON = 1U << 16U,
  INPUT_SLEEP_COVER = 1U << 17U,
  INPUT_PAGINATION_BUTTONS = 1U << 18U,
  INPUT_HOME_BUTTON = 1U << 19U,
  INPUT_LIGHT_BUTTON = 1U << 20U,
  INPUT_MENU_BUTTON = 1U << 21U,
  INPUT_DPAD = 1U << 22U,
  INPUT_ROTATION_EVENT = 1U << 23U,
  INPUT_SCALED_TABLET = 1U << 24U,
  INPUT_VOLUME_BUTTONS = 1U << 25U,
  INPUT_KINDLE_FRAME_TAP = 1U << 26U,
} INPUT_DEVICE_TYPE_E;
typedef uint32_t INPUT_DEVICE_TYPE_T;
typedef enum {
  SCAN_ONLY = 1U << 0U,
  OPEN_BLOCKING = 1U << 1U,
  MATCH_ALL = 1U << 2U,
  EXCLUDE_ALL = 1U << 3U,
  NO_RECAP = 1U << 4U,
} INPUT_SETTINGS_TYPE_E;
typedef uint32_t INPUT_SETTINGS_TYPE_T;
typedef struct {
  INPUT_DEVICE_TYPE_T type;
  int fd;
  bool matched;
  char name[256];
  char path[4096];
} FBInkInputDevice;
FBInkInputDevice *fbink_input_scan(INPUT_DEVICE_TYPE_T match_types, INPUT_DEVICE_TYPE_T exclude_types, INPUT_SETTINGS_TYPE_T settings, size_t *dev_count);
FBInkInputDevice *fbink_input_check(const char *filepath, INPUT_DEVICE_TYPE_T match_types, INPUT_DEVICE_TYPE_T exclude_types, INPUT_SETTINGS_TYPE_T settings);
]]
