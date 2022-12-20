// NOTE: This ones needs a recent kernel, the ones from eInk devices TCs are too old for some of the stuff we need for Android.
//       i.e., CPPFLAGS="-I/usr/include" ./ffi-cdecl ...
#include <linux/input.h>

#include "ffi-cdecl.h"

cdecl_const(EVIOCGRAB)
cdecl_const(EVIOCGREP)
cdecl_const(EVIOCSREP)

cdecl_const(EV_SYN)
cdecl_const(EV_KEY)
cdecl_const(EV_REL)
cdecl_const(EV_ABS)
cdecl_const(EV_MSC)
cdecl_const(EV_SW)
cdecl_const(EV_LED)
cdecl_const(EV_SND)
cdecl_const(EV_REP)
cdecl_const(EV_FF)
cdecl_const(EV_PWR)
cdecl_const(EV_FF_STATUS)
cdecl_const(EV_MAX)

cdecl_const(SYN_REPORT)
cdecl_const(SYN_CONFIG)
cdecl_const(SYN_MT_REPORT)
cdecl_const(SYN_DROPPED)

cdecl_const(KEY_BATTERY)

cdecl_const(BTN_TOOL_PEN)
cdecl_const(BTN_TOOL_FINGER)
cdecl_const(BTN_TOOL_RUBBER)
cdecl_const(BTN_TOUCH)
cdecl_const(BTN_STYLUS)
cdecl_const(BTN_STYLUS2)
cdecl_const(BTN_TOOL_DOUBLETAP)

cdecl_const(ABS_X)
cdecl_const(ABS_Y)
cdecl_const(ABS_PRESSURE)
cdecl_const(ABS_DISTANCE)
cdecl_const(ABS_TILT_X)
cdecl_const(ABS_TILT_Y)

cdecl_const(ABS_MT_SLOT)
cdecl_const(ABS_MT_TOUCH_MAJOR)
cdecl_const(ABS_MT_TOUCH_MINOR)
cdecl_const(ABS_MT_WIDTH_MAJOR)
cdecl_const(ABS_MT_WIDTH_MINOR)
cdecl_const(ABS_MT_ORIENTATION)
cdecl_const(ABS_MT_POSITION_X)
cdecl_const(ABS_MT_POSITION_Y)
cdecl_const(ABS_MT_TOOL_TYPE)
cdecl_const(ABS_MT_BLOB_ID)
cdecl_const(ABS_MT_TRACKING_ID)
cdecl_const(ABS_MT_PRESSURE)
cdecl_const(ABS_MT_DISTANCE)
cdecl_const(ABS_MT_TOOL_X)
cdecl_const(ABS_MT_TOOL_Y)

cdecl_const(SW_ROTATE_LOCK)
cdecl_const(SW_MACHINE_COVER)

cdecl_const(MSC_GESTURE)
cdecl_const(MSC_RAW)

cdecl_const(REP_DELAY)
cdecl_const(REP_PERIOD)
cdecl_const(REP_CNT)

cdecl_struct(input_event)
