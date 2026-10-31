// NOTE: This ones needs a recent kernel, the ones from eInk devices TCs are too old for some of the stuff we need for Android.
//       i.e., CPPFLAGS="-I/usr/include" ./ffi-cdecl ...
#define __signed__ signed
#include <linux/fb.h>
#include <linux/input.h>
#include <stddef.h>
#include <stdint.h>

/*
** Custom values we use for ev.type, ev.code & ev.value in Input and Device HAL implementations
** In particular, orientation constants, usable by Device implementations for platform-specific gyro translations.
** (matches framebuffer constants, which matches Linux <input/fb.h> FB_ROTATE_* constants).
** (i.e., this is how the device is *physically* oriented).
*/
#define EV_SDL  'S'
#define MSC_GYRO  'G'
#define DEVICE_ROTATED_UPRIGHT            FB_ROTATE_UR
#define DEVICE_ROTATED_CLOCKWISE          FB_ROTATE_CW
#define DEVICE_ROTATED_UPSIDE_DOWN        FB_ROTATE_UD
#define DEVICE_ROTATED_COUNTER_CLOCKWISE  FB_ROTATE_CCW

cdecl_const(EVIOCGRAB)
cdecl_const(EVIOCGREP)
cdecl_const(EVIOCSREP)

cdecl_const(EV_ABS)
cdecl_const(EV_FF)
cdecl_const(EV_FF_STATUS)
cdecl_const(EV_KEY)
cdecl_const(EV_LED)
cdecl_const(EV_MAX)
cdecl_const(EV_MSC)
cdecl_const(EV_PWR)
cdecl_const(EV_REL)
cdecl_const(EV_REP)
cdecl_const(EV_SDL)
cdecl_const(EV_SND)
cdecl_const(EV_SW)
cdecl_const(EV_SYN)

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
cdecl_const(MSC_GYRO)
cdecl_const(MSC_RAW)

cdecl_const(REP_DELAY)
cdecl_const(REP_PERIOD)
cdecl_const(REP_CNT)

cdecl_const(DEVICE_ROTATED_UPRIGHT)
cdecl_const(DEVICE_ROTATED_CLOCKWISE)
cdecl_const(DEVICE_ROTATED_UPSIDE_DOWN)
cdecl_const(DEVICE_ROTATED_COUNTER_CLOCKWISE)

cdecl_type_replace(__u16, uint16_t);
cdecl_type_replace(__s32, int32_t);

// NOTE: we can't use the raw definition for `struct input_event`:
// when using musl, `time_t` is 64bits even on 32bits (e.g. ARMhf & x86),
// making the layout of `struct input_event` when using `struct timeval`
// incompatible with the kernel ABI.

#ifdef DEBUG_INPUT_EVENT_CDECL
cdecl_struct(input_event);
#endif

#if (__BITS_PER_LONG != 32 || !defined(__USE_TIME_BITS64)) && !defined(__KERNEL__)
# ifdef DEBUG_INPUT_EVENT_CDECL
#  warning input_event is using timeval
# endif
# ifndef input_event_sec
#  define input_event_sec time.tv_sec
# endif
# ifndef input_event_usec
#  define input_event_usec time.tv_usec
# endif
#else
# ifdef DEBUG_INPUT_EVENT_CDECL
#  warning input_event is not using timeval
# endif
#endif

#ifdef DEBUG_INPUT_EVENT_CDECL
cdecl_offsetof(real_input_event_sec, struct input_event, input_event_sec);
cdecl_offsetof(real_input_event_usec, struct input_event, input_event_usec);
cdecl_offsetof(real_input_event_type, struct input_event, type);
cdecl_offsetof(real_input_event_code, struct input_event, code);
cdecl_offsetof(real_input_event_value, struct input_event, value);
cdecl_sizeof(real_input_event, struct input_event);
#endif

cdecl_out(struct_input_event, struct input_event {
    struct {
        long tv_sec;
        long tv_usec;
    } time;
    uint16_t type;
    uint16_t code;
    int32_t value;
};);

enum {
    OFFSETOF_input_event_sec = 0,
    OFFSETOF_input_event_usec = OFFSETOF_input_event_sec + sizeof (long),
    OFFSETOF_input_event_type = OFFSETOF_input_event_usec + sizeof (long),
    OFFSETOF_input_event_code = OFFSETOF_input_event_type + sizeof (__u16),
    OFFSETOF_input_event_value = OFFSETOF_input_event_code + sizeof (__u16),
    SIZEOF_input_event = OFFSETOF_input_event_value + sizeof (__s32),
};

#ifdef DEBUG_INPUT_EVENT_CDECL
cdecl_const(OFFSETOF_input_event_sec);
cdecl_const(OFFSETOF_input_event_usec);
cdecl_const(OFFSETOF_input_event_type);
cdecl_const(OFFSETOF_input_event_code);
cdecl_const(OFFSETOF_input_event_value);
cdecl_const(SIZEOF_input_event);
#else
_Static_assert(offsetof (struct input_event, input_event_sec) == OFFSETOF_input_event_sec);
_Static_assert(offsetof (struct input_event, input_event_usec) == OFFSETOF_input_event_usec);
_Static_assert(offsetof (struct input_event, type) == OFFSETOF_input_event_type);
_Static_assert(offsetof (struct input_event, code) == OFFSETOF_input_event_code);
_Static_assert(offsetof (struct input_event, value) == OFFSETOF_input_event_value);
_Static_assert(sizeof (struct input_event) == SIZEOF_input_event);
#endif
