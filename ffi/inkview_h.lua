local ffi = require("ffi")

ffi.cdef[[
static const int MSG_REBOOT = 272;
static const int EVT_INIT = 21;
static const int EVT_EXIT = 22;
static const int EVT_SHOW = 23;
static const int EVT_HIDE = 24;
static const int EVT_KEYPRESS = 25;
static const int EVT_KEYPRESS_EXT = 40;
static const int EVT_KEYRELEASE = 26;
static const int EVT_KEYRELEASE_EXT = 41;
static const int EVT_KEYREPEAT = 28;
static const int EVT_KEYREPEAT_EXT = 42;
static const int EVT_POINTERUP = 29;
static const int EVT_POINTERDOWN = 30;
static const int EVT_POINTERMOVE = 31;
static const int EVT_ORIENTATION = 32;
static const int EVT_MTSYNC = 39;
static const int EVT_FOREGROUND = 151;
static const int EVT_BACKGROUND = 152;
static const int IV_KEY_POWER = 1;
static const int IV_KEY_DELETE = 8;
static const int IV_KEY_OK = 10;
static const int IV_KEY_UP = 17;
static const int IV_KEY_DOWN = 18;
static const int IV_KEY_LEFT = 19;
static const int IV_KEY_RIGHT = 20;
static const int IV_KEY_MINUS = 21;
static const int IV_KEY_PLUS = 22;
static const int IV_KEY_MENU = 23;
static const int IV_KEY_PREV = 24;
static const int IV_KEY_NEXT = 25;
static const int IV_KEY_HOME = 26;
static const int IV_KEY_BACK = 27;
static const int IV_KEY_PREV2 = 28;
static const int IV_KEY_NEXT2 = 29;
static const int IV_KEY_MUSIC = 30;
static const int IV_KEY_COVEROPEN = 2;
static const int IV_KEY_COVERCLOSE = 3;
static const int IV_KEY_ZOOMOUT = 6;
static const int IV_KEY_ZOOMIN = 7;
static const int IV_KEY_MENU_POWER = 4;
static const int IV_KEY_MAX = 32;
static const int IV_KEY_SHIFT = 14;
static const int IV_KEY_LANGUAGECHANGE = 15;
static const int IV_KEY_KEYBOARDCLOSE = 16;
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
