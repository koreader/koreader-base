#include <linux/rtc.h>
#include <linux/ioctl.h>
#include <time.h>

#include "ffi-cdecl.h"

cdecl_struct(rtc_time)
cdecl_struct(rtc_wkalrm)

cdecl_const(RTC_WKALM_SET)
cdecl_const(RTC_WKALM_RD)

cdecl_type(time_t)
cdecl_struct(tm)
cdecl_func(time)
cdecl_func(localtime)
