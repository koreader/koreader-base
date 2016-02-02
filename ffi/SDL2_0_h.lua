local ffi = require("ffi")

ffi.cdef[[
typedef unsigned int Uint32;
typedef int Sint32;
typedef short unsigned int Uint16;
typedef short int Sint16;
typedef unsigned char Uint8;
typedef signed char Sint8;
struct SDL_Keysym {
  enum {
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
    SDL_SCANCODE_AUDIONEXT = 258,
    SDL_SCANCODE_AUDIOPREV = 259,
    SDL_SCANCODE_AUDIOSTOP = 260,
    SDL_SCANCODE_AUDIOPLAY = 261,
    SDL_SCANCODE_AUDIOMUTE = 262,
    SDL_SCANCODE_MEDIASELECT = 263,
    SDL_SCANCODE_WWW = 264,
    SDL_SCANCODE_MAIL = 265,
    SDL_SCANCODE_CALCULATOR = 266,
    SDL_SCANCODE_COMPUTER = 267,
    SDL_SCANCODE_AC_SEARCH = 268,
    SDL_SCANCODE_AC_HOME = 269,
    SDL_SCANCODE_AC_BACK = 270,
    SDL_SCANCODE_AC_FORWARD = 271,
    SDL_SCANCODE_AC_STOP = 272,
    SDL_SCANCODE_AC_REFRESH = 273,
    SDL_SCANCODE_AC_BOOKMARKS = 274,
    SDL_SCANCODE_BRIGHTNESSDOWN = 275,
    SDL_SCANCODE_BRIGHTNESSUP = 276,
    SDL_SCANCODE_DISPLAYSWITCH = 277,
    SDL_SCANCODE_KBDILLUMTOGGLE = 278,
    SDL_SCANCODE_KBDILLUMDOWN = 279,
    SDL_SCANCODE_KBDILLUMUP = 280,
    SDL_SCANCODE_EJECT = 281,
    SDL_SCANCODE_SLEEP = 282,
    SDL_SCANCODE_APP1 = 283,
    SDL_SCANCODE_APP2 = 284,
    SDL_NUM_SCANCODES = 512,
  } scancode;
  int sym;
  Uint16 mod;
  Uint32 unused;
};
typedef enum {
  SDL_FIRSTEVENT = 0,
  SDL_QUIT = 256,
  SDL_APP_TERMINATING = 257,
  SDL_APP_LOWMEMORY = 258,
  SDL_APP_WILLENTERBACKGROUND = 259,
  SDL_APP_DIDENTERBACKGROUND = 260,
  SDL_APP_WILLENTERFOREGROUND = 261,
  SDL_APP_DIDENTERFOREGROUND = 262,
  SDL_WINDOWEVENT = 512,
  SDL_SYSWMEVENT = 513,
  SDL_KEYDOWN = 768,
  SDL_KEYUP = 769,
  SDL_TEXTEDITING = 770,
  SDL_TEXTINPUT = 771,
  SDL_MOUSEMOTION = 1024,
  SDL_MOUSEBUTTONDOWN = 1025,
  SDL_MOUSEBUTTONUP = 1026,
  SDL_MOUSEWHEEL = 1027,
  SDL_JOYAXISMOTION = 1536,
  SDL_JOYBALLMOTION = 1537,
  SDL_JOYHATMOTION = 1538,
  SDL_JOYBUTTONDOWN = 1539,
  SDL_JOYBUTTONUP = 1540,
  SDL_JOYDEVICEADDED = 1541,
  SDL_JOYDEVICEREMOVED = 1542,
  SDL_CONTROLLERAXISMOTION = 1616,
  SDL_CONTROLLERBUTTONDOWN = 1617,
  SDL_CONTROLLERBUTTONUP = 1618,
  SDL_CONTROLLERDEVICEADDED = 1619,
  SDL_CONTROLLERDEVICEREMOVED = 1620,
  SDL_CONTROLLERDEVICEREMAPPED = 1621,
  SDL_FINGERDOWN = 1792,
  SDL_FINGERUP = 1793,
  SDL_FINGERMOTION = 1794,
  SDL_DOLLARGESTURE = 2048,
  SDL_DOLLARRECORD = 2049,
  SDL_MULTIGESTURE = 2050,
  SDL_CLIPBOARDUPDATE = 2304,
  SDL_DROPFILE = 4096,
  SDL_RENDER_TARGETS_RESET = 8192,
  SDL_USEREVENT = 32768,
  SDL_LASTEVENT = 65535,
} SDL_EventType;
struct SDL_CommonEvent {
  Uint32 type;
  Uint32 timestamp;
};
struct SDL_WindowEvent {
  Uint32 type;
  Uint32 timestamp;
  Uint32 windowID;
  Uint8 event;
  Uint8 padding1;
  Uint8 padding2;
  Uint8 padding3;
  Sint32 data1;
  Sint32 data2;
};
struct SDL_KeyboardEvent {
  Uint32 type;
  Uint32 timestamp;
  Uint32 windowID;
  Uint8 state;
  Uint8 repeat;
  Uint8 padding2;
  Uint8 padding3;
  struct SDL_Keysym keysym;
};
struct SDL_TextEditingEvent {
  Uint32 type;
  Uint32 timestamp;
  Uint32 windowID;
  char text[32];
  Sint32 start;
  Sint32 length;
};
struct SDL_TextInputEvent {
  Uint32 type;
  Uint32 timestamp;
  Uint32 windowID;
  char text[32];
};
struct SDL_MouseMotionEvent {
  Uint32 type;
  Uint32 timestamp;
  Uint32 windowID;
  Uint32 which;
  Uint32 state;
  Sint32 x;
  Sint32 y;
  Sint32 xrel;
  Sint32 yrel;
};
struct SDL_MouseButtonEvent {
  Uint32 type;
  Uint32 timestamp;
  Uint32 windowID;
  Uint32 which;
  Uint8 button;
  Uint8 state;
  Uint8 clicks;
  Uint8 padding1;
  Sint32 x;
  Sint32 y;
};
struct SDL_MouseWheelEvent {
  Uint32 type;
  Uint32 timestamp;
  Uint32 windowID;
  Uint32 which;
  Sint32 x;
  Sint32 y;
};
struct SDL_JoyAxisEvent {
  Uint32 type;
  Uint32 timestamp;
  int which;
  Uint8 axis;
  Uint8 padding1;
  Uint8 padding2;
  Uint8 padding3;
  Sint16 value;
  Uint16 padding4;
};
struct SDL_JoyBallEvent {
  Uint32 type;
  Uint32 timestamp;
  int which;
  Uint8 ball;
  Uint8 padding1;
  Uint8 padding2;
  Uint8 padding3;
  Sint16 xrel;
  Sint16 yrel;
};
struct SDL_JoyHatEvent {
  Uint32 type;
  Uint32 timestamp;
  int which;
  Uint8 hat;
  Uint8 value;
  Uint8 padding1;
  Uint8 padding2;
};
struct SDL_JoyButtonEvent {
  Uint32 type;
  Uint32 timestamp;
  int which;
  Uint8 button;
  Uint8 state;
  Uint8 padding1;
  Uint8 padding2;
};
struct SDL_JoyDeviceEvent {
  Uint32 type;
  Uint32 timestamp;
  Sint32 which;
};
struct SDL_ControllerAxisEvent {
  Uint32 type;
  Uint32 timestamp;
  int which;
  Uint8 axis;
  Uint8 padding1;
  Uint8 padding2;
  Uint8 padding3;
  Sint16 value;
  Uint16 padding4;
};
struct SDL_ControllerButtonEvent {
  Uint32 type;
  Uint32 timestamp;
  int which;
  Uint8 button;
  Uint8 state;
  Uint8 padding1;
  Uint8 padding2;
};
struct SDL_ControllerDeviceEvent {
  Uint32 type;
  Uint32 timestamp;
  Sint32 which;
};
struct SDL_QuitEvent {
  Uint32 type;
  Uint32 timestamp;
};
struct SDL_UserEvent {
  Uint32 type;
  Uint32 timestamp;
  Uint32 windowID;
  Sint32 code;
  void *data1;
  void *data2;
};
struct SDL_SysWMEvent {
  Uint32 type;
  Uint32 timestamp;
  struct SDL_SysWMmsg *msg;
};
struct SDL_TouchFingerEvent {
  Uint32 type;
  Uint32 timestamp;
  long int touchId;
  long int fingerId;
  float x;
  float y;
  float dx;
  float dy;
  float pressure;
};
struct SDL_MultiGestureEvent {
  Uint32 type;
  Uint32 timestamp;
  long int touchId;
  float dTheta;
  float dDist;
  float x;
  float y;
  Uint16 numFingers;
  Uint16 padding;
};
struct SDL_DollarGestureEvent {
  Uint32 type;
  Uint32 timestamp;
  long int touchId;
  long int gestureId;
  Uint32 numFingers;
  float error;
  float x;
  float y;
};
struct SDL_DropEvent {
  Uint32 type;
  Uint32 timestamp;
  char *file;
};
union SDL_Event {
  Uint32 type;
  struct SDL_CommonEvent common;
  struct SDL_WindowEvent window;
  struct SDL_KeyboardEvent key;
  struct SDL_TextEditingEvent edit;
  struct SDL_TextInputEvent text;
  struct SDL_MouseMotionEvent motion;
  struct SDL_MouseButtonEvent button;
  struct SDL_MouseWheelEvent wheel;
  struct SDL_JoyAxisEvent jaxis;
  struct SDL_JoyBallEvent jball;
  struct SDL_JoyHatEvent jhat;
  struct SDL_JoyButtonEvent jbutton;
  struct SDL_JoyDeviceEvent jdevice;
  struct SDL_ControllerAxisEvent caxis;
  struct SDL_ControllerButtonEvent cbutton;
  struct SDL_ControllerDeviceEvent cdevice;
  struct SDL_QuitEvent quit;
  struct SDL_UserEvent user;
  struct SDL_SysWMEvent syswm;
  struct SDL_TouchFingerEvent tfinger;
  struct SDL_MultiGestureEvent mgesture;
  struct SDL_DollarGestureEvent dgesture;
  struct SDL_DropEvent drop;
  Uint8 padding[56];
};
struct SDL_Rect {
  int x;
  int y;
  int w;
  int h;
};
typedef struct SDL_Rect SDL_Rect;
struct SDL_Window;
typedef struct SDL_Window SDL_Window;
struct SDL_Renderer;
typedef struct SDL_Renderer SDL_Renderer;
struct SDL_Texture;
typedef struct SDL_Texture SDL_Texture;
int SDL_Init(Uint32) __attribute__((visibility("default")));
Uint32 SDL_WasInit(Uint32) __attribute__((visibility("default")));
void SDL_SetMainReady(void) __attribute__((visibility("default")));
void SDL_Quit(void) __attribute__((visibility("default")));
int SDL_WaitEvent(union SDL_Event *) __attribute__((visibility("default")));
int SDL_WaitEventTimeout(union SDL_Event *, int) __attribute__((visibility("default")));
int SDL_PollEvent(union SDL_Event *) __attribute__((visibility("default")));
Uint32 SDL_GetTicks(void) __attribute__((visibility("default")));
void SDL_Delay(Uint32) __attribute__((visibility("default")));
SDL_Window *SDL_CreateWindow(const char *, int, int, int, int, Uint32) __attribute__((visibility("default")));
SDL_Renderer *SDL_CreateRenderer(SDL_Window *, int, Uint32) __attribute__((visibility("default")));
int SDL_CreateWindowAndRenderer(int, int, Uint32, SDL_Window **, SDL_Renderer **) __attribute__((visibility("default")));
int SDL_SetRenderDrawColor(SDL_Renderer *, Uint8, Uint8, Uint8, Uint8) __attribute__((visibility("default")));
int SDL_RenderClear(SDL_Renderer *) __attribute__((visibility("default")));
void SDL_RenderPresent(SDL_Renderer *) __attribute__((visibility("default")));
int SDL_RenderCopy(SDL_Renderer *, SDL_Texture *, const SDL_Rect *, const SDL_Rect *) __attribute__((visibility("default")));
SDL_Texture *SDL_CreateTexture(SDL_Renderer *, Uint32, int, int, int) __attribute__((visibility("default")));
int SDL_UpdateTexture(SDL_Texture *, const SDL_Rect *, const void *, int) __attribute__((visibility("default")));
void SDL_SetWindowTitle(SDL_Window *, const char *) __attribute__((visibility("default")));
static const int SDL_INIT_AUDIO = 16;
static const int SDL_INIT_VIDEO = 32;
static const int SDL_INIT_EVENTS = 16384;
static const int SDL_WINDOWPOS_UNDEFINED = 536805376;
static const int SDL_WINDOWPOS_CENTERED = 805240832;
static const int SDL_WINDOW_FULLSCREEN = 1;
static const int SDL_WINDOW_FULLSCREEN_DESKTOP = 4097;
static const int SDL_TEXTUREACCESS_STREAMING = 1;
static const int SDL_PIXELFORMAT_ARGB8888 = 372645892;
]]
