-- Automatically generated with ./utils/gen_inkview_h.py.

local ffi = require("ffi")
local C = ffi.C

local target_version
for __, version in ipairs{ 505, 507, 508, 509, 511, 512, 514, 515, 517, 519, 605, 608, 610, 611 } do
    if C.POCKETBOOK_VERSION >= version then
        target_version = version
    end
end
if not target_version then
    error("unsupported PocketBook software version: " .. tonumber(C.POCKETBOOK_VERSION))
end
print("target PocketBook software version: " ..  target_version)

require "ffi/posix_h"

ffi.cdef[[
static const unsigned MSG_REBOOT = 272;
static const unsigned EVT_ACTIVATE = 38;
static const unsigned EVT_BACKGROUND = 152;
static const unsigned EVT_BT_RXCOMPLETE = 171;
static const unsigned EVT_BT_TXCOMPLETE = 172;
static const unsigned EVT_CALLBACK = 212;
static const unsigned EVT_CONFIGCHANGED = 154;
static const unsigned EVT_DIC_CLOSED = 201;
static const unsigned EVT_EXIT = 22;
static const unsigned EVT_EXT_KB = 210;
static const unsigned EVT_FOCUS = 36;
static const unsigned EVT_FOREGROUND = 151;
static const unsigned EVT_FSCHANGED = 73;
static const unsigned EVT_FSINCOMING = 72;
static const unsigned EVT_GLOBALACTION = 150;
static const unsigned EVT_GLOBALREQUEST = 149;
static const unsigned EVT_HIDE = 24;
static const unsigned EVT_INIT = 21;
static const unsigned EVT_KEYPRESS = 25;
static const unsigned EVT_KEYRELEASE = 26;
static const unsigned EVT_KEYREPEAT = 28;
static const unsigned EVT_LETTER = 211;
static const unsigned EVT_MP_STATECHANGED = 81;
static const unsigned EVT_MP_TRACKCHANGED = 82;
static const unsigned EVT_MTSYNC = 39;
static const unsigned EVT_NEXTPAGE = 92;
static const unsigned EVT_OBREEY_CONFIG_CHANGED = 156;
static const unsigned EVT_OPENDIC = 93;
static const unsigned EVT_ORIENTATION = 32;
static const unsigned EVT_PANEL = 120;
static const unsigned EVT_PANEL_BLUETOOTH = 128;
static const unsigned EVT_PANEL_BLUETOOTH_A2DP = 118;
static const unsigned EVT_PANEL_CLOCK = 127;
static const unsigned EVT_PANEL_FRONT_LIGHT = 133;
static const unsigned EVT_PANEL_ICON = 121;
static const unsigned EVT_PANEL_MPLAYER = 124;
static const unsigned EVT_PANEL_NETWORK = 126;
static const unsigned EVT_PANEL_OBREEY_SYNC = 130;
static const unsigned EVT_PANEL_PROGRESS = 123;
static const unsigned EVT_PANEL_SETREADINGMODE = 131;
static const unsigned EVT_PANEL_SETREADINGMODE_INVERT = 132;
static const unsigned EVT_PANEL_TASKLIST = 129;
static const unsigned EVT_PANEL_TEXT = 122;
static const unsigned EVT_PANEL_USBDRIVE = 125;
static const unsigned EVT_POINTERDOWN = 30;
static const unsigned EVT_POINTERDRAG = 44;
static const unsigned EVT_POINTERHOLD = 35;
static const unsigned EVT_POINTERLONG = 34;
static const unsigned EVT_POINTERMOVE = 31;
static const unsigned EVT_POINTERUP = 29;
static const unsigned EVT_PREVPAGE = 91;
static const unsigned EVT_QN_BORDER = 53;
static const unsigned EVT_QN_MOVE = 51;
static const unsigned EVT_QN_RELEASE = 52;
]]

if target_version == 505 then
ffi.cdef[[ static const unsigned EVT_REPAINT = 23; ]]
end

if 507 <= target_version and target_version <= 611 then
ffi.cdef[[ static const unsigned EVT_REPAINT = 43; ]]
end

ffi.cdef[[
static const unsigned EVT_SAVESTATE = 155;
static const unsigned EVT_SCANPROGRESS = 213;
static const unsigned EVT_SCANSTOPPED = 216;
static const unsigned EVT_SCROLL = 33;
static const unsigned EVT_SDIN = 161;
static const unsigned EVT_SDOUT = 162;
static const unsigned EVT_SHOW = 23;
static const unsigned EVT_SNAPSHOT = 71;
static const unsigned EVT_STARTSCAN = 215;
static const unsigned EVT_STOPSCAN = 214;
static const unsigned EVT_SUBTASKCLOSE = 153;
static const unsigned EVT_SYNTH_ENDED = 200;
static const unsigned EVT_TAB = 119;
static const unsigned EVT_TEXTCLEAR = 209;
]]

if 505 <= target_version and target_version <= 519 then
ffi.cdef[[
static const unsigned EVT_TOUCHDOWN = 41;
static const unsigned EVT_TOUCHMOVE = 42;
static const unsigned EVT_TOUCHUP = 40;
]]
end

if 605 <= target_version and target_version <= 611 then
ffi.cdef[[
static const unsigned EVT_TOUCHDOWN = 48;
static const unsigned EVT_TOUCHMOVE = 49;
static const unsigned EVT_TOUCHUP = 47;
]]
end

ffi.cdef[[
static const unsigned EVT_UNFOCUS = 37;
static const unsigned EVT_CONTROL_PANEL_ABOUT_TO_OPEN = 94;
static const unsigned EVT_NET_CONNECTED = 256;
static const unsigned EVT_NET_DISCONNECTED = 257;
static const unsigned EVT_NET_FOUND_NEW_FW = 260;
static const unsigned EVT_POSTPONE_TIMED_POWEROFF = 217;
]]

if 507 <= target_version and target_version <= 611 then
ffi.cdef[[
static const unsigned EVT_FRAME_ACTIVATED = 218;
static const unsigned EVT_FRAME_DEACTIVATED = 219;
static const unsigned EVT_POINTERCANCEL = 45;
]]
end

if 511 <= target_version and target_version <= 611 then
ffi.cdef[[ static const unsigned EVT_READ_PROGRESS_CHANGED = 220; ]]
end

if 519 <= target_version and target_version <= 611 then
ffi.cdef[[
static const unsigned EVT_ASYNC_TASK_FINISHED = 262;
static const unsigned EVT_AUDIO_CHANGED = 265;
static const unsigned EVT_AVRCP_COMMAND = 264;
static const unsigned EVT_DUMP_BITMAPS_DEBUG_INFO = 221;
static const unsigned EVT_STOP_PLAYING = 263;
static const unsigned EVT_SYNTH_POSITION = 261;
static const unsigned EVT_UPDATE = 95;
]]
end

if target_version == 605 then
ffi.cdef[[ static const unsigned EVT_CUSTOM = 267; ]]
end

if 605 <= target_version and target_version <= 611 then
ffi.cdef[[
static const unsigned EVT_KEYPRESS_EXT = 40;
static const unsigned EVT_KEYRELEASE_EXT = 41;
static const unsigned EVT_KEYREPEAT_EXT = 42;
static const unsigned EVT_PACKAGE_JOB_CHANGED = 266;
static const unsigned EVT_POINTERCHANGED = 46;
static const unsigned EVT_USBSTORE_IN = 163;
static const unsigned EVT_USBSTORE_OUT = 164;
]]
end

if target_version == 608 then
ffi.cdef[[ static const unsigned EVT_CUSTOM = 269; ]]
end

if 610 <= target_version and target_version <= 611 then
ffi.cdef[[ static const unsigned EVT_CUSTOM = 1024; ]]
end

ffi.cdef[[
static const unsigned IV_KEY_0 = 48;
static const unsigned IV_KEY_1 = 49;
static const unsigned IV_KEY_2 = 50;
static const unsigned IV_KEY_3 = 51;
static const unsigned IV_KEY_4 = 52;
static const unsigned IV_KEY_5 = 53;
static const unsigned IV_KEY_6 = 54;
static const unsigned IV_KEY_7 = 55;
static const unsigned IV_KEY_8 = 56;
static const unsigned IV_KEY_9 = 57;
static const unsigned IV_KEY_BACK = 27;
static const unsigned IV_KEY_COVERCLOSE = 3;
static const unsigned IV_KEY_COVEROPEN = 2;
static const unsigned IV_KEY_DELETE = 8;
static const unsigned IV_KEY_DOWN = 18;
static const unsigned IV_KEY_HOME = 26;
static const unsigned IV_KEY_KEYBOARDCLOSE = 16;
static const unsigned IV_KEY_LANGUAGECHANGE = 15;
static const unsigned IV_KEY_LEFT = 19;
static const unsigned IV_KEY_MENU = 23;
static const unsigned IV_KEY_MINUS = 21;
static const unsigned IV_KEY_MUSIC = 30;
static const unsigned IV_KEY_NEXT = 25;
static const unsigned IV_KEY_NEXT2 = 29;
static const unsigned IV_KEY_OK = 10;
static const unsigned IV_KEY_PLUS = 22;
static const unsigned IV_KEY_POWER = 1;
static const unsigned IV_KEY_PREV = 24;
static const unsigned IV_KEY_PREV2 = 28;
static const unsigned IV_KEY_RIGHT = 20;
static const unsigned IV_KEY_SHIFT = 14;
static const unsigned IV_KEY_UP = 17;
static const unsigned IV_KEY_ZOOMIN = 7;
static const unsigned IV_KEY_ZOOMOUT = 6;
]]

if 519 <= target_version and target_version <= 611 then
ffi.cdef[[ static const unsigned IV_KEY_MENU_POWER = 4; ]]
end

if 605 <= target_version and target_version <= 611 then
ffi.cdef[[ static const unsigned IV_KEY_MAX = 32; ]]
end

ffi.cdef[[
static const unsigned NET_CONNECTED = 3840;
static const unsigned NET_OK = 0;
static const unsigned REQ_KEYLOCK = 65;
]]

if 505 <= target_version and target_version <= 519 then
ffi.cdef[[
enum input_dev_e {
  UNKNOWN = 0,
  CAPTOUCH,
  DIGITIZER,
  MAX_INPUT_DEV,
};
]]
end

if 605 <= target_version and target_version <= 611 then
ffi.cdef[[
enum input_dev_e {
  DEV_UNKNOWN = 0,
  TP_CAPACITIVE,
  TP_DIGITIZER,
  MAX_INPUT_TOUCH_DEV,
  INPUT_DEV_KEYBOARD_HW,
  INPUT_DEV_KEYBOARD_BT,
  INPUT_DEV_KEYBOARD_USB,
};
]]
end

if target_version == 611 then
ffi.cdef[[
typedef struct {
  int active;
  int x;
  int y;
} hw_event_data_slot;
]]
end

ffi.cdef[[
struct hw_event_data_common_s {
  int mod;
  int par1;
  int par2;
};
typedef struct hw_event_data_common_s hw_event_data_common;
]]

if 505 <= target_version and target_version <= 608 then
ffi.cdef[[
struct hw_event_data_pointer_s {
  int id;
  int x;
  int y;
  int pressure;
  enum input_dev_e devtype;
};
]]
end

if target_version == 610 then
ffi.cdef[[
struct hw_event_data_pointer_s {
  int id;
  int x;
  int y;
  int pressure;
  int tilt_x;
  int tilt_y;
  enum input_dev_e devtype;
};
]]
end

if target_version == 611 then
ffi.cdef[[
struct hw_event_data_pointer_s {
  int id;
  int x;
  int y;
  int pressure;
  int tilt_x;
  int tilt_y;
  enum input_dev_e devtype;
  uint32_t tools;
};
]]
end

ffi.cdef[[ typedef struct hw_event_data_pointer_s hw_event_data_pointer; ]]

if 505 <= target_version and target_version <= 610 then
ffi.cdef[[
struct hw_event_s {
  int type;
  union {
    hw_event_data_common common;
    hw_event_data_pointer pointer;
  };
  struct timeval time;
};
]]
end

if target_version == 611 then
ffi.cdef[[
struct hw_event_s {
  int type;
  struct timeval time;
  union {
    hw_event_data_common common;
    hw_event_data_pointer pointer;
    hw_event_data_slot mt[3];
  };
};
]]
end

ffi.cdef[[ typedef struct hw_event_s hw_event; ]]

if 505 <= target_version and target_version <= 605 then
ffi.cdef[[
struct icanvas_s {
  int width;
  int height;
  int scanline;
  int depth;
  int clipx1, clipx2;
  int clipy1, clipy2;
  unsigned char *addr;
};
]]
end

if 608 <= target_version and target_version <= 611 then
ffi.cdef[[
struct icanvas_s {
  int width;
  int height;
  int scanline;
  int depth;
  int clipx1, clipx2;
  int clipy1, clipy2;
  uint8_t *addr;
};
]]
end

ffi.cdef[[
typedef struct icanvas_s icanvas;
typedef struct iconfig_s iconfig;
typedef int (*iv_handler)(int type, int par1, int par2);
]]

if 505 <= target_version and target_version <= 519 then
ffi.cdef[[
struct iv_mtinfo_s {
  int active;
  int x;
  int y;
  int pressure;
  enum input_dev_e devtype;
  int rsv_2;
  long long timems;
};
]]
end

if 505 <= target_version and target_version <= 610 then
ffi.cdef[[ typedef struct iv_mtinfo_s iv_mtinfo; ]]
end

if 505 <= target_version and target_version <= 517 then
ffi.cdef[[
typedef enum {
  PANEL_DISABLED = 0,
  PANEL_ENABLED = 1 << 1,
  PANEL_EVENT_NO_HANDLING = 1 << 2,
} PANEL_FLAGS;
]]
end

if target_version == 519 then
ffi.cdef[[
typedef enum {
  PANEL_DISABLED = 0,
  PANEL_ENABLED = 1 << 1,
  PANEL_EVENT_NO_HANDLING = 1 << 2,
  PANEL_NO_FB_OFFSET = 1 << 3,
} PANEL_FLAGS;
]]
end

if 605 <= target_version and target_version <= 608 then
ffi.cdef[[
struct iv_mtinfo_s {
  bool active;
  int x;
  int y;
  int pressure;
  enum input_dev_e devtype;
  long long timems;
};
]]
end

if 605 <= target_version and target_version <= 611 then
ffi.cdef[[
typedef enum {
  PANEL_DISABLED = 0,
  PANEL_ENABLED = 1 << 1,
  PANEL_EVENT_NO_HANDLING = 1 << 2,
  PANEL_NO_FB_OFFSET = 1 << 3,
  PANEL_NO_SELF_UPDATE = 1 << 4,
} PANEL_FLAGS;
]]
end

if target_version == 610 then
ffi.cdef[[
struct iv_mtinfo_s {
  bool active;
  int x;
  int y;
  int pressure;
  int tilt_x;
  int tilt_y;
  enum input_dev_e devtype;
  long long timems;
};
]]
end

if target_version == 611 then
ffi.cdef[[
typedef struct {
  bool active;
  int x;
  int y;
  int pressure;
  int tilt_x;
  int tilt_y;
  enum input_dev_e devtype;
  uint32_t tools;
  long long timems;
} iv_pointer;
typedef iv_pointer iv_mtinfo;
]]
end

ffi.cdef[[
void ClearOnExit();
void DynamicUpdate(int x, int y, int w, int h);
void FullUpdate();
void FullUpdateHQ();
int GetBatteryPower();
char *GetCurrentProfile();
int GetCurrentTask();
char *GetDeviceModel();
int GetFrontlightState(void);
iconfig *GetGlobalConfig();
int GetSleepmode();
char *GetSoftwareVersion();
icanvas *GetTaskFramebuffer(int task);
int GoSleep(int ms, int deep);
int IsCharging();
int IsTaskActive();
int MultitaskingSupported();
int NetConnect(const char *name);
int NetDisconnect();
int OpenBook(const char *path, const char *parameters, int flags);
void OpenScreen();
int PageSnapshot();
void PartialUpdate(int x, int y, int w, int h);
void PartialUpdateHQ(int x, int y, int w, int h);
void PowerOff();
]]

if 505 <= target_version and target_version <= 512 then
ffi.cdef[[ void PrepareForLoop(iv_handler); ]]
end

if 514 <= target_version and target_version <= 611 then
ffi.cdef[[ void PrepareForLoop(iv_handler hproc); ]]
end

ffi.cdef[[
void ProcessEventLoop();
int QueryGSensor();
int QueryNetwork();
const char *ReadString(iconfig *cfg, const char *name, const char *deflt);
int SendGlobalRequest(int param);
void SetFrontlightState(int flstate);
void SetPanelType(int type);
]]

if 505 <= target_version and target_version <= 508 then
ffi.cdef[[ int SetSubtaskInfo(int task, int subtask, char *name, char *book); ]]
end

if 509 <= target_version and target_version <= 611 then
ffi.cdef[[ int SetSubtaskInfo(int task, int subtask, const char *name, const char *book); ]]
end

ffi.cdef[[
void WaitForUpdateComplete();
int WiFiPower(int status);
void hw_close();
int hw_get_keylock();
int hw_init();
long iv_ipc_request(long type, long attr, unsigned char *data, int inlen, int outlen);
void iv_setup_gsensor();
void iv_setup_touchpanel();
void iv_sleepmode(int on);
void iv_update_orientation(int isexternal);
iv_mtinfo *GetTouchInfoI(unsigned index);
]]

if 508 <= target_version and target_version <= 611 then
ffi.cdef[[ int NetMgrPing(void); ]]
end

if 519 <= target_version and target_version <= 611 then
ffi.cdef[[
int GetFrontlightColor(void);
int GetFrontlightEnabled();
int GetGSensorOrientation();
void SetFrontlightColor(int color);
void SetFrontlightEnabled(int enabled);
]]
end

if 605 <= target_version and target_version <= 611 then
ffi.cdef[[ void adjustAreaDefault(unsigned char *data, int scanline, int width, int height); ]]
end
