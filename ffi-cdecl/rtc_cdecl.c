#include <linux/rtc.h>
#include <linux/ioctl.h>
#include <time.h>
#include <sys/time.h>

#include "ffi-cdecl.h"

cdecl_struct(rtc_time)
cdecl_struct(rtc_wkalrm)

cdecl_const(RTC_AIE_ON)
cdecl_const(RTC_AIE_OFF)
cdecl_const(RTC_WKALM_SET)
cdecl_const(RTC_WKALM_RD)
cdecl_const(RTC_RD_TIME)

cdecl_type(time_t)
cdecl_struct(tm)
cdecl_func(time)
cdecl_func(gmtime)
cdecl_func(gmtime_r)
cdecl_func(localtime)
cdecl_func(localtime_r)
cdecl_func(timegm)
cdecl_func(mktime)
cdecl_func(settimeofday)
cdecl_func(tzset)
