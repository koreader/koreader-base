-- Automatically generated with ffi-cdecl.

require "ffi/posix_h"

require("ffi").cdef[[
static const unsigned EVIOCGRAB = 1074021776;
static const unsigned EVIOCGREP = 2148025603;
static const unsigned EVIOCSREP = 1074283779;
static const unsigned EV_ABS = 3;
static const unsigned EV_FF = 21;
static const unsigned EV_FF_STATUS = 23;
static const unsigned EV_KEY = 1;
static const unsigned EV_LED = 17;
static const unsigned EV_MAX = 31;
static const unsigned EV_MSC = 4;
static const unsigned EV_PWR = 22;
static const unsigned EV_REL = 2;
static const unsigned EV_REP = 20;
static const unsigned EV_SDL = 83;
static const unsigned EV_SND = 18;
static const unsigned EV_SW = 5;
static const unsigned EV_SYN = 0;
static const unsigned SYN_REPORT = 0;
static const unsigned SYN_CONFIG = 1;
static const unsigned SYN_MT_REPORT = 2;
static const unsigned SYN_DROPPED = 3;
static const unsigned KEY_BATTERY = 236;
static const unsigned BTN_TOOL_PEN = 320;
static const unsigned BTN_TOOL_FINGER = 325;
static const unsigned BTN_TOOL_RUBBER = 321;
static const unsigned BTN_TOUCH = 330;
static const unsigned BTN_STYLUS = 331;
static const unsigned BTN_STYLUS2 = 332;
static const unsigned BTN_TOOL_DOUBLETAP = 333;
static const unsigned ABS_X = 0;
static const unsigned ABS_Y = 1;
static const unsigned ABS_PRESSURE = 24;
static const unsigned ABS_DISTANCE = 25;
static const unsigned ABS_TILT_X = 26;
static const unsigned ABS_TILT_Y = 27;
static const unsigned ABS_MT_SLOT = 47;
static const unsigned ABS_MT_TOUCH_MAJOR = 48;
static const unsigned ABS_MT_TOUCH_MINOR = 49;
static const unsigned ABS_MT_WIDTH_MAJOR = 50;
static const unsigned ABS_MT_WIDTH_MINOR = 51;
static const unsigned ABS_MT_ORIENTATION = 52;
static const unsigned ABS_MT_POSITION_X = 53;
static const unsigned ABS_MT_POSITION_Y = 54;
static const unsigned ABS_MT_TOOL_TYPE = 55;
static const unsigned ABS_MT_BLOB_ID = 56;
static const unsigned ABS_MT_TRACKING_ID = 57;
static const unsigned ABS_MT_PRESSURE = 58;
static const unsigned ABS_MT_DISTANCE = 59;
static const unsigned ABS_MT_TOOL_X = 60;
static const unsigned ABS_MT_TOOL_Y = 61;
static const unsigned SW_ROTATE_LOCK = 12;
static const unsigned SW_MACHINE_COVER = 16;
static const unsigned MSC_GESTURE = 2;
static const unsigned MSC_GYRO = 71;
static const unsigned MSC_RAW = 3;
static const unsigned REP_DELAY = 0;
static const unsigned REP_PERIOD = 1;
static const unsigned REP_CNT = 2;
static const unsigned DEVICE_ROTATED_UPRIGHT = 0;
static const unsigned DEVICE_ROTATED_CLOCKWISE = 1;
static const unsigned DEVICE_ROTATED_UPSIDE_DOWN = 2;
static const unsigned DEVICE_ROTATED_COUNTER_CLOCKWISE = 3;
typedef unsigned short __u16;
typedef signed int __s32;
struct input_event {
  struct timeval time;
  __u16 type;
  __u16 code;
  __s32 value;
};
]]
