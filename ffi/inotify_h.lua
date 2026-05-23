-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
static const unsigned IN_ACCESS = 1;
static const unsigned IN_ATTRIB = 4;
static const unsigned IN_CLOSE_WRITE = 8;
static const unsigned IN_CLOSE_NOWRITE = 16;
static const unsigned IN_CREATE = 256;
static const unsigned IN_DELETE = 512;
static const unsigned IN_DELETE_SELF = 1024;
static const unsigned IN_MODIFY = 2;
static const unsigned IN_MOVE_SELF = 2048;
static const unsigned IN_MOVED_FROM = 64;
static const unsigned IN_MOVED_TO = 128;
static const unsigned IN_OPEN = 32;
static const unsigned IN_ALL_EVENTS = 4095;
static const unsigned IN_MOVE = 192;
static const unsigned IN_CLOSE = 24;
static const unsigned IN_DONT_FOLLOW = 33554432;
static const unsigned IN_EXCL_UNLINK = 67108864;
static const unsigned IN_MASK_ADD = 536870912;
static const unsigned IN_ONESHOT = 2147483648;
static const unsigned IN_ONLYDIR = 16777216;
static const unsigned IN_IGNORED = 32768;
static const unsigned IN_ISDIR = 1073741824;
static const unsigned IN_Q_OVERFLOW = 16384;
static const unsigned IN_UNMOUNT = 8192;
static const unsigned IN_NONBLOCK = 2048;
static const unsigned IN_CLOEXEC = 524288;
int inotify_init(void);
int inotify_init1(int __flags);
int inotify_add_watch(int __fd, const char *__name, uint32_t __mask);
int inotify_rm_watch(int __fd, int __wd);
struct inotify_event {
  int wd;
  uint32_t mask;
  uint32_t cookie;
  uint32_t len;
  char name[];
};
]]
