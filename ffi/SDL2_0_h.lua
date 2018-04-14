local ffi = require("ffi")
ffi.cdef[[
typedef unsigned int Uint32;
typedef int Sint32;
typedef short unsigned int Uint16;
typedef short int Sint16;
typedef unsigned char Uint8;
typedef signed char Sint8;
typedef int64_t Sint64;
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
  short unsigned int mod;
  unsigned int unused;
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
  SDL_USEREVENT = 32768,
  SDL_LASTEVENT = 65535,
} SDL_EventType;
struct SDL_CommonEvent {
  unsigned int type;
  unsigned int timestamp;
};
struct SDL_WindowEvent {
  unsigned int type;
  unsigned int timestamp;
  unsigned int windowID;
  unsigned char event;
  unsigned char padding1;
  unsigned char padding2;
  unsigned char padding3;
  int data1;
  int data2;
};

/**
 *  \brief Event subtype for window events
 */
typedef enum
{
    SDL_WINDOWEVENT_NONE,           /**< Never used */
    SDL_WINDOWEVENT_SHOWN,          /**< Window has been shown */
    SDL_WINDOWEVENT_HIDDEN,         /**< Window has been hidden */
    SDL_WINDOWEVENT_EXPOSED,        /**< Window has been exposed and should be
                                         redrawn */
    SDL_WINDOWEVENT_MOVED,          /**< Window has been moved to data1, data2
                                     */
    SDL_WINDOWEVENT_RESIZED,        /**< Window has been resized to data1xdata2 */
    SDL_WINDOWEVENT_SIZE_CHANGED,   /**< The window size has changed, either as
                                         a result of an API call or through the
                                         system or user changing the window size. */
    SDL_WINDOWEVENT_MINIMIZED,      /**< Window has been minimized */
    SDL_WINDOWEVENT_MAXIMIZED,      /**< Window has been maximized */
    SDL_WINDOWEVENT_RESTORED,       /**< Window has been restored to normal size
                                         and position */
    SDL_WINDOWEVENT_ENTER,          /**< Window has gained mouse focus */
    SDL_WINDOWEVENT_LEAVE,          /**< Window has lost mouse focus */
    SDL_WINDOWEVENT_FOCUS_GAINED,   /**< Window has gained keyboard focus */
    SDL_WINDOWEVENT_FOCUS_LOST,     /**< Window has lost keyboard focus */
    SDL_WINDOWEVENT_CLOSE,          /**< The window manager requests that the window be closed */
    SDL_WINDOWEVENT_TAKE_FOCUS,     /**< Window is being offered a focus (should SetWindowInputFocus() on itself or a subwindow, or ignore) */
    SDL_WINDOWEVENT_HIT_TEST        /**< Window had a hit test that wasn't SDL_HITTEST_NORMAL. */
} SDL_WindowEventID;

struct SDL_KeyboardEvent {
  unsigned int type;
  unsigned int timestamp;
  unsigned int windowID;
  unsigned char state;
  unsigned char repeat;
  unsigned char padding2;
  unsigned char padding3;
  struct SDL_Keysym keysym;
};
struct SDL_TextEditingEvent {
  unsigned int type;
  unsigned int timestamp;
  unsigned int windowID;
  char text[32];
  int start;
  int length;
};
struct SDL_TextInputEvent {
  unsigned int type;
  unsigned int timestamp;
  unsigned int windowID;
  char text[32];
};
struct SDL_MouseMotionEvent {
  unsigned int type;
  unsigned int timestamp;
  unsigned int windowID;
  unsigned int which;
  unsigned int state;
  int x;
  int y;
  int xrel;
  int yrel;
};
struct SDL_MouseButtonEvent {
  unsigned int type;
  unsigned int timestamp;
  unsigned int windowID;
  unsigned int which;
  unsigned char button;
  unsigned char state;
  unsigned char padding1;
  unsigned char padding2;
  int x;
  int y;
};
struct SDL_MouseWheelEvent {
  unsigned int type;
  unsigned int timestamp;
  unsigned int windowID;
  unsigned int which;
  int x;
  int y;
};
struct SDL_JoyAxisEvent {
  unsigned int type;
  unsigned int timestamp;
  int which;
  unsigned char axis;
  unsigned char padding1;
  unsigned char padding2;
  unsigned char padding3;
  short int value;
  short unsigned int padding4;
};
struct SDL_JoyBallEvent {
  unsigned int type;
  unsigned int timestamp;
  int which;
  unsigned char ball;
  unsigned char padding1;
  unsigned char padding2;
  unsigned char padding3;
  short int xrel;
  short int yrel;
};
struct SDL_JoyHatEvent {
  unsigned int type;
  unsigned int timestamp;
  int which;
  unsigned char hat;
  unsigned char value;
  unsigned char padding1;
  unsigned char padding2;
};
struct SDL_JoyButtonEvent {
  unsigned int type;
  unsigned int timestamp;
  int which;
  unsigned char button;
  unsigned char state;
  unsigned char padding1;
  unsigned char padding2;
};
struct SDL_JoyDeviceEvent {
  unsigned int type;
  unsigned int timestamp;
  int which;
};
struct SDL_ControllerAxisEvent {
  unsigned int type;
  unsigned int timestamp;
  int which;
  unsigned char axis;
  unsigned char padding1;
  unsigned char padding2;
  unsigned char padding3;
  short int value;
  short unsigned int padding4;
};
struct SDL_ControllerButtonEvent {
  unsigned int type;
  unsigned int timestamp;
  int which;
  unsigned char button;
  unsigned char state;
  unsigned char padding1;
  unsigned char padding2;
};
struct SDL_ControllerDeviceEvent {
  unsigned int type;
  unsigned int timestamp;
  int which;
};
struct SDL_QuitEvent {
  unsigned int type;
  unsigned int timestamp;
};
struct SDL_UserEvent {
  unsigned int type;
  unsigned int timestamp;
  unsigned int windowID;
  int code;
  void *data1;
  void *data2;
};
struct SDL_DisplayMode {
  unsigned int format;
  int w;
  int h;
  int refresh_rate;
  void *data;
};
struct SDL_SysWMEvent {
  unsigned int type;
  unsigned int timestamp;
  struct SDL_SysWMmsg *msg;
};
struct SDL_TouchFingerEvent {
  unsigned int type;
  unsigned int timestamp;
  Sint64 touchId;
  Sint64 fingerId;
  float x;
  float y;
  float dx;
  float dy;
  float pressure;
};
struct SDL_MultiGestureEvent {
  unsigned int type;
  unsigned int timestamp;
  Sint64 touchId;
  float dTheta;
  float dDist;
  float x;
  float y;
  short unsigned int numFingers;
  short unsigned int padding;
};
struct SDL_DollarGestureEvent {
  unsigned int type;
  unsigned int timestamp;
  Sint64 touchId;
  Sint64 gestureId;
  unsigned int numFingers;
  float error;
  float x;
  float y;
};
struct SDL_DropEvent {
  unsigned int type;
  unsigned int timestamp;
  char *file;
};
union SDL_Event {
  unsigned int type;
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
  unsigned char padding[56];
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
int SDL_Init(unsigned int) __attribute__((visibility("default")));
unsigned int SDL_WasInit(unsigned int) __attribute__((visibility("default")));
void SDL_SetMainReady(void) __attribute__((visibility("default")));
void SDL_Quit(void) __attribute__((visibility("default")));
int SDL_WaitEvent(union SDL_Event *) __attribute__((visibility("default")));
int SDL_WaitEventTimeout(union SDL_Event *, int) __attribute__((visibility("default")));
int SDL_PollEvent(union SDL_Event *) __attribute__((visibility("default")));
unsigned int SDL_GetTicks(void) __attribute__((visibility("default")));
void SDL_Delay(unsigned int) __attribute__((visibility("default")));
int SDL_GetCurrentDisplayMode(int, struct SDL_DisplayMode*) __attribute__((visibility("default")));
struct SDL_Window *SDL_CreateWindow(const char *, int, int, int, int, unsigned int) __attribute__((visibility("default")));
struct SDL_Renderer *SDL_CreateRenderer(struct SDL_Window *, int, unsigned int) __attribute__((visibility("default")));
int SDL_CreateWindowAndRenderer(int, int, unsigned int, struct SDL_Window **, struct SDL_Renderer **) __attribute__((visibility("default")));
int SDL_SetRenderDrawColor(struct SDL_Renderer *, unsigned char, unsigned char, unsigned char, unsigned char) __attribute__((visibility("default")));
int SDL_RenderClear(struct SDL_Renderer *) __attribute__((visibility("default")));
void SDL_RenderPresent(struct SDL_Renderer *) __attribute__((visibility("default")));
int SDL_RenderCopy(struct SDL_Renderer *, struct SDL_Texture *, const struct SDL_Rect *, const struct SDL_Rect *) __attribute__((visibility("default")));
struct SDL_Texture *SDL_CreateTexture(struct SDL_Renderer *, unsigned int, int, int, int) __attribute__((visibility("default")));
int SDL_UpdateTexture(struct SDL_Texture *, const struct SDL_Rect *, const void *, int) __attribute__((visibility("default")));
void SDL_DestroyTexture(SDL_Texture* texture);
typedef struct SDL_Color
{
    Uint8 r;
    Uint8 g;
    Uint8 b;
    Uint8 a;
} SDL_Color;
typedef struct SDL_Palette
{
    int ncolors;
    SDL_Color *colors;
    Uint32 version;
    int refcount;
} SDL_Palette;
typedef struct SDL_PixelFormat
{
    Uint32 format;
    SDL_Palette *palette;
    Uint8 BitsPerPixel;
    Uint8 BytesPerPixel;
    Uint8 padding[2];
    Uint32 Rmask;
    Uint32 Gmask;
    Uint32 Bmask;
    Uint32 Amask;
    Uint8 Rloss;
    Uint8 Gloss;
    Uint8 Bloss;
    Uint8 Aloss;
    Uint8 Rshift;
    Uint8 Gshift;
    Uint8 Bshift;
    Uint8 Ashift;
    int refcount;
    struct SDL_PixelFormat *next;
} SDL_PixelFormat;
typedef enum
{
    SDL_BLENDMODE_NONE = 0x00000000,
    SDL_BLENDMODE_BLEND = 0x00000001,
    SDL_BLENDMODE_ADD = 0x00000002,
    SDL_BLENDMODE_MOD = 0x00000004
} SDL_BlendMode;
typedef struct SDL_Surface
{
    Uint32 flags;
    SDL_PixelFormat *format;
    int w, h;
    int pitch;
    void *pixels;
    void *userdata;
    int locked;
    void *lock_data;
    SDL_Rect clip_rect;
    struct SDL_BlitMap *map;
    int refcount;
} SDL_Surface;
typedef int (*SDL_blit) (struct SDL_Surface * src, SDL_Rect * srcrect,
                         struct SDL_Surface * dst, SDL_Rect * dstrect);
SDL_Surface * SDL_CreateRGBSurface
    (Uint32 flags, int width, int height, int depth,
     Uint32 Rmask, Uint32 Gmask, Uint32 Bmask, Uint32 Amask);
SDL_Surface * SDL_CreateRGBSurfaceFrom(void *pixels,
                                                    int width,
                                                    int height,
                                                    int depth,
                                                    int pitch,
                                                    Uint32 Rmask,
                                                    Uint32 Gmask,
                                                    Uint32 Bmask,
                                                    Uint32 Amask);
SDL_Surface* SDL_CreateRGBSurfaceWithFormatFrom(void*  pixels,
                                                int    width,
                                                int    height,
                                                int    depth,
                                                int    pitch,
                                                Uint32 format);
void SDL_FreeSurface(SDL_Surface * surface);
int SDL_SetSurfacePalette(SDL_Surface * surface,
                                                  SDL_Palette * palette);
int SDL_LockSurface(SDL_Surface * surface);
void SDL_UnlockSurface(SDL_Surface * surface);
void SDL_SetWindowIcon(SDL_Window * window,
                                           SDL_Surface * icon);
void SDL_SetWindowTitle(struct SDL_Window *, const char *) __attribute__((visibility("default")));
typedef enum SDL_bool {
    SDL_FALSE = 0,
    SDL_TRUE  = 1
} SDL_bool;
SDL_bool SDL_HasClipboardText(void);
char* SDL_GetClipboardText(void);
int SDL_SetClipboardText(const char* text);
const char* SDL_GetError(void);
struct _SDL_Joystick;
typedef struct _SDL_Joystick SDL_Joystick;
typedef struct {
    Uint8 data[16];
} SDL_JoystickGUID;
typedef Sint32 SDL_JoystickID;
int SDL_NumJoysticks(void);
const char * SDL_JoystickNameForIndex(int device_index);
SDL_Joystick * SDL_JoystickOpen(int device_index);
const char * SDL_JoystickName(SDL_Joystick * joystick);
SDL_JoystickGUID SDL_JoystickGetDeviceGUID(int device_index);
SDL_JoystickGUID SDL_JoystickGetGUID(SDL_Joystick * joystick);
void SDL_JoystickGetGUIDString(SDL_JoystickGUID guid, char *pszGUID, int cbGUID);
SDL_JoystickGUID SDL_JoystickGetGUIDFromString(const char *pchGUID);
SDL_bool SDL_JoystickGetAttached(SDL_Joystick * joystick);
SDL_JoystickID SDL_JoystickInstanceID(SDL_Joystick * joystick);
int SDL_JoystickNumAxes(SDL_Joystick * joystick);
int SDL_JoystickNumBalls(SDL_Joystick * joystick);
int SDL_JoystickNumHats(SDL_Joystick * joystick);
int SDL_JoystickNumButtons(SDL_Joystick * joystick);
void SDL_JoystickUpdate(void);
int SDL_JoystickEventState(int state);
Sint16 SDL_JoystickGetAxis(SDL_Joystick * joystick,
                                                   int axis);
Uint8 SDL_JoystickGetHat(SDL_Joystick * joystick,
                                                 int hat);
int SDL_JoystickGetBall(SDL_Joystick * joystick,
                                                int ball, int *dx, int *dy);
Uint8 SDL_JoystickGetButton(SDL_Joystick * joystick,
                                                    int button);
void SDL_JoystickClose(SDL_Joystick * joystick);
struct _SDL_GameController;
typedef struct _SDL_GameController SDL_GameController;
typedef enum
{
    SDL_CONTROLLER_BINDTYPE_NONE = 0,
    SDL_CONTROLLER_BINDTYPE_BUTTON,
    SDL_CONTROLLER_BINDTYPE_AXIS,
    SDL_CONTROLLER_BINDTYPE_HAT
} SDL_GameControllerBindType;
typedef struct SDL_GameControllerButtonBind
{
    SDL_GameControllerBindType bindType;
    union
    {
        int button;
        int axis;
        struct {
            int hat;
            int hat_mask;
        } hat;
    } value;
} SDL_GameControllerButtonBind;
int SDL_GameControllerAddMapping( const char* mappingString );
char * SDL_GameControllerMappingForGUID( SDL_JoystickGUID guid );
char * SDL_GameControllerMapping( SDL_GameController * gamecontroller );
SDL_bool SDL_IsGameController(int joystick_index);
const char * SDL_GameControllerNameForIndex(int joystick_index);
SDL_GameController * SDL_GameControllerOpen(int joystick_index);
const char * SDL_GameControllerName(SDL_GameController *gamecontroller);
SDL_bool SDL_GameControllerGetAttached(SDL_GameController *gamecontroller);
SDL_Joystick * SDL_GameControllerGetJoystick(SDL_GameController *gamecontroller);
int SDL_GameControllerEventState(int state);
void SDL_GameControllerUpdate(void);
typedef enum
{
    SDL_CONTROLLER_AXIS_INVALID = -1,
    SDL_CONTROLLER_AXIS_LEFTX,
    SDL_CONTROLLER_AXIS_LEFTY,
    SDL_CONTROLLER_AXIS_RIGHTX,
    SDL_CONTROLLER_AXIS_RIGHTY,
    SDL_CONTROLLER_AXIS_TRIGGERLEFT,
    SDL_CONTROLLER_AXIS_TRIGGERRIGHT,
    SDL_CONTROLLER_AXIS_MAX
} SDL_GameControllerAxis;
SDL_GameControllerAxis SDL_GameControllerGetAxisFromString(const char *pchString);
const char* SDL_GameControllerGetStringForAxis(SDL_GameControllerAxis axis);
SDL_GameControllerButtonBind
SDL_GameControllerGetBindForAxis(SDL_GameController *gamecontroller,
                                 SDL_GameControllerAxis axis);
Sint16
SDL_GameControllerGetAxis(SDL_GameController *gamecontroller,
                          SDL_GameControllerAxis axis);
typedef enum
{
    SDL_CONTROLLER_BUTTON_INVALID = -1,
    SDL_CONTROLLER_BUTTON_A,
    SDL_CONTROLLER_BUTTON_B,
    SDL_CONTROLLER_BUTTON_X,
    SDL_CONTROLLER_BUTTON_Y,
    SDL_CONTROLLER_BUTTON_BACK,
    SDL_CONTROLLER_BUTTON_GUIDE,
    SDL_CONTROLLER_BUTTON_START,
    SDL_CONTROLLER_BUTTON_LEFTSTICK,
    SDL_CONTROLLER_BUTTON_RIGHTSTICK,
    SDL_CONTROLLER_BUTTON_LEFTSHOULDER,
    SDL_CONTROLLER_BUTTON_RIGHTSHOULDER,
    SDL_CONTROLLER_BUTTON_DPAD_UP,
    SDL_CONTROLLER_BUTTON_DPAD_DOWN,
    SDL_CONTROLLER_BUTTON_DPAD_LEFT,
    SDL_CONTROLLER_BUTTON_DPAD_RIGHT,
    SDL_CONTROLLER_BUTTON_MAX
} SDL_GameControllerButton;
SDL_GameControllerButton SDL_GameControllerGetButtonFromString(const char *pchString);
const char* SDL_GameControllerGetStringForButton(SDL_GameControllerButton button);
SDL_GameControllerButtonBind
SDL_GameControllerGetBindForButton(SDL_GameController *gamecontroller,
                                   SDL_GameControllerButton button);
Uint8 SDL_GameControllerGetButton(SDL_GameController *gamecontroller,
                                                          SDL_GameControllerButton button);
void SDL_GameControllerClose(SDL_GameController *gamecontroller);
enum {
SDL_HAT_CENTERED    = 0x00,
SDL_HAT_UP          = 0x01,
SDL_HAT_RIGHT       = 0x02,
SDL_HAT_DOWN        = 0x04,
SDL_HAT_LEFT        = 0x08,
SDL_HAT_RIGHTUP     = (SDL_HAT_RIGHT|SDL_HAT_UP),
SDL_HAT_RIGHTDOWN   = (SDL_HAT_RIGHT|SDL_HAT_DOWN),
SDL_HAT_LEFTUP      = (SDL_HAT_LEFT|SDL_HAT_UP),
SDL_HAT_LEFTDOWN    = (SDL_HAT_LEFT|SDL_HAT_DOWN)
};
typedef Sint64 SDL_TouchID;
typedef Sint64 SDL_FingerID;
typedef struct SDL_Finger
{
    SDL_FingerID id;
    float x;
    float y;
    float pressure;
} SDL_Finger;
int SDL_GetNumTouchDevices(void);
SDL_TouchID SDL_GetTouchDevice(int index);
int SDL_GetNumTouchFingers(SDL_TouchID touchID);
SDL_Finger * SDL_GetTouchFinger(SDL_TouchID touchID, int index);
enum {
SDL_INIT_TIMER          = 0x00000001,
SDL_INIT_AUDIO          = 0x00000010,
SDL_INIT_VIDEO          = 0x00000020,
SDL_INIT_JOYSTICK       = 0x00000200,
SDL_INIT_HAPTIC         = 0x00001000,
SDL_INIT_GAMECONTROLLER = 0x00002000,
SDL_INIT_EVENTS         = 0x00004000,
SDL_INIT_NOPARACHUTE    = 0x00100000,
SDL_INIT_EVERYTHING     = ( SDL_INIT_TIMER | SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_JOYSTICK | SDL_INIT_HAPTIC | SDL_INIT_GAMECONTROLLER )
};
static const int SDL_WINDOWPOS_UNDEFINED = 536805376;
static const int SDL_WINDOW_FULLSCREEN = 1;
static const int SDL_WINDOW_FULLSCREEN_DESKTOP = 4097;
static const int SDL_WINDOW_RESIZABLE = 32;
typedef enum
{
    SDL_TEXTUREACCESS_STATIC,
    SDL_TEXTUREACCESS_STREAMING,
    SDL_TEXTUREACCESS_TARGET
} SDL_TextureAccess;
static const int SDL_PIXELFORMAT_ARGB8888 = 372645892;
static const int SDL_PIXELFORMAT_RGBA8888 = 373694468;
static const int SDL_PIXELFORMAT_ABGR8888 = 376840196;
]]
