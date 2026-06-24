#include <linux/ioctl.h>
#include <linux/rtc.h>

cdecl_struct(rtc_time)
cdecl_struct(rtc_wkalrm)

cdecl_const(RTC_AIE_ON)
cdecl_const(RTC_AIE_OFF)
cdecl_const(RTC_WKALM_SET)
cdecl_const(RTC_WKALM_RD)
cdecl_const(RTC_RD_TIME)
