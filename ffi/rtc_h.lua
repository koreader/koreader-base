-- Automatically generated with ffi-cdecl.

require "ffi/posix_h"

require("ffi").cdef[[
struct rtc_time {
  int tm_sec;
  int tm_min;
  int tm_hour;
  int tm_mday;
  int tm_mon;
  int tm_year;
  int tm_wday;
  int tm_yday;
  int tm_isdst;
};
struct rtc_wkalrm {
  unsigned char enabled;
  unsigned char pending;
  struct rtc_time time;
};
static const unsigned RTC_AIE_ON = 28673;
static const unsigned RTC_AIE_OFF = 28674;
static const unsigned RTC_WKALM_SET = 1076391951;
static const unsigned RTC_WKALM_RD = 2150133776;
static const unsigned RTC_RD_TIME = 2149871625;
]]
