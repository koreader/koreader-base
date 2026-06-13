-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
typedef uint64_t Uint64;
typedef int64_t Sint64;
typedef uint32_t Uint32;
typedef int32_t Sint32;
typedef uint16_t Uint16;
typedef int16_t Sint16;
typedef uint8_t Uint8;
typedef int8_t Sint8;
static const unsigned SDL_BUTTON_LEFT = 1;
static const unsigned SDL_BUTTON_RIGHT = 3;
static const unsigned SDL_INIT_EVENTS = 16384;
static const unsigned SDL_INIT_GAMEPAD = 8192;
static const unsigned SDL_INIT_VIDEO = 32;
static const unsigned SDL_HAT_CENTERED = 0;
static const unsigned SDL_HAT_UP = 1;
static const unsigned SDL_HAT_RIGHT = 2;
static const unsigned SDL_HAT_DOWN = 4;
static const unsigned SDL_HAT_LEFT = 8;
static const unsigned SDL_HAT_RIGHTUP = 3;
static const unsigned SDL_HAT_RIGHTDOWN = 6;
static const unsigned SDL_HAT_LEFTUP = 9;
static const unsigned SDL_HAT_LEFTDOWN = 12;
static const unsigned SDL_TOUCH_MOUSEID = 4294967295;
static const unsigned SDL_WINDOWPOS_UNDEFINED = 536805376;
static const unsigned SDL_WINDOW_FULLSCREEN = 1;
static const unsigned SDL_WINDOW_RESIZABLE = 32;
static const unsigned SDL_WINDOW_HIGH_PIXEL_DENSITY = 8192;
enum SDL_EventType {
  SDL_EVENT_FIRST = 0,
  SDL_EVENT_QUIT = 0x100,
  SDL_EVENT_TERMINATING,
  SDL_EVENT_LOW_MEMORY,
  SDL_EVENT_WILL_ENTER_BACKGROUND,
  SDL_EVENT_DID_ENTER_BACKGROUND,
  SDL_EVENT_WILL_ENTER_FOREGROUND,
  SDL_EVENT_DID_ENTER_FOREGROUND,
  SDL_EVENT_LOCALE_CHANGED,
  SDL_EVENT_SYSTEM_THEME_CHANGED,
  SDL_EVENT_DISPLAY_ORIENTATION = 0x151,
  SDL_EVENT_DISPLAY_ADDED,
  SDL_EVENT_DISPLAY_REMOVED,
  SDL_EVENT_DISPLAY_MOVED,
  SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED,
  SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED,
  SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED,
  SDL_EVENT_DISPLAY_USABLE_BOUNDS_CHANGED,
  SDL_EVENT_DISPLAY_FIRST = SDL_EVENT_DISPLAY_ORIENTATION,
  SDL_EVENT_DISPLAY_LAST = SDL_EVENT_DISPLAY_USABLE_BOUNDS_CHANGED,
  SDL_EVENT_WINDOW_SHOWN = 0x202,
  SDL_EVENT_WINDOW_HIDDEN,
  SDL_EVENT_WINDOW_EXPOSED,
  SDL_EVENT_WINDOW_MOVED,
  SDL_EVENT_WINDOW_RESIZED,
  SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED,
  SDL_EVENT_WINDOW_METAL_VIEW_RESIZED,
  SDL_EVENT_WINDOW_MINIMIZED,
  SDL_EVENT_WINDOW_MAXIMIZED,
  SDL_EVENT_WINDOW_RESTORED,
  SDL_EVENT_WINDOW_MOUSE_ENTER,
  SDL_EVENT_WINDOW_MOUSE_LEAVE,
  SDL_EVENT_WINDOW_FOCUS_GAINED,
  SDL_EVENT_WINDOW_FOCUS_LOST,
  SDL_EVENT_WINDOW_CLOSE_REQUESTED,
  SDL_EVENT_WINDOW_HIT_TEST,
  SDL_EVENT_WINDOW_ICCPROF_CHANGED,
  SDL_EVENT_WINDOW_DISPLAY_CHANGED,
  SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED,
  SDL_EVENT_WINDOW_SAFE_AREA_CHANGED,
  SDL_EVENT_WINDOW_OCCLUDED,
  SDL_EVENT_WINDOW_ENTER_FULLSCREEN,
  SDL_EVENT_WINDOW_LEAVE_FULLSCREEN,
  SDL_EVENT_WINDOW_DESTROYED,
  SDL_EVENT_WINDOW_HDR_STATE_CHANGED,
  SDL_EVENT_WINDOW_FIRST = SDL_EVENT_WINDOW_SHOWN,
  SDL_EVENT_WINDOW_LAST = SDL_EVENT_WINDOW_HDR_STATE_CHANGED,
  SDL_EVENT_KEY_DOWN = 0x300,
  SDL_EVENT_KEY_UP,
  SDL_EVENT_TEXT_EDITING,
  SDL_EVENT_TEXT_INPUT,
  SDL_EVENT_KEYMAP_CHANGED,
  SDL_EVENT_KEYBOARD_ADDED,
  SDL_EVENT_KEYBOARD_REMOVED,
  SDL_EVENT_TEXT_EDITING_CANDIDATES,
  SDL_EVENT_SCREEN_KEYBOARD_SHOWN,
  SDL_EVENT_SCREEN_KEYBOARD_HIDDEN,
  SDL_EVENT_MOUSE_MOTION = 0x400,
  SDL_EVENT_MOUSE_BUTTON_DOWN,
  SDL_EVENT_MOUSE_BUTTON_UP,
  SDL_EVENT_MOUSE_WHEEL,
  SDL_EVENT_MOUSE_ADDED,
  SDL_EVENT_MOUSE_REMOVED,
  SDL_EVENT_JOYSTICK_AXIS_MOTION = 0x600,
  SDL_EVENT_JOYSTICK_BALL_MOTION,
  SDL_EVENT_JOYSTICK_HAT_MOTION,
  SDL_EVENT_JOYSTICK_BUTTON_DOWN,
  SDL_EVENT_JOYSTICK_BUTTON_UP,
  SDL_EVENT_JOYSTICK_ADDED,
  SDL_EVENT_JOYSTICK_REMOVED,
  SDL_EVENT_JOYSTICK_BATTERY_UPDATED,
  SDL_EVENT_JOYSTICK_UPDATE_COMPLETE,
  SDL_EVENT_GAMEPAD_AXIS_MOTION = 0x650,
  SDL_EVENT_GAMEPAD_BUTTON_DOWN,
  SDL_EVENT_GAMEPAD_BUTTON_UP,
  SDL_EVENT_GAMEPAD_ADDED,
  SDL_EVENT_GAMEPAD_REMOVED,
  SDL_EVENT_GAMEPAD_REMAPPED,
  SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN,
  SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION,
  SDL_EVENT_GAMEPAD_TOUCHPAD_UP,
  SDL_EVENT_GAMEPAD_SENSOR_UPDATE,
  SDL_EVENT_GAMEPAD_UPDATE_COMPLETE,
  SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED,
  SDL_EVENT_FINGER_DOWN = 0x700,
  SDL_EVENT_FINGER_UP,
  SDL_EVENT_FINGER_MOTION,
  SDL_EVENT_FINGER_CANCELED,
  SDL_EVENT_PINCH_BEGIN = 0x710,
  SDL_EVENT_PINCH_UPDATE,
  SDL_EVENT_PINCH_END,
  SDL_EVENT_CLIPBOARD_UPDATE = 0x900,
  SDL_EVENT_DROP_FILE = 0x1000,
  SDL_EVENT_DROP_TEXT,
  SDL_EVENT_DROP_BEGIN,
  SDL_EVENT_DROP_COMPLETE,
  SDL_EVENT_DROP_POSITION,
  SDL_EVENT_AUDIO_DEVICE_ADDED = 0x1100,
  SDL_EVENT_AUDIO_DEVICE_REMOVED,
  SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED,
  SDL_EVENT_SENSOR_UPDATE = 0x1200,
  SDL_EVENT_PEN_PROXIMITY_IN = 0x1300,
  SDL_EVENT_PEN_PROXIMITY_OUT,
  SDL_EVENT_PEN_DOWN,
  SDL_EVENT_PEN_UP,
  SDL_EVENT_PEN_BUTTON_DOWN,
  SDL_EVENT_PEN_BUTTON_UP,
  SDL_EVENT_PEN_MOTION,
  SDL_EVENT_PEN_AXIS,
  SDL_EVENT_CAMERA_DEVICE_ADDED = 0x1400,
  SDL_EVENT_CAMERA_DEVICE_REMOVED,
  SDL_EVENT_CAMERA_DEVICE_APPROVED,
  SDL_EVENT_CAMERA_DEVICE_DENIED,
  SDL_EVENT_RENDER_TARGETS_RESET = 0x2000,
  SDL_EVENT_RENDER_DEVICE_RESET,
  SDL_EVENT_RENDER_DEVICE_LOST,
  SDL_EVENT_PRIVATE0 = 0x4000,
  SDL_EVENT_PRIVATE1,
  SDL_EVENT_PRIVATE2,
  SDL_EVENT_PRIVATE3,
  SDL_EVENT_POLL_SENTINEL = 0x7F00,
  SDL_EVENT_USER = 0x8000,
  SDL_EVENT_LAST = 0xFFFF,
  SDL_EVENT_ENUM_PADDING = 0x7FFFFFFF,
};
enum SDL_GamepadButton {
  SDL_GAMEPAD_BUTTON_INVALID = -1,
  SDL_GAMEPAD_BUTTON_SOUTH,
  SDL_GAMEPAD_BUTTON_EAST,
  SDL_GAMEPAD_BUTTON_WEST,
  SDL_GAMEPAD_BUTTON_NORTH,
  SDL_GAMEPAD_BUTTON_BACK,
  SDL_GAMEPAD_BUTTON_GUIDE,
  SDL_GAMEPAD_BUTTON_START,
  SDL_GAMEPAD_BUTTON_LEFT_STICK,
  SDL_GAMEPAD_BUTTON_RIGHT_STICK,
  SDL_GAMEPAD_BUTTON_LEFT_SHOULDER,
  SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER,
  SDL_GAMEPAD_BUTTON_DPAD_UP,
  SDL_GAMEPAD_BUTTON_DPAD_DOWN,
  SDL_GAMEPAD_BUTTON_DPAD_LEFT,
  SDL_GAMEPAD_BUTTON_DPAD_RIGHT,
  SDL_GAMEPAD_BUTTON_MISC1,
  SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1,
  SDL_GAMEPAD_BUTTON_LEFT_PADDLE1,
  SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2,
  SDL_GAMEPAD_BUTTON_LEFT_PADDLE2,
  SDL_GAMEPAD_BUTTON_TOUCHPAD,
  SDL_GAMEPAD_BUTTON_MISC2,
  SDL_GAMEPAD_BUTTON_MISC3,
  SDL_GAMEPAD_BUTTON_MISC4,
  SDL_GAMEPAD_BUTTON_MISC5,
  SDL_GAMEPAD_BUTTON_MISC6,
  SDL_GAMEPAD_BUTTON_COUNT,
};
enum SDL_MouseWheelDirection {
  SDL_MOUSEWHEEL_NORMAL,
  SDL_MOUSEWHEEL_FLIPPED,
};
enum SDL_PenAxis {
  SDL_PEN_AXIS_PRESSURE,
  SDL_PEN_AXIS_XTILT,
  SDL_PEN_AXIS_YTILT,
  SDL_PEN_AXIS_DISTANCE,
  SDL_PEN_AXIS_ROTATION,
  SDL_PEN_AXIS_SLIDER,
  SDL_PEN_AXIS_TANGENTIAL_PRESSURE,
  SDL_PEN_AXIS_COUNT,
};
enum SDL_PixelFormat {
  SDL_PIXELFORMAT_UNKNOWN = 0,
  SDL_PIXELFORMAT_INDEX1LSB = 0x11100100u,
  SDL_PIXELFORMAT_INDEX1MSB = 0x11200100u,
  SDL_PIXELFORMAT_INDEX2LSB = 0x1c100200u,
  SDL_PIXELFORMAT_INDEX2MSB = 0x1c200200u,
  SDL_PIXELFORMAT_INDEX4LSB = 0x12100400u,
  SDL_PIXELFORMAT_INDEX4MSB = 0x12200400u,
  SDL_PIXELFORMAT_INDEX8 = 0x13000801u,
  SDL_PIXELFORMAT_RGB332 = 0x14110801u,
  SDL_PIXELFORMAT_XRGB4444 = 0x15120c02u,
  SDL_PIXELFORMAT_XBGR4444 = 0x15520c02u,
  SDL_PIXELFORMAT_XRGB1555 = 0x15130f02u,
  SDL_PIXELFORMAT_XBGR1555 = 0x15530f02u,
  SDL_PIXELFORMAT_ARGB4444 = 0x15321002u,
  SDL_PIXELFORMAT_RGBA4444 = 0x15421002u,
  SDL_PIXELFORMAT_ABGR4444 = 0x15721002u,
  SDL_PIXELFORMAT_BGRA4444 = 0x15821002u,
  SDL_PIXELFORMAT_ARGB1555 = 0x15331002u,
  SDL_PIXELFORMAT_RGBA5551 = 0x15441002u,
  SDL_PIXELFORMAT_ABGR1555 = 0x15731002u,
  SDL_PIXELFORMAT_BGRA5551 = 0x15841002u,
  SDL_PIXELFORMAT_RGB565 = 0x15151002u,
  SDL_PIXELFORMAT_BGR565 = 0x15551002u,
  SDL_PIXELFORMAT_RGB24 = 0x17101803u,
  SDL_PIXELFORMAT_BGR24 = 0x17401803u,
  SDL_PIXELFORMAT_XRGB8888 = 0x16161804u,
  SDL_PIXELFORMAT_RGBX8888 = 0x16261804u,
  SDL_PIXELFORMAT_XBGR8888 = 0x16561804u,
  SDL_PIXELFORMAT_BGRX8888 = 0x16661804u,
  SDL_PIXELFORMAT_ARGB8888 = 0x16362004u,
  SDL_PIXELFORMAT_RGBA8888 = 0x16462004u,
  SDL_PIXELFORMAT_ABGR8888 = 0x16762004u,
  SDL_PIXELFORMAT_BGRA8888 = 0x16862004u,
  SDL_PIXELFORMAT_XRGB2101010 = 0x16172004u,
  SDL_PIXELFORMAT_XBGR2101010 = 0x16572004u,
  SDL_PIXELFORMAT_ARGB2101010 = 0x16372004u,
  SDL_PIXELFORMAT_ABGR2101010 = 0x16772004u,
  SDL_PIXELFORMAT_RGB48 = 0x18103006u,
  SDL_PIXELFORMAT_BGR48 = 0x18403006u,
  SDL_PIXELFORMAT_RGBA64 = 0x18204008u,
  SDL_PIXELFORMAT_ARGB64 = 0x18304008u,
  SDL_PIXELFORMAT_BGRA64 = 0x18504008u,
  SDL_PIXELFORMAT_ABGR64 = 0x18604008u,
  SDL_PIXELFORMAT_RGB48_FLOAT = 0x1a103006u,
  SDL_PIXELFORMAT_BGR48_FLOAT = 0x1a403006u,
  SDL_PIXELFORMAT_RGBA64_FLOAT = 0x1a204008u,
  SDL_PIXELFORMAT_ARGB64_FLOAT = 0x1a304008u,
  SDL_PIXELFORMAT_BGRA64_FLOAT = 0x1a504008u,
  SDL_PIXELFORMAT_ABGR64_FLOAT = 0x1a604008u,
  SDL_PIXELFORMAT_RGB96_FLOAT = 0x1b10600cu,
  SDL_PIXELFORMAT_BGR96_FLOAT = 0x1b40600cu,
  SDL_PIXELFORMAT_RGBA128_FLOAT = 0x1b208010u,
  SDL_PIXELFORMAT_ARGB128_FLOAT = 0x1b308010u,
  SDL_PIXELFORMAT_BGRA128_FLOAT = 0x1b508010u,
  SDL_PIXELFORMAT_ABGR128_FLOAT = 0x1b608010u,
  SDL_PIXELFORMAT_YV12 = 0x32315659u,
  SDL_PIXELFORMAT_IYUV = 0x56555949u,
  SDL_PIXELFORMAT_YUY2 = 0x32595559u,
  SDL_PIXELFORMAT_UYVY = 0x59565955u,
  SDL_PIXELFORMAT_YVYU = 0x55595659u,
  SDL_PIXELFORMAT_NV12 = 0x3231564eu,
  SDL_PIXELFORMAT_NV21 = 0x3132564eu,
  SDL_PIXELFORMAT_P010 = 0x30313050u,
  SDL_PIXELFORMAT_EXTERNAL_OES = 0x2053454fu,
  SDL_PIXELFORMAT_MJPG = 0x47504a4du,
  SDL_PIXELFORMAT_RGBA32 = SDL_PIXELFORMAT_ABGR8888,
  SDL_PIXELFORMAT_ARGB32 = SDL_PIXELFORMAT_BGRA8888,
  SDL_PIXELFORMAT_BGRA32 = SDL_PIXELFORMAT_ARGB8888,
  SDL_PIXELFORMAT_ABGR32 = SDL_PIXELFORMAT_RGBA8888,
  SDL_PIXELFORMAT_RGBX32 = SDL_PIXELFORMAT_XBGR8888,
  SDL_PIXELFORMAT_XRGB32 = SDL_PIXELFORMAT_BGRX8888,
  SDL_PIXELFORMAT_BGRX32 = SDL_PIXELFORMAT_XRGB8888,
  SDL_PIXELFORMAT_XBGR32 = SDL_PIXELFORMAT_RGBX8888,
};
enum SDL_PowerState {
  SDL_POWERSTATE_ERROR = -1,
  SDL_POWERSTATE_UNKNOWN,
  SDL_POWERSTATE_ON_BATTERY,
  SDL_POWERSTATE_NO_BATTERY,
  SDL_POWERSTATE_CHARGING,
  SDL_POWERSTATE_CHARGED,
};
enum SDL_Scancode {
  SDL_SCANCODE_UNKNOWN = 0,
  SDL_SCANCODE_A = 4,
  SDL_SCANCODE_B = 5,
  SDL_SCANCODE_C = 6,
  SDL_SCANCODE_D = 7,
  SDL_SCANCODE_E = 8,
  SDL_SCANCODE_F = 9,
  SDL_SCANCODE_G = 10,
  SDL_SCANCODE_H = 11,
  SDL_SCANCODE_I = 12,
  SDL_SCANCODE_J = 13,
  SDL_SCANCODE_K = 14,
  SDL_SCANCODE_L = 15,
  SDL_SCANCODE_M = 16,
  SDL_SCANCODE_N = 17,
  SDL_SCANCODE_O = 18,
  SDL_SCANCODE_P = 19,
  SDL_SCANCODE_Q = 20,
  SDL_SCANCODE_R = 21,
  SDL_SCANCODE_S = 22,
  SDL_SCANCODE_T = 23,
  SDL_SCANCODE_U = 24,
  SDL_SCANCODE_V = 25,
  SDL_SCANCODE_W = 26,
  SDL_SCANCODE_X = 27,
  SDL_SCANCODE_Y = 28,
  SDL_SCANCODE_Z = 29,
  SDL_SCANCODE_1 = 30,
  SDL_SCANCODE_2 = 31,
  SDL_SCANCODE_3 = 32,
  SDL_SCANCODE_4 = 33,
  SDL_SCANCODE_5 = 34,
  SDL_SCANCODE_6 = 35,
  SDL_SCANCODE_7 = 36,
  SDL_SCANCODE_8 = 37,
  SDL_SCANCODE_9 = 38,
  SDL_SCANCODE_0 = 39,
  SDL_SCANCODE_RETURN = 40,
  SDL_SCANCODE_ESCAPE = 41,
  SDL_SCANCODE_BACKSPACE = 42,
  SDL_SCANCODE_TAB = 43,
  SDL_SCANCODE_SPACE = 44,
  SDL_SCANCODE_MINUS = 45,
  SDL_SCANCODE_EQUALS = 46,
  SDL_SCANCODE_LEFTBRACKET = 47,
  SDL_SCANCODE_RIGHTBRACKET = 48,
  SDL_SCANCODE_BACKSLASH = 49,
  SDL_SCANCODE_NONUSHASH = 50,
  SDL_SCANCODE_SEMICOLON = 51,
  SDL_SCANCODE_APOSTROPHE = 52,
  SDL_SCANCODE_GRAVE = 53,
  SDL_SCANCODE_COMMA = 54,
  SDL_SCANCODE_PERIOD = 55,
  SDL_SCANCODE_SLASH = 56,
  SDL_SCANCODE_CAPSLOCK = 57,
  SDL_SCANCODE_F1 = 58,
  SDL_SCANCODE_F2 = 59,
  SDL_SCANCODE_F3 = 60,
  SDL_SCANCODE_F4 = 61,
  SDL_SCANCODE_F5 = 62,
  SDL_SCANCODE_F6 = 63,
  SDL_SCANCODE_F7 = 64,
  SDL_SCANCODE_F8 = 65,
  SDL_SCANCODE_F9 = 66,
  SDL_SCANCODE_F10 = 67,
  SDL_SCANCODE_F11 = 68,
  SDL_SCANCODE_F12 = 69,
  SDL_SCANCODE_PRINTSCREEN = 70,
  SDL_SCANCODE_SCROLLLOCK = 71,
  SDL_SCANCODE_PAUSE = 72,
  SDL_SCANCODE_INSERT = 73,
  SDL_SCANCODE_HOME = 74,
  SDL_SCANCODE_PAGEUP = 75,
  SDL_SCANCODE_DELETE = 76,
  SDL_SCANCODE_END = 77,
  SDL_SCANCODE_PAGEDOWN = 78,
  SDL_SCANCODE_RIGHT = 79,
  SDL_SCANCODE_LEFT = 80,
  SDL_SCANCODE_DOWN = 81,
  SDL_SCANCODE_UP = 82,
  SDL_SCANCODE_NUMLOCKCLEAR = 83,
  SDL_SCANCODE_KP_DIVIDE = 84,
  SDL_SCANCODE_KP_MULTIPLY = 85,
  SDL_SCANCODE_KP_MINUS = 86,
  SDL_SCANCODE_KP_PLUS = 87,
  SDL_SCANCODE_KP_ENTER = 88,
  SDL_SCANCODE_KP_1 = 89,
  SDL_SCANCODE_KP_2 = 90,
  SDL_SCANCODE_KP_3 = 91,
  SDL_SCANCODE_KP_4 = 92,
  SDL_SCANCODE_KP_5 = 93,
  SDL_SCANCODE_KP_6 = 94,
  SDL_SCANCODE_KP_7 = 95,
  SDL_SCANCODE_KP_8 = 96,
  SDL_SCANCODE_KP_9 = 97,
  SDL_SCANCODE_KP_0 = 98,
  SDL_SCANCODE_KP_PERIOD = 99,
  SDL_SCANCODE_NONUSBACKSLASH = 100,
  SDL_SCANCODE_APPLICATION = 101,
  SDL_SCANCODE_POWER = 102,
  SDL_SCANCODE_KP_EQUALS = 103,
  SDL_SCANCODE_F13 = 104,
  SDL_SCANCODE_F14 = 105,
  SDL_SCANCODE_F15 = 106,
  SDL_SCANCODE_F16 = 107,
  SDL_SCANCODE_F17 = 108,
  SDL_SCANCODE_F18 = 109,
  SDL_SCANCODE_F19 = 110,
  SDL_SCANCODE_F20 = 111,
  SDL_SCANCODE_F21 = 112,
  SDL_SCANCODE_F22 = 113,
  SDL_SCANCODE_F23 = 114,
  SDL_SCANCODE_F24 = 115,
  SDL_SCANCODE_EXECUTE = 116,
  SDL_SCANCODE_HELP = 117,
  SDL_SCANCODE_MENU = 118,
  SDL_SCANCODE_SELECT = 119,
  SDL_SCANCODE_STOP = 120,
  SDL_SCANCODE_AGAIN = 121,
  SDL_SCANCODE_UNDO = 122,
  SDL_SCANCODE_CUT = 123,
  SDL_SCANCODE_COPY = 124,
  SDL_SCANCODE_PASTE = 125,
  SDL_SCANCODE_FIND = 126,
  SDL_SCANCODE_MUTE = 127,
  SDL_SCANCODE_VOLUMEUP = 128,
  SDL_SCANCODE_VOLUMEDOWN = 129,
  SDL_SCANCODE_KP_COMMA = 133,
  SDL_SCANCODE_KP_EQUALSAS400 = 134,
  SDL_SCANCODE_INTERNATIONAL1 = 135,
  SDL_SCANCODE_INTERNATIONAL2 = 136,
  SDL_SCANCODE_INTERNATIONAL3 = 137,
  SDL_SCANCODE_INTERNATIONAL4 = 138,
  SDL_SCANCODE_INTERNATIONAL5 = 139,
  SDL_SCANCODE_INTERNATIONAL6 = 140,
  SDL_SCANCODE_INTERNATIONAL7 = 141,
  SDL_SCANCODE_INTERNATIONAL8 = 142,
  SDL_SCANCODE_INTERNATIONAL9 = 143,
  SDL_SCANCODE_LANG1 = 144,
  SDL_SCANCODE_LANG2 = 145,
  SDL_SCANCODE_LANG3 = 146,
  SDL_SCANCODE_LANG4 = 147,
  SDL_SCANCODE_LANG5 = 148,
  SDL_SCANCODE_LANG6 = 149,
  SDL_SCANCODE_LANG7 = 150,
  SDL_SCANCODE_LANG8 = 151,
  SDL_SCANCODE_LANG9 = 152,
  SDL_SCANCODE_ALTERASE = 153,
  SDL_SCANCODE_SYSREQ = 154,
  SDL_SCANCODE_CANCEL = 155,
  SDL_SCANCODE_CLEAR = 156,
  SDL_SCANCODE_PRIOR = 157,
  SDL_SCANCODE_RETURN2 = 158,
  SDL_SCANCODE_SEPARATOR = 159,
  SDL_SCANCODE_OUT = 160,
  SDL_SCANCODE_OPER = 161,
  SDL_SCANCODE_CLEARAGAIN = 162,
  SDL_SCANCODE_CRSEL = 163,
  SDL_SCANCODE_EXSEL = 164,
  SDL_SCANCODE_KP_00 = 176,
  SDL_SCANCODE_KP_000 = 177,
  SDL_SCANCODE_THOUSANDSSEPARATOR = 178,
  SDL_SCANCODE_DECIMALSEPARATOR = 179,
  SDL_SCANCODE_CURRENCYUNIT = 180,
  SDL_SCANCODE_CURRENCYSUBUNIT = 181,
  SDL_SCANCODE_KP_LEFTPAREN = 182,
  SDL_SCANCODE_KP_RIGHTPAREN = 183,
  SDL_SCANCODE_KP_LEFTBRACE = 184,
  SDL_SCANCODE_KP_RIGHTBRACE = 185,
  SDL_SCANCODE_KP_TAB = 186,
  SDL_SCANCODE_KP_BACKSPACE = 187,
  SDL_SCANCODE_KP_A = 188,
  SDL_SCANCODE_KP_B = 189,
  SDL_SCANCODE_KP_C = 190,
  SDL_SCANCODE_KP_D = 191,
  SDL_SCANCODE_KP_E = 192,
  SDL_SCANCODE_KP_F = 193,
  SDL_SCANCODE_KP_XOR = 194,
  SDL_SCANCODE_KP_POWER = 195,
  SDL_SCANCODE_KP_PERCENT = 196,
  SDL_SCANCODE_KP_LESS = 197,
  SDL_SCANCODE_KP_GREATER = 198,
  SDL_SCANCODE_KP_AMPERSAND = 199,
  SDL_SCANCODE_KP_DBLAMPERSAND = 200,
  SDL_SCANCODE_KP_VERTICALBAR = 201,
  SDL_SCANCODE_KP_DBLVERTICALBAR = 202,
  SDL_SCANCODE_KP_COLON = 203,
  SDL_SCANCODE_KP_HASH = 204,
  SDL_SCANCODE_KP_SPACE = 205,
  SDL_SCANCODE_KP_AT = 206,
  SDL_SCANCODE_KP_EXCLAM = 207,
  SDL_SCANCODE_KP_MEMSTORE = 208,
  SDL_SCANCODE_KP_MEMRECALL = 209,
  SDL_SCANCODE_KP_MEMCLEAR = 210,
  SDL_SCANCODE_KP_MEMADD = 211,
  SDL_SCANCODE_KP_MEMSUBTRACT = 212,
  SDL_SCANCODE_KP_MEMMULTIPLY = 213,
  SDL_SCANCODE_KP_MEMDIVIDE = 214,
  SDL_SCANCODE_KP_PLUSMINUS = 215,
  SDL_SCANCODE_KP_CLEAR = 216,
  SDL_SCANCODE_KP_CLEARENTRY = 217,
  SDL_SCANCODE_KP_BINARY = 218,
  SDL_SCANCODE_KP_OCTAL = 219,
  SDL_SCANCODE_KP_DECIMAL = 220,
  SDL_SCANCODE_KP_HEXADECIMAL = 221,
  SDL_SCANCODE_LCTRL = 224,
  SDL_SCANCODE_LSHIFT = 225,
  SDL_SCANCODE_LALT = 226,
  SDL_SCANCODE_LGUI = 227,
  SDL_SCANCODE_RCTRL = 228,
  SDL_SCANCODE_RSHIFT = 229,
  SDL_SCANCODE_RALT = 230,
  SDL_SCANCODE_RGUI = 231,
  SDL_SCANCODE_MODE = 257,
  SDL_SCANCODE_SLEEP = 258,
  SDL_SCANCODE_WAKE = 259,
  SDL_SCANCODE_CHANNEL_INCREMENT = 260,
  SDL_SCANCODE_CHANNEL_DECREMENT = 261,
  SDL_SCANCODE_MEDIA_PLAY = 262,
  SDL_SCANCODE_MEDIA_PAUSE = 263,
  SDL_SCANCODE_MEDIA_RECORD = 264,
  SDL_SCANCODE_MEDIA_FAST_FORWARD = 265,
  SDL_SCANCODE_MEDIA_REWIND = 266,
  SDL_SCANCODE_MEDIA_NEXT_TRACK = 267,
  SDL_SCANCODE_MEDIA_PREVIOUS_TRACK = 268,
  SDL_SCANCODE_MEDIA_STOP = 269,
  SDL_SCANCODE_MEDIA_EJECT = 270,
  SDL_SCANCODE_MEDIA_PLAY_PAUSE = 271,
  SDL_SCANCODE_MEDIA_SELECT = 272,
  SDL_SCANCODE_AC_NEW = 273,
  SDL_SCANCODE_AC_OPEN = 274,
  SDL_SCANCODE_AC_CLOSE = 275,
  SDL_SCANCODE_AC_EXIT = 276,
  SDL_SCANCODE_AC_SAVE = 277,
  SDL_SCANCODE_AC_PRINT = 278,
  SDL_SCANCODE_AC_PROPERTIES = 279,
  SDL_SCANCODE_AC_SEARCH = 280,
  SDL_SCANCODE_AC_HOME = 281,
  SDL_SCANCODE_AC_BACK = 282,
  SDL_SCANCODE_AC_FORWARD = 283,
  SDL_SCANCODE_AC_STOP = 284,
  SDL_SCANCODE_AC_REFRESH = 285,
  SDL_SCANCODE_AC_BOOKMARKS = 286,
  SDL_SCANCODE_SOFTLEFT = 287,
  SDL_SCANCODE_SOFTRIGHT = 288,
  SDL_SCANCODE_CALL = 289,
  SDL_SCANCODE_ENDCALL = 290,
  SDL_SCANCODE_RESERVED = 400,
  SDL_SCANCODE_COUNT = 512,
};
enum SDL_TextureAccess {
  SDL_TEXTUREACCESS_STATIC,
  SDL_TEXTUREACCESS_STREAMING,
  SDL_TEXTUREACCESS_TARGET,
};
typedef Uint32 SDL_AudioDeviceID;
typedef Uint32 SDL_CameraID;
typedef Uint32 SDL_DisplayID;
typedef struct SDL_DisplayModeData SDL_DisplayModeData;
typedef enum SDL_EventType SDL_EventType;
typedef struct SDL_FRect SDL_FRect;
typedef struct SDL_Finger SDL_Finger;
typedef Uint64 SDL_FingerID;
typedef struct SDL_Gamepad SDL_Gamepad;
typedef Uint32 SDL_InitFlags;
typedef Uint32 SDL_JoystickID;
typedef Uint32 SDL_KeyboardID;
typedef Uint32 SDL_Keycode;
typedef Uint16 SDL_Keymod;
typedef Uint32 SDL_MouseButtonFlags;
typedef Uint32 SDL_MouseID;
typedef enum SDL_MouseWheelDirection SDL_MouseWheelDirection;
typedef enum SDL_PenAxis SDL_PenAxis;
typedef Uint32 SDL_PenID;
typedef Uint32 SDL_PenInputFlags;
typedef enum SDL_PixelFormat SDL_PixelFormat;
typedef enum SDL_PowerState SDL_PowerState;
typedef struct SDL_Rect SDL_Rect;
typedef struct SDL_Renderer SDL_Renderer;
typedef enum SDL_Scancode SDL_Scancode;
typedef Uint32 SDL_SensorID;
typedef struct SDL_Surface SDL_Surface;
typedef struct SDL_Texture SDL_Texture;
typedef enum SDL_TextureAccess SDL_TextureAccess;
typedef Uint64 SDL_TouchID;
typedef struct SDL_Window SDL_Window;
typedef Uint64 SDL_WindowFlags;
typedef Uint32 SDL_WindowID;
struct SDL_Finger {
  SDL_FingerID id;
  float x;
  float y;
  float pressure;
};
struct SDL_Rect {
  int x, y;
  int w, h;
};
bool SDL_StartTextInput(SDL_Window *);
bool SDL_StopTextInput(SDL_Window *);
struct SDL_CommonEvent {
  Uint32 type;
  Uint32 reserved;
  Uint64 timestamp;
};
typedef struct SDL_CommonEvent SDL_CommonEvent;
struct SDL_DisplayEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_DisplayID displayID;
  Sint32 data1;
  Sint32 data2;
};
typedef struct SDL_DisplayEvent SDL_DisplayEvent;
struct SDL_WindowEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  Sint32 data1;
  Sint32 data2;
};
typedef struct SDL_WindowEvent SDL_WindowEvent;
struct SDL_KeyboardDeviceEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_KeyboardID which;
};
typedef struct SDL_KeyboardDeviceEvent SDL_KeyboardDeviceEvent;
struct SDL_KeyboardEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  SDL_KeyboardID which;
  SDL_Scancode scancode;
  SDL_Keycode key;
  SDL_Keymod mod;
  Uint16 raw;
  bool down;
  bool repeat;
};
typedef struct SDL_KeyboardEvent SDL_KeyboardEvent;
struct SDL_TextEditingEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  const char *text;
  Sint32 start;
  Sint32 length;
};
typedef struct SDL_TextEditingEvent SDL_TextEditingEvent;
struct SDL_TextEditingCandidatesEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  const char *const *candidates;
  Sint32 num_candidates;
  Sint32 selected_candidate;
  bool horizontal;
  Uint8 padding1;
  Uint8 padding2;
  Uint8 padding3;
};
typedef struct SDL_TextEditingCandidatesEvent SDL_TextEditingCandidatesEvent;
struct SDL_TextInputEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  const char *text;
};
typedef struct SDL_TextInputEvent SDL_TextInputEvent;
struct SDL_MouseDeviceEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_MouseID which;
};
typedef struct SDL_MouseDeviceEvent SDL_MouseDeviceEvent;
struct SDL_MouseMotionEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  SDL_MouseID which;
  SDL_MouseButtonFlags state;
  float x;
  float y;
  float xrel;
  float yrel;
};
typedef struct SDL_MouseMotionEvent SDL_MouseMotionEvent;
struct SDL_MouseButtonEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  SDL_MouseID which;
  Uint8 button;
  bool down;
  Uint8 clicks;
  Uint8 padding;
  float x;
  float y;
};
typedef struct SDL_MouseButtonEvent SDL_MouseButtonEvent;
struct SDL_MouseWheelEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  SDL_MouseID which;
  float x;
  float y;
  SDL_MouseWheelDirection direction;
  float mouse_x;
  float mouse_y;
  Sint32 integer_x;
  Sint32 integer_y;
};
typedef struct SDL_MouseWheelEvent SDL_MouseWheelEvent;
struct SDL_JoyDeviceEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_JoystickID which;
};
typedef struct SDL_JoyDeviceEvent SDL_JoyDeviceEvent;
struct SDL_JoyAxisEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_JoystickID which;
  Uint8 axis;
  Uint8 padding1;
  Uint8 padding2;
  Uint8 padding3;
  Sint16 value;
  Uint16 padding4;
};
typedef struct SDL_JoyAxisEvent SDL_JoyAxisEvent;
struct SDL_JoyBallEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_JoystickID which;
  Uint8 ball;
  Uint8 padding1;
  Uint8 padding2;
  Uint8 padding3;
  Sint16 xrel;
  Sint16 yrel;
};
typedef struct SDL_JoyBallEvent SDL_JoyBallEvent;
struct SDL_JoyHatEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_JoystickID which;
  Uint8 hat;
  Uint8 value;
  Uint8 padding1;
  Uint8 padding2;
};
typedef struct SDL_JoyHatEvent SDL_JoyHatEvent;
struct SDL_JoyButtonEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_JoystickID which;
  Uint8 button;
  bool down;
  Uint8 padding1;
  Uint8 padding2;
};
typedef struct SDL_JoyButtonEvent SDL_JoyButtonEvent;
struct SDL_JoyBatteryEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_JoystickID which;
  SDL_PowerState state;
  int percent;
};
typedef struct SDL_JoyBatteryEvent SDL_JoyBatteryEvent;
struct SDL_GamepadDeviceEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_JoystickID which;
};
typedef struct SDL_GamepadDeviceEvent SDL_GamepadDeviceEvent;
struct SDL_GamepadAxisEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_JoystickID which;
  Uint8 axis;
  Uint8 padding1;
  Uint8 padding2;
  Uint8 padding3;
  Sint16 value;
  Uint16 padding4;
};
typedef struct SDL_GamepadAxisEvent SDL_GamepadAxisEvent;
struct SDL_GamepadButtonEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_JoystickID which;
  Uint8 button;
  bool down;
  Uint8 padding1;
  Uint8 padding2;
};
typedef struct SDL_GamepadButtonEvent SDL_GamepadButtonEvent;
struct SDL_GamepadTouchpadEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_JoystickID which;
  Sint32 touchpad;
  Sint32 finger;
  float x;
  float y;
  float pressure;
};
typedef struct SDL_GamepadTouchpadEvent SDL_GamepadTouchpadEvent;
struct SDL_GamepadSensorEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_JoystickID which;
  Sint32 sensor;
  float data[3];
  Uint64 sensor_timestamp;
};
typedef struct SDL_GamepadSensorEvent SDL_GamepadSensorEvent;
struct SDL_AudioDeviceEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_AudioDeviceID which;
  bool recording;
  Uint8 padding1;
  Uint8 padding2;
  Uint8 padding3;
};
typedef struct SDL_AudioDeviceEvent SDL_AudioDeviceEvent;
struct SDL_CameraDeviceEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_CameraID which;
};
typedef struct SDL_CameraDeviceEvent SDL_CameraDeviceEvent;
struct SDL_SensorEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_SensorID which;
  float data[6];
  Uint64 sensor_timestamp;
};
typedef struct SDL_SensorEvent SDL_SensorEvent;
struct SDL_QuitEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
};
typedef struct SDL_QuitEvent SDL_QuitEvent;
struct SDL_UserEvent {
  Uint32 type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  Sint32 code;
  void *data1;
  void *data2;
};
typedef struct SDL_UserEvent SDL_UserEvent;
struct SDL_TouchFingerEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_TouchID touchID;
  SDL_FingerID fingerID;
  float x;
  float y;
  float dx;
  float dy;
  float pressure;
  SDL_WindowID windowID;
};
typedef struct SDL_TouchFingerEvent SDL_TouchFingerEvent;
struct SDL_PenProximityEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  SDL_PenID which;
};
typedef struct SDL_PenProximityEvent SDL_PenProximityEvent;
struct SDL_PenTouchEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  SDL_PenID which;
  SDL_PenInputFlags pen_state;
  float x;
  float y;
  bool eraser;
  bool down;
};
typedef struct SDL_PenTouchEvent SDL_PenTouchEvent;
struct SDL_PenMotionEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  SDL_PenID which;
  SDL_PenInputFlags pen_state;
  float x;
  float y;
};
typedef struct SDL_PenMotionEvent SDL_PenMotionEvent;
struct SDL_PenButtonEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  SDL_PenID which;
  SDL_PenInputFlags pen_state;
  float x;
  float y;
  Uint8 button;
  bool down;
};
typedef struct SDL_PenButtonEvent SDL_PenButtonEvent;
struct SDL_PenAxisEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  SDL_PenID which;
  SDL_PenInputFlags pen_state;
  float x;
  float y;
  SDL_PenAxis axis;
  float value;
};
typedef struct SDL_PenAxisEvent SDL_PenAxisEvent;
struct SDL_PinchFingerEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  float scale;
  SDL_WindowID windowID;
};
typedef struct SDL_PinchFingerEvent SDL_PinchFingerEvent;
struct SDL_RenderEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
};
typedef struct SDL_RenderEvent SDL_RenderEvent;
struct SDL_DropEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  SDL_WindowID windowID;
  float x;
  float y;
  const char *source;
  const char *data;
};
typedef struct SDL_DropEvent SDL_DropEvent;
struct SDL_ClipboardEvent {
  SDL_EventType type;
  Uint32 reserved;
  Uint64 timestamp;
  bool owner;
  Sint32 num_mime_types;
  const char **mime_types;
};
typedef struct SDL_ClipboardEvent SDL_ClipboardEvent;
union SDL_Event {
  Uint32 type;
  SDL_CommonEvent common;
  SDL_DisplayEvent display;
  SDL_WindowEvent window;
  SDL_KeyboardDeviceEvent kdevice;
  SDL_KeyboardEvent key;
  SDL_TextEditingEvent edit;
  SDL_TextEditingCandidatesEvent edit_candidates;
  SDL_TextInputEvent text;
  SDL_MouseDeviceEvent mdevice;
  SDL_MouseMotionEvent motion;
  SDL_MouseButtonEvent button;
  SDL_MouseWheelEvent wheel;
  SDL_JoyDeviceEvent jdevice;
  SDL_JoyAxisEvent jaxis;
  SDL_JoyBallEvent jball;
  SDL_JoyHatEvent jhat;
  SDL_JoyButtonEvent jbutton;
  SDL_JoyBatteryEvent jbattery;
  SDL_GamepadDeviceEvent gdevice;
  SDL_GamepadAxisEvent gaxis;
  SDL_GamepadButtonEvent gbutton;
  SDL_GamepadTouchpadEvent gtouchpad;
  SDL_GamepadSensorEvent gsensor;
  SDL_AudioDeviceEvent adevice;
  SDL_CameraDeviceEvent cdevice;
  SDL_SensorEvent sensor;
  SDL_QuitEvent quit;
  SDL_UserEvent user;
  SDL_TouchFingerEvent tfinger;
  SDL_PinchFingerEvent pinch;
  SDL_PenProximityEvent pproximity;
  SDL_PenTouchEvent ptouch;
  SDL_PenMotionEvent pmotion;
  SDL_PenButtonEvent pbutton;
  SDL_PenAxisEvent paxis;
  SDL_RenderEvent render;
  SDL_DropEvent drop;
  SDL_ClipboardEvent clipboard;
  Uint8 padding[128];
};
typedef union SDL_Event SDL_Event;
SDL_Renderer *SDL_CreateRenderer(SDL_Window *, const char *);
SDL_Texture *SDL_CreateTexture(SDL_Renderer *, SDL_PixelFormat, SDL_TextureAccess, int, int);
SDL_Window *SDL_CreateWindow(const char *, int, int, SDL_WindowFlags);
void SDL_DestroyRenderer(SDL_Renderer *);
void SDL_DestroyTexture(SDL_Texture *);
bool SDL_EnableScreenSaver(void);
bool SDL_GetCurrentRenderOutputSize(SDL_Renderer *, int *, int *);
const char *SDL_GetCurrentVideoDriver(void);
bool SDL_GetWindowSize(SDL_Window *, int *, int *);
bool SDL_Init(SDL_InitFlags);
bool SDL_InitSubSystem(SDL_InitFlags);
void SDL_Quit(void);
void SDL_QuitSubSystem(SDL_InitFlags);
bool SDL_RenderClear(SDL_Renderer *);
bool SDL_RenderPresent(SDL_Renderer *);
bool SDL_RenderTexture(SDL_Renderer *, SDL_Texture *, const SDL_FRect *, const SDL_FRect *);
void SDL_SetMainReady(void);
bool SDL_SetWindowPosition(SDL_Window *, int, int);
bool SDL_SetWindowTitle(SDL_Window *, const char *);
bool SDL_UpdateTexture(SDL_Texture *, const SDL_Rect *, const void *, int);
bool SDL_WaitEventTimeout(SDL_Event *, Sint32);
SDL_InitFlags SDL_WasInit(SDL_InitFlags);
struct SDL_DisplayMode {
  SDL_DisplayID displayID;
  SDL_PixelFormat format;
  int w;
  int h;
  float pixel_density;
  float refresh_rate;
  int refresh_rate_numerator;
  int refresh_rate_denominator;
  SDL_DisplayModeData *internal;
};
typedef struct SDL_DisplayMode SDL_DisplayMode;
SDL_DisplayID SDL_GetPrimaryDisplay(void);
const SDL_DisplayMode *SDL_GetCurrentDisplayMode(SDL_DisplayID);
SDL_Surface *SDL_CreateSurfaceFrom(int, int, SDL_PixelFormat, void *, int);
bool SDL_SetWindowIcon(SDL_Window *, SDL_Surface *);
void SDL_DestroySurface(SDL_Surface *);
bool SDL_SetWindowFullscreen(SDL_Window *, bool);
bool SDL_SyncWindow(SDL_Window *);
const char *SDL_GetBasePath(void);
SDL_PowerState SDL_GetPowerInfo(int *, int *);
const char *SDL_GetPlatform(void);
bool SDL_HasClipboardText(void);
char *SDL_GetClipboardText(void);
bool SDL_SetClipboardText(const char *);
const char *SDL_GetError(void);
bool SDL_SetHint(const char *, const char *);
SDL_JoystickID *SDL_GetJoysticks(int *);
bool SDL_IsGamepad(SDL_JoystickID);
const char *SDL_GetGamepadNameForID(SDL_JoystickID);
SDL_Gamepad *SDL_OpenGamepad(SDL_JoystickID);
void SDL_CloseGamepad(SDL_Gamepad *);
SDL_Finger **SDL_GetTouchFingers(SDL_TouchID, int *);
int SDL_GetVersion(void);
void SDL_free(void *);
]]
