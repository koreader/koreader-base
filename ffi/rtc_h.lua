-- Automatically generated with ffi-cdecl.

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
typedef long __time_t;
typedef __time_t time_t;
struct tm {
  int tm_sec;
  int tm_min;
  int tm_hour;
  int tm_mday;
  int tm_mon;
  int tm_year;
  int tm_wday;
  int tm_yday;
  int tm_isdst;
  long tm_gmtoff;
  const char *tm_zone;
};
time_t time(time_t *);
struct tm *gmtime(const time_t *);
struct tm *gmtime_r(const time_t *, struct tm *);
struct tm *localtime(const time_t *);
struct tm *localtime_r(const time_t *, struct tm *);
time_t timegm(struct tm *);
time_t mktime(struct tm *);
int settimeofday(const struct timeval *, const struct timezone *);
void tzset(void);
]]
