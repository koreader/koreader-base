local ffi = require("ffi")

ffi.cdef[[
static const int MSG_REBOOT = 272;
static const int EVT_ACTIVATE = 38;
static const int EVT_ASYNC_TASK_FINISHED = 262;
static const int EVT_AUDIO_CHANGED = 265;
static const int EVT_AVRCP_COMMAND = 264;
static const int EVT_BACKGROUND = 152;
static const int EVT_BT_RXCOMPLETE = 171;
static const int EVT_BT_TXCOMPLETE = 172;
static const int EVT_CALLBACK = 212;
static const int EVT_CONFIGCHANGED = 154;
static const int EVT_CONTROL_PANEL_ABOUT_TO_OPEN = 94;
static const int EVT_CUSTOM = 267;
static const int EVT_DIC_CLOSED = 201;
static const int EVT_DUMP_BITMAPS_DEBUG_INFO = 221;
static const int EVT_EXIT = 22;
static const int EVT_EXT_KB = 210;
static const int EVT_FOCUS = 36;
static const int EVT_FOREGROUND = 151;
static const int EVT_FRAME_ACTIVATED = 218;
static const int EVT_FRAME_DEACTIVATED = 219;
static const int EVT_FSCHANGED = 73;
static const int EVT_FSINCOMING = 72;
static const int EVT_GLOBALACTION = 150;
static const int EVT_GLOBALREQUEST = 149;
static const int EVT_HIDE = 24;
static const int EVT_INIT = 21;
static const int EVT_KEYPRESS = 25;
static const int EVT_KEYPRESS_EXT = 40;
static const int EVT_KEYRELEASE = 26;
static const int EVT_KEYRELEASE_EXT = 41;
static const int EVT_KEYREPEAT = 28;
static const int EVT_KEYREPEAT_EXT = 42;
static const int EVT_LETTER = 211;
static const int EVT_MP_STATECHANGED = 81;
static const int EVT_MP_TRACKCHANGED = 82;
static const int EVT_MTSYNC = 39;
static const int EVT_NET_CONNECTED = 256;
static const int EVT_NET_DISCONNECTED = 257;
static const int EVT_NET_FOUND_NEW_FW = 260;
static const int EVT_NEXTPAGE = 92;
static const int EVT_OBREEY_CONFIG_CHANGED = 156;
static const int EVT_OPENDIC = 93;
static const int EVT_ORIENTATION = 32;
static const int EVT_PACKAGE_JOB_CHANGED = 266;
static const int EVT_PANEL = 120;
static const int EVT_PANEL_BLUETOOTH = 128;
static const int EVT_PANEL_BLUETOOTH_A2DP = 118;
static const int EVT_PANEL_CLOCK = 127;
static const int EVT_PANEL_FRONT_LIGHT = 133;
static const int EVT_PANEL_ICON = 121;
static const int EVT_PANEL_MPLAYER = 124;
static const int EVT_PANEL_NETWORK = 126;
static const int EVT_PANEL_OBREEY_SYNC = 130;
static const int EVT_PANEL_PROGRESS = 123;
static const int EVT_PANEL_SETREADINGMODE = 131;
static const int EVT_PANEL_SETREADINGMODE_INVERT = 132;
static const int EVT_PANEL_TASKLIST = 129;
static const int EVT_PANEL_TEXT = 122;
static const int EVT_PANEL_USBDRIVE = 125;
static const int EVT_POINTERCANCEL = 45;
static const int EVT_POINTERCHANGED = 46;
static const int EVT_POINTERDOWN = 30;
static const int EVT_POINTERDRAG = 44;
static const int EVT_POINTERHOLD = 35;
static const int EVT_POINTERLONG = 34;
static const int EVT_POINTERMOVE = 31;
static const int EVT_POINTERUP = 29;
static const int EVT_POSTPONE_TIMED_POWEROFF = 217;
static const int EVT_PREVPAGE = 91;
static const int EVT_QN_BORDER = 53;
static const int EVT_QN_MOVE = 51;
static const int EVT_QN_RELEASE = 52;
static const int EVT_READ_PROGRESS_CHANGED = 220;
static const int EVT_REPAINT = 43;
static const int EVT_SAVESTATE = 155;
static const int EVT_SCANPROGRESS = 213;
static const int EVT_SCANSTOPPED = 216;
static const int EVT_SCROLL = 33;
static const int EVT_SDIN = 161;
static const int EVT_SDOUT = 162;
static const int EVT_SHOW = 23;
static const int EVT_SNAPSHOT = 71;
static const int EVT_STARTSCAN = 215;
static const int EVT_STOPSCAN = 214;
static const int EVT_STOP_PLAYING = 263;
static const int EVT_SUBTASKCLOSE = 153;
static const int EVT_SYNTH_ENDED = 200;
static const int EVT_SYNTH_POSITION = 261;
static const int EVT_TAB = 119;
static const int EVT_TEXTCLEAR = 209;
static const int EVT_TOUCHDOWN = 48;
static const int EVT_TOUCHMOVE = 49;
static const int EVT_TOUCHUP = 47;
static const int EVT_UNFOCUS = 37;
static const int EVT_UPDATE = 95;
static const int EVT_USBSTORE_IN = 163;
static const int EVT_USBSTORE_OUT = 164;
static const int IV_KEY_0 = 48;
static const int IV_KEY_1 = 49;
static const int IV_KEY_2 = 50;
static const int IV_KEY_3 = 51;
static const int IV_KEY_4 = 52;
static const int IV_KEY_5 = 53;
static const int IV_KEY_6 = 54;
static const int IV_KEY_7 = 55;
static const int IV_KEY_8 = 56;
static const int IV_KEY_9 = 57;
static const int IV_KEY_BACK = 27;
static const int IV_KEY_COVERCLOSE = 3;
static const int IV_KEY_COVEROPEN = 2;
static const int IV_KEY_DELETE = 8;
static const int IV_KEY_DOWN = 18;
static const int IV_KEY_HOME = 26;
static const int IV_KEY_KEYBOARDCLOSE = 16;
static const int IV_KEY_LANGUAGECHANGE = 15;
static const int IV_KEY_LEFT = 19;
static const int IV_KEY_MAX = 32;
static const int IV_KEY_MENU = 23;
static const int IV_KEY_MENU_POWER = 4;
static const int IV_KEY_MINUS = 21;
static const int IV_KEY_MUSIC = 30;
static const int IV_KEY_NEXT = 25;
static const int IV_KEY_NEXT2 = 29;
static const int IV_KEY_OK = 10;
static const int IV_KEY_PLUS = 22;
static const int IV_KEY_POWER = 1;
static const int IV_KEY_PREV = 24;
static const int IV_KEY_PREV2 = 28;
static const int IV_KEY_RIGHT = 20;
static const int IV_KEY_SHIFT = 14;
static const int IV_KEY_UP = 17;
static const int IV_KEY_ZOOMIN = 7;
static const int IV_KEY_ZOOMOUT = 6;
static const int NET_CONNECTED = 3840;
static const int NET_OK = 0;
static const int REQ_KEYLOCK = 65;
enum input_dev_e {
  DEV_UNKNOWN = 0,
  TP_CAPACITIVE = 1,
  TP_DIGITIZER = 2,
  MAX_INPUT_TOUCH_DEV = 3,
  INPUT_DEV_KEYBOARD_HW = 4,
  INPUT_DEV_KEYBOARD_BT = 5,
  INPUT_DEV_KEYBOARD_USB = 6,
};
struct hw_event_data_common_s {
  int mod;
  int par1;
  int par2;
};
typedef struct hw_event_data_common_s hw_event_data_common;
struct hw_event_data_pointer_s {
  int id;
  int x;
  int y;
  int pressure;
  enum input_dev_e devtype;
};
typedef struct hw_event_data_pointer_s hw_event_data_pointer;
struct hw_event_s {
  int type;
  union {
    hw_event_data_common common;
    hw_event_data_pointer pointer;
  };
  struct timeval time;
};
typedef struct hw_event_s hw_event;
struct icanvas_s {
  int width;
  int height;
  int scanline;
  int depth;
  int clipx1;
  int clipx2;
  int clipy1;
  int clipy2;
  unsigned char *addr;
};
typedef struct icanvas_s icanvas;
typedef int (*iv_handler)(int, int, int);
struct iv_mtinfo_s {
  bool active;
  int x;
  int y;
  int pressure;
  enum input_dev_e devtype;
  long long int timems;
};
typedef struct iv_mtinfo_s iv_mtinfo;
typedef enum {
  PANEL_DISABLED = 0,
  PANEL_ENABLED = 2,
  PANEL_EVENT_NO_HANDLING = 4,
  PANEL_NO_FB_OFFSET = 8,
  PANEL_NO_SELF_UPDATE = 16,
} PANEL_FLAGS;
void ClearOnExit();
void DynamicUpdate(int, int, int, int);
void FullUpdate();
void FullUpdateHQ();
int GetBatteryPower();
char *GetCurrentProfile();
int GetCurrentTask();
char *GetDeviceModel();
int GetFrontlightColor(void);
int GetFrontlightEnabled();
int GetFrontlightState(void);
int GetSleepmode();
char *GetSoftwareVersion();
icanvas *GetTaskFramebuffer(int);
iv_mtinfo *GetTouchInfoI(unsigned int);
int GoSleep(int, int);
int IsCharging();
int IsTaskActive();
int MultitaskingSupported();
int NetConnect(const char *);
int NetDisconnect();
int NetMgrPing(void);
int OpenBook(const char *, const char *, int);
void OpenScreen();
void PartialUpdate(int, int, int, int);
void PartialUpdateHQ(int, int, int, int);
void PowerOff();
void PrepareForLoop(iv_handler);
void ProcessEventLoop();
int QueryGSensor();
int QueryNetwork();
int SendGlobalRequest(int);
void SetFrontlightColor(int);
void SetFrontlightEnabled(int);
void SetFrontlightState(int);
void SetPanelType(int);
int SetSubtaskInfo(int, int, const char *, const char *);
void WaitForUpdateComplete();
int WiFiPower(int);
void adjustAreaDefault(unsigned char *, int, int, int);
void hw_close();
int hw_get_keylock();
int hw_init();
long int iv_ipc_request(long int, long int, unsigned char *, int, int);
void iv_setup_gsensor();
void iv_setup_touchpanel();
void iv_sleepmode(int);
void iv_update_orientation(int);
]]
