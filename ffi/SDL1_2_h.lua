local ffi = require("ffi")

ffi.cdef[[
typedef unsigned int Uint32;
typedef int Sint32;
typedef short unsigned int Uint16;
typedef short int Sint16;
typedef unsigned char Uint8;
typedef signed char Sint8;
struct SDL_keysym {
  Uint8 scancode;
  enum {
    SDLK_UNKNOWN = 0,
    SDLK_FIRST = 0,
    SDLK_BACKSPACE = 8,
    SDLK_TAB = 9,
    SDLK_CLEAR = 12,
    SDLK_RETURN = 13,
    SDLK_PAUSE = 19,
    SDLK_ESCAPE = 27,
    SDLK_SPACE = 32,
    SDLK_EXCLAIM = 33,
    SDLK_QUOTEDBL = 34,
    SDLK_HASH = 35,
    SDLK_DOLLAR = 36,
    SDLK_AMPERSAND = 38,
    SDLK_QUOTE = 39,
    SDLK_LEFTPAREN = 40,
    SDLK_RIGHTPAREN = 41,
    SDLK_ASTERISK = 42,
    SDLK_PLUS = 43,
    SDLK_COMMA = 44,
    SDLK_MINUS = 45,
    SDLK_PERIOD = 46,
    SDLK_SLASH = 47,
    SDLK_0 = 48,
    SDLK_1 = 49,
    SDLK_2 = 50,
    SDLK_3 = 51,
    SDLK_4 = 52,
    SDLK_5 = 53,
    SDLK_6 = 54,
    SDLK_7 = 55,
    SDLK_8 = 56,
    SDLK_9 = 57,
    SDLK_COLON = 58,
    SDLK_SEMICOLON = 59,
    SDLK_LESS = 60,
    SDLK_EQUALS = 61,
    SDLK_GREATER = 62,
    SDLK_QUESTION = 63,
    SDLK_AT = 64,
    SDLK_LEFTBRACKET = 91,
    SDLK_BACKSLASH = 92,
    SDLK_RIGHTBRACKET = 93,
    SDLK_CARET = 94,
    SDLK_UNDERSCORE = 95,
    SDLK_BACKQUOTE = 96,
    SDLK_a = 97,
    SDLK_b = 98,
    SDLK_c = 99,
    SDLK_d = 100,
    SDLK_e = 101,
    SDLK_f = 102,
    SDLK_g = 103,
    SDLK_h = 104,
    SDLK_i = 105,
    SDLK_j = 106,
    SDLK_k = 107,
    SDLK_l = 108,
    SDLK_m = 109,
    SDLK_n = 110,
    SDLK_o = 111,
    SDLK_p = 112,
    SDLK_q = 113,
    SDLK_r = 114,
    SDLK_s = 115,
    SDLK_t = 116,
    SDLK_u = 117,
    SDLK_v = 118,
    SDLK_w = 119,
    SDLK_x = 120,
    SDLK_y = 121,
    SDLK_z = 122,
    SDLK_DELETE = 127,
    SDLK_WORLD_0 = 160,
    SDLK_WORLD_1 = 161,
    SDLK_WORLD_2 = 162,
    SDLK_WORLD_3 = 163,
    SDLK_WORLD_4 = 164,
    SDLK_WORLD_5 = 165,
    SDLK_WORLD_6 = 166,
    SDLK_WORLD_7 = 167,
    SDLK_WORLD_8 = 168,
    SDLK_WORLD_9 = 169,
    SDLK_WORLD_10 = 170,
    SDLK_WORLD_11 = 171,
    SDLK_WORLD_12 = 172,
    SDLK_WORLD_13 = 173,
    SDLK_WORLD_14 = 174,
    SDLK_WORLD_15 = 175,
    SDLK_WORLD_16 = 176,
    SDLK_WORLD_17 = 177,
    SDLK_WORLD_18 = 178,
    SDLK_WORLD_19 = 179,
    SDLK_WORLD_20 = 180,
    SDLK_WORLD_21 = 181,
    SDLK_WORLD_22 = 182,
    SDLK_WORLD_23 = 183,
    SDLK_WORLD_24 = 184,
    SDLK_WORLD_25 = 185,
    SDLK_WORLD_26 = 186,
    SDLK_WORLD_27 = 187,
    SDLK_WORLD_28 = 188,
    SDLK_WORLD_29 = 189,
    SDLK_WORLD_30 = 190,
    SDLK_WORLD_31 = 191,
    SDLK_WORLD_32 = 192,
    SDLK_WORLD_33 = 193,
    SDLK_WORLD_34 = 194,
    SDLK_WORLD_35 = 195,
    SDLK_WORLD_36 = 196,
    SDLK_WORLD_37 = 197,
    SDLK_WORLD_38 = 198,
    SDLK_WORLD_39 = 199,
    SDLK_WORLD_40 = 200,
    SDLK_WORLD_41 = 201,
    SDLK_WORLD_42 = 202,
    SDLK_WORLD_43 = 203,
    SDLK_WORLD_44 = 204,
    SDLK_WORLD_45 = 205,
    SDLK_WORLD_46 = 206,
    SDLK_WORLD_47 = 207,
    SDLK_WORLD_48 = 208,
    SDLK_WORLD_49 = 209,
    SDLK_WORLD_50 = 210,
    SDLK_WORLD_51 = 211,
    SDLK_WORLD_52 = 212,
    SDLK_WORLD_53 = 213,
    SDLK_WORLD_54 = 214,
    SDLK_WORLD_55 = 215,
    SDLK_WORLD_56 = 216,
    SDLK_WORLD_57 = 217,
    SDLK_WORLD_58 = 218,
    SDLK_WORLD_59 = 219,
    SDLK_WORLD_60 = 220,
    SDLK_WORLD_61 = 221,
    SDLK_WORLD_62 = 222,
    SDLK_WORLD_63 = 223,
    SDLK_WORLD_64 = 224,
    SDLK_WORLD_65 = 225,
    SDLK_WORLD_66 = 226,
    SDLK_WORLD_67 = 227,
    SDLK_WORLD_68 = 228,
    SDLK_WORLD_69 = 229,
    SDLK_WORLD_70 = 230,
    SDLK_WORLD_71 = 231,
    SDLK_WORLD_72 = 232,
    SDLK_WORLD_73 = 233,
    SDLK_WORLD_74 = 234,
    SDLK_WORLD_75 = 235,
    SDLK_WORLD_76 = 236,
    SDLK_WORLD_77 = 237,
    SDLK_WORLD_78 = 238,
    SDLK_WORLD_79 = 239,
    SDLK_WORLD_80 = 240,
    SDLK_WORLD_81 = 241,
    SDLK_WORLD_82 = 242,
    SDLK_WORLD_83 = 243,
    SDLK_WORLD_84 = 244,
    SDLK_WORLD_85 = 245,
    SDLK_WORLD_86 = 246,
    SDLK_WORLD_87 = 247,
    SDLK_WORLD_88 = 248,
    SDLK_WORLD_89 = 249,
    SDLK_WORLD_90 = 250,
    SDLK_WORLD_91 = 251,
    SDLK_WORLD_92 = 252,
    SDLK_WORLD_93 = 253,
    SDLK_WORLD_94 = 254,
    SDLK_WORLD_95 = 255,
    SDLK_KP0 = 256,
    SDLK_KP1 = 257,
    SDLK_KP2 = 258,
    SDLK_KP3 = 259,
    SDLK_KP4 = 260,
    SDLK_KP5 = 261,
    SDLK_KP6 = 262,
    SDLK_KP7 = 263,
    SDLK_KP8 = 264,
    SDLK_KP9 = 265,
    SDLK_KP_PERIOD = 266,
    SDLK_KP_DIVIDE = 267,
    SDLK_KP_MULTIPLY = 268,
    SDLK_KP_MINUS = 269,
    SDLK_KP_PLUS = 270,
    SDLK_KP_ENTER = 271,
    SDLK_KP_EQUALS = 272,
    SDLK_UP = 273,
    SDLK_DOWN = 274,
    SDLK_RIGHT = 275,
    SDLK_LEFT = 276,
    SDLK_INSERT = 277,
    SDLK_HOME = 278,
    SDLK_END = 279,
    SDLK_PAGEUP = 280,
    SDLK_PAGEDOWN = 281,
    SDLK_F1 = 282,
    SDLK_F2 = 283,
    SDLK_F3 = 284,
    SDLK_F4 = 285,
    SDLK_F5 = 286,
    SDLK_F6 = 287,
    SDLK_F7 = 288,
    SDLK_F8 = 289,
    SDLK_F9 = 290,
    SDLK_F10 = 291,
    SDLK_F11 = 292,
    SDLK_F12 = 293,
    SDLK_F13 = 294,
    SDLK_F14 = 295,
    SDLK_F15 = 296,
    SDLK_NUMLOCK = 300,
    SDLK_CAPSLOCK = 301,
    SDLK_SCROLLOCK = 302,
    SDLK_RSHIFT = 303,
    SDLK_LSHIFT = 304,
    SDLK_RCTRL = 305,
    SDLK_LCTRL = 306,
    SDLK_RALT = 307,
    SDLK_LALT = 308,
    SDLK_RMETA = 309,
    SDLK_LMETA = 310,
    SDLK_LSUPER = 311,
    SDLK_RSUPER = 312,
    SDLK_MODE = 313,
    SDLK_COMPOSE = 314,
    SDLK_HELP = 315,
    SDLK_PRINT = 316,
    SDLK_SYSREQ = 317,
    SDLK_BREAK = 318,
    SDLK_MENU = 319,
    SDLK_POWER = 320,
    SDLK_EURO = 321,
    SDLK_UNDO = 322,
    SDLK_LAST = 323,
  } sym;
  enum {
    KMOD_NONE = 0,
    KMOD_LSHIFT = 1,
    KMOD_RSHIFT = 2,
    KMOD_LCTRL = 64,
    KMOD_RCTRL = 128,
    KMOD_LALT = 256,
    KMOD_RALT = 512,
    KMOD_LMETA = 1024,
    KMOD_RMETA = 2048,
    KMOD_NUM = 4096,
    KMOD_CAPS = 8192,
    KMOD_MODE = 16384,
    KMOD_RESERVED = 32768,
  } mod;
  Uint16 unicode;
};
typedef enum {
  SDL_NOEVENT = 0,
  SDL_ACTIVEEVENT = 1,
  SDL_KEYDOWN = 2,
  SDL_KEYUP = 3,
  SDL_MOUSEMOTION = 4,
  SDL_MOUSEBUTTONDOWN = 5,
  SDL_MOUSEBUTTONUP = 6,
  SDL_JOYAXISMOTION = 7,
  SDL_JOYBALLMOTION = 8,
  SDL_JOYHATMOTION = 9,
  SDL_JOYBUTTONDOWN = 10,
  SDL_JOYBUTTONUP = 11,
  SDL_QUIT = 12,
  SDL_SYSWMEVENT = 13,
  SDL_EVENT_RESERVEDA = 14,
  SDL_EVENT_RESERVEDB = 15,
  SDL_VIDEORESIZE = 16,
  SDL_VIDEOEXPOSE = 17,
  SDL_EVENT_RESERVED2 = 18,
  SDL_EVENT_RESERVED3 = 19,
  SDL_EVENT_RESERVED4 = 20,
  SDL_EVENT_RESERVED5 = 21,
  SDL_EVENT_RESERVED6 = 22,
  SDL_EVENT_RESERVED7 = 23,
  SDL_USEREVENT = 24,
  SDL_NUMEVENTS = 32,
} SDL_EventType;
typedef enum {
  SDL_ACTIVEEVENTMASK = 2,
  SDL_KEYDOWNMASK = 4,
  SDL_KEYUPMASK = 8,
  SDL_KEYEVENTMASK = 12,
  SDL_MOUSEMOTIONMASK = 16,
  SDL_MOUSEBUTTONDOWNMASK = 32,
  SDL_MOUSEBUTTONUPMASK = 64,
  SDL_MOUSEEVENTMASK = 112,
  SDL_JOYAXISMOTIONMASK = 128,
  SDL_JOYBALLMOTIONMASK = 256,
  SDL_JOYHATMOTIONMASK = 512,
  SDL_JOYBUTTONDOWNMASK = 1024,
  SDL_JOYBUTTONUPMASK = 2048,
  SDL_JOYEVENTMASK = 3968,
  SDL_VIDEORESIZEMASK = 65536,
  SDL_VIDEOEXPOSEMASK = 131072,
  SDL_QUITMASK = 4096,
  SDL_SYSWMEVENTMASK = 8192,
} SDL_EventMask;
struct SDL_ActiveEvent {
  Uint8 type;
  Uint8 gain;
  Uint8 state;
};
struct SDL_KeyboardEvent {
  Uint8 type;
  Uint8 which;
  Uint8 state;
  struct SDL_keysym keysym;
};
struct SDL_MouseMotionEvent {
  Uint8 type;
  Uint8 which;
  Uint8 state;
  Uint16 x;
  Uint16 y;
  Sint16 xrel;
  Sint16 yrel;
};
struct SDL_MouseButtonEvent {
  Uint8 type;
  Uint8 which;
  Uint8 button;
  Uint8 state;
  Uint16 x;
  Uint16 y;
};
struct SDL_JoyAxisEvent {
  Uint8 type;
  Uint8 which;
  Uint8 axis;
  Sint16 value;
};
struct SDL_JoyBallEvent {
  Uint8 type;
  Uint8 which;
  Uint8 ball;
  Sint16 xrel;
  Sint16 yrel;
};
struct SDL_JoyHatEvent {
  Uint8 type;
  Uint8 which;
  Uint8 hat;
  Uint8 value;
};
struct SDL_JoyButtonEvent {
  Uint8 type;
  Uint8 which;
  Uint8 button;
  Uint8 state;
};
struct SDL_ResizeEvent {
  Uint8 type;
  int w;
  int h;
};
struct SDL_ExposeEvent {
  Uint8 type;
};
struct SDL_QuitEvent {
  Uint8 type;
};
struct SDL_UserEvent {
  Uint8 type;
  int code;
  void *data1;
  void *data2;
};
struct SDL_SysWMEvent {
  Uint8 type;
  struct SDL_SysWMmsg *msg;
};
union SDL_Event {
  Uint8 type;
  struct SDL_ActiveEvent active;
  struct SDL_KeyboardEvent key;
  struct SDL_MouseMotionEvent motion;
  struct SDL_MouseButtonEvent button;
  struct SDL_JoyAxisEvent jaxis;
  struct SDL_JoyBallEvent jball;
  struct SDL_JoyHatEvent jhat;
  struct SDL_JoyButtonEvent jbutton;
  struct SDL_ResizeEvent resize;
  struct SDL_ExposeEvent expose;
  struct SDL_QuitEvent quit;
  struct SDL_UserEvent user;
  struct SDL_SysWMEvent syswm;
};
struct SDL_Rect {
  Sint16 x;
  Sint16 y;
  Uint16 w;
  Uint16 h;
};
struct SDL_Color {
  Uint8 r;
  Uint8 g;
  Uint8 b;
  Uint8 unused;
};
struct SDL_Palette {
  int ncolors;
  struct SDL_Color *colors;
};
struct SDL_PixelFormat {
  struct SDL_Palette *palette;
  Uint8 BitsPerPixel;
  Uint8 BytesPerPixel;
  Uint8 Rloss;
  Uint8 Gloss;
  Uint8 Bloss;
  Uint8 Aloss;
  Uint8 Rshift;
  Uint8 Gshift;
  Uint8 Bshift;
  Uint8 Ashift;
  Uint32 Rmask;
  Uint32 Gmask;
  Uint32 Bmask;
  Uint32 Amask;
  Uint32 colorkey;
  Uint8 alpha;
};
struct SDL_Surface {
  Uint32 flags;
  struct SDL_PixelFormat *format;
  int w;
  int h;
  Uint16 pitch;
  void *pixels;
  int offset;
  struct private_hwdata *hwdata;
  struct SDL_Rect clip_rect;
  Uint32 unused1;
  Uint32 locked;
  struct SDL_BlitMap *map;
  unsigned int format_version;
  int refcount;
};
int SDL_Init(Uint32) __attribute__((visibility("default")));
Uint32 SDL_WasInit(Uint32) __attribute__((visibility("default")));
void SDL_Quit(void) __attribute__((visibility("default")));
struct SDL_Surface *SDL_SetVideoMode(int, int, int, Uint32) __attribute__((visibility("default")));
int SDL_EnableKeyRepeat(int, int) __attribute__((visibility("default")));
int SDL_WaitEvent(union SDL_Event *) __attribute__((visibility("default")));
int SDL_PollEvent(union SDL_Event *) __attribute__((visibility("default")));
Uint32 SDL_GetTicks(void) __attribute__((visibility("default")));
void SDL_Delay(Uint32) __attribute__((visibility("default")));
int SDL_LockSurface(struct SDL_Surface *) __attribute__((visibility("default")));
void SDL_UnlockSurface(struct SDL_Surface *) __attribute__((visibility("default")));
int SDL_FillRect(struct SDL_Surface *, struct SDL_Rect *, Uint32) __attribute__((visibility("default")));
int SDL_Flip(struct SDL_Surface *) __attribute__((visibility("default")));
Uint32 SDL_MapRGB(const struct SDL_PixelFormat *const, const Uint8, const Uint8, const Uint8) __attribute__((visibility("default")));
static const int SDL_INIT_TIMER = 1;
static const int SDL_INIT_AUDIO = 16;
static const int SDL_INIT_VIDEO = 32;
static const int SDL_INIT_CDROM = 256;
static const int SDL_INIT_JOYSTICK = 512;
static const int SDL_INIT_NOPARACHUTE = 1048576;
static const int SDL_INIT_EVENTTHREAD = 16777216;
static const int SDL_INIT_EVERYTHING = 65535;
static const int SDL_SWSURFACE = 0;
static const int SDL_HWSURFACE = 1;
static const int SDL_ASYNCBLIT = 4;
static const int SDL_ANYFORMAT = 268435456;
static const int SDL_HWPALETTE = 536870912;
static const int SDL_DOUBLEBUF = 1073741824;
static const int SDL_FULLSCREEN = 2147483648;
static const int SDL_OPENGL = 2;
static const int SDL_OPENGLBLIT = 10;
static const int SDL_RESIZABLE = 16;
static const int SDL_NOFRAME = 32;
static const int SDL_HWACCEL = 256;
static const int SDL_SRCCOLORKEY = 4096;
static const int SDL_RLEACCELOK = 8192;
static const int SDL_RLEACCEL = 16384;
static const int SDL_SRCALPHA = 65536;
static const int SDL_PREALLOC = 16777216;
]]
