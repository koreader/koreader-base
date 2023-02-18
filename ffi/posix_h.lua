local ffi = require("ffi")

-- Handle arch-dependent typedefs...
if ffi.arch == "x64" then
    require("ffi/posix_types_x64_h")
elseif ffi.arch == "x86" then
    require("ffi/posix_types_x86_h")
elseif ffi.abi("64bit") then
    require("ffi/posix_types_64b_h")
else
    require("ffi/posix_types_def_h")
end

ffi.cdef[[
static const int EAGAIN = 11;
static const int EINTR = 4;
static const int EINVAL = 22;
static const int ENODEV = 19;
static const int ENOSYS = 38;
static const int EPIPE = 32;
static const int ETIME = 62;
static const int ETIMEDOUT = 110;
struct timezone {
  int tz_minuteswest;
  int tz_dsttime;
};
int pipe(int *) __attribute__((nothrow, leaf));
int fork(void) __attribute__((nothrow));
int dup(int) __attribute__((nothrow, leaf));
int dup2(int, int) __attribute__((nothrow, leaf));
static const int O_APPEND = 1024;
static const int O_CREAT = 64;
static const int O_TRUNC = 512;
static const int O_RDWR = 2;
static const int O_RDONLY = 0;
static const int O_WRONLY = 1;
static const int O_NONBLOCK = 2048;
static const int O_CLOEXEC = 524288;
static const int S_IRUSR = 256;
static const int S_IWUSR = 128;
static const int S_IXUSR = 64;
static const int S_IRWXU = 448;
static const int S_IRGRP = 32;
static const int S_IWGRP = 16;
static const int S_IXGRP = 8;
static const int S_IRWXG = 56;
static const int S_IROTH = 4;
static const int S_IWOTH = 2;
static const int S_IXOTH = 1;
static const int S_IRWXO = 7;
int open(const char *, int, ...);
int mq_open(const char *, int, ...) __attribute__((nothrow, leaf));
ssize_t mq_receive(int, char *, size_t, unsigned int *);
int mq_close(int) __attribute__((nothrow, leaf));
int close(int);
int fcntl(int, int, ...);
int execl(const char *, const char *, ...) __attribute__((nothrow, leaf));
int execlp(const char *, const char *, ...) __attribute__((nothrow, leaf));
int execv(const char *, char *const *) __attribute__((nothrow, leaf));
int execvp(const char *, char *const *) __attribute__((nothrow, leaf));
ssize_t write(int, const void *, size_t);
ssize_t read(int, void *, size_t);
int kill(int, int) __attribute__((nothrow, leaf));
static const int WNOHANG = 1;
int waitpid(int, int *, int);
int getpid(void) __attribute__((nothrow, leaf));
int getppid(void) __attribute__((nothrow, leaf));
int setpgid(int, int) __attribute__((nothrow, leaf));
struct pollfd {
  int fd;
  short int events;
  short int revents;
};
static const int POLLIN = 1;
static const int POLLOUT = 4;
static const int POLLERR = 8;
static const int POLLHUP = 16;
int poll(struct pollfd *, long unsigned int, int);
static const int PROT_READ = 1;
static const int PROT_WRITE = 2;
static const int MAP_SHARED = 1;
static const int MAP_ANONYMOUS = 32;
static const int MAP_FAILED = -1;
static const int PATH_MAX = 4096;
int memcmp(const void *, const void *, size_t) __attribute__((pure, leaf, nothrow));
void *mmap(void *, size_t, int, int, int, off_t) __attribute__((nothrow, leaf));
int munmap(void *, size_t) __attribute__((nothrow, leaf));
int ioctl(int, long unsigned int, ...) __attribute__((nothrow, leaf));
void Sleep(int ms);
unsigned int sleep(unsigned int);
int usleep(unsigned int);
int nanosleep(const struct timespec *, struct timespec *);
int statvfs(const char *restrict, struct statvfs *restrict) __attribute__((nothrow, leaf));
int gettimeofday(struct timeval *restrict, struct timezone *restrict) __attribute__((nothrow, leaf));
char *realpath(const char *restrict, char *restrict) __attribute__((nothrow, leaf));
char *basename(char *) __attribute__((nothrow, leaf));
char *dirname(char *) __attribute__((nothrow, leaf));
typedef int clockid_t;
int clock_getres(clockid_t, struct timespec *) __attribute__((nothrow, leaf));
int clock_gettime(clockid_t, struct timespec *) __attribute__((nothrow, leaf));
int clock_settime(clockid_t, const struct timespec *) __attribute__((nothrow, leaf));
static const int TIMER_ABSTIME = 1;
int clock_nanosleep(clockid_t, int, const struct timespec *, struct timespec *);
void *malloc(size_t) __attribute__((malloc, leaf, nothrow));
void *calloc(size_t, size_t) __attribute__((malloc, leaf, nothrow));
void free(void *) __attribute__((leaf, nothrow));
void *memset(void *, int, size_t) __attribute__((leaf, nothrow));
char *strdup(const char *) __attribute__((malloc, leaf, nothrow));
char *strndup(const char *, size_t) __attribute__((malloc, leaf, nothrow));
int strcoll(const char *, const char *) __attribute__((nothrow, leaf, pure));
int strcmp(const char *, const char *) __attribute__((pure, leaf, nothrow));
int strcasecmp(const char *, const char *) __attribute__((pure, leaf, nothrow));
static const int F_OK = 0;
int access(const char *, int) __attribute__((nothrow, leaf));
typedef struct _IO_FILE FILE;
typedef long long unsigned int dev_t;
typedef long unsigned int ino_t;
typedef unsigned int mode_t;
typedef unsigned int nlink_t;
typedef unsigned int uid_t;
typedef unsigned int gid_t;
typedef long int blksize_t;
typedef long int blkcnt_t;
struct stat {
  long long unsigned int st_dev;
  short unsigned int __pad1;
  long unsigned int st_ino;
  unsigned int st_mode;
  unsigned int st_nlink;
  unsigned int st_uid;
  unsigned int st_gid;
  long long unsigned int st_rdev;
  short unsigned int __pad2;
  long int st_size;
  long int st_blksize;
  long int st_blocks;
  struct timespec st_atim;
  struct timespec st_mtim;
  struct timespec st_ctim;
  long unsigned int __glibc_reserved4;
  long unsigned int __glibc_reserved5;
};
unsigned int getuid(void) __attribute__((nothrow, leaf));
FILE *fopen(const char *restrict, const char *restrict);
int stat(const char *restrict, struct stat *restrict) __attribute__((nothrow, leaf));
int fstat(int, struct stat *) __attribute__((nothrow, leaf));
int lstat(const char *restrict, struct stat *restrict) __attribute__((nothrow, leaf));
size_t fread(void *restrict, size_t, size_t, FILE *restrict);
size_t fwrite(const void *restrict, size_t, size_t, FILE *restrict);
int fclose(FILE *);
int fflush(FILE *);
int feof(FILE *) __attribute__((nothrow, leaf));
int ferror(FILE *) __attribute__((nothrow, leaf));
int printf(const char *, ...);
int sprintf(char *, const char *, ...) __attribute__((nothrow));
int fprintf(FILE *restrict, const char *restrict, ...);
int fputc(int, FILE *);
static const int FIONREAD = 21531;
int fileno(FILE *) __attribute__((nothrow, leaf));
char *strerror(int) __attribute__((nothrow, leaf));
int fsync(int);
int fdatasync(int);
int setenv(const char *, const char *, int) __attribute__((nothrow, leaf));
int unsetenv(const char *) __attribute__((nothrow, leaf));
int _putenv(const char *);
typedef unsigned int id_t;
enum __priority_which {
  PRIO_PROCESS = 0,
  PRIO_PGRP = 1,
  PRIO_USER = 2,
};
typedef enum __priority_which __priority_which_t;
int getpriority(__priority_which_t, id_t) __attribute__((nothrow, leaf));
int setpriority(__priority_which_t, id_t, int) __attribute__((nothrow, leaf));
typedef int pid_t;
struct sched_param {
  int sched_priority;
};
static const int SCHED_OTHER = 0;
static const int SCHED_BATCH = 3;
static const int SCHED_IDLE = 5;
static const int SCHED_FIFO = 1;
static const int SCHED_RR = 2;
static const int SCHED_RESET_ON_FORK = 1073741824;
int sched_getscheduler(int) __attribute__((nothrow, leaf));
int sched_setscheduler(int, int, const struct sched_param *) __attribute__((nothrow, leaf));
int sched_getparam(int, struct sched_param *) __attribute__((nothrow, leaf));
int sched_setparam(int, const struct sched_param *) __attribute__((nothrow, leaf));
typedef struct {
  long unsigned int __bits[32];
} cpu_set_t;
int sched_getaffinity(int, size_t, cpu_set_t *) __attribute__((nothrow, leaf));
int sched_setaffinity(int, size_t, const cpu_set_t *) __attribute__((nothrow, leaf));
int sched_yield(void) __attribute__((nothrow, leaf));
struct sockaddr {
  short unsigned int sa_family;
  char sa_data[14];
};
struct ifaddrs {
  struct ifaddrs *ifa_next;
  char *ifa_name;
  unsigned int ifa_flags;
  struct sockaddr *ifa_addr;
  struct sockaddr *ifa_netmask;
  union {
    struct sockaddr *ifu_broadaddr;
    struct sockaddr *ifu_dstaddr;
  } ifa_ifu;
  void *ifa_data;
};
static const int NI_MAXHOST = 1025;
int getifaddrs(struct ifaddrs **) __attribute__((nothrow, leaf));
static const int AF_INET = 2;
static const int AF_INET6 = 10;
int getnameinfo(const struct sockaddr *restrict, unsigned int, char *restrict, unsigned int, char *restrict, unsigned int, int);
struct in_addr {
  unsigned int s_addr;
};
struct sockaddr_in {
  short unsigned int sin_family;
  short unsigned int sin_port;
  struct in_addr sin_addr;
  unsigned char sin_zero[8];
};
struct in6_addr {
  union {
    uint8_t __u6_addr8[16];
    uint16_t __u6_addr16[8];
    uint32_t __u6_addr32[4];
  } __in6_u;
};
struct sockaddr_in6 {
  short unsigned int sin6_family;
  short unsigned int sin6_port;
  uint32_t sin6_flowinfo;
  struct in6_addr sin6_addr;
  uint32_t sin6_scope_id;
};
static const int NI_NUMERICHOST = 1;
const char *gai_strerror(int) __attribute__((nothrow, leaf));
void freeifaddrs(struct ifaddrs *) __attribute__((nothrow, leaf));
static const int PF_INET = 2;
static const int SOCK_DGRAM = 2;
static const int IPPROTO_IP = 0;
static const int IFNAMSIZ = 16;
struct ifmap {
  long unsigned int mem_start;
  long unsigned int mem_end;
  short unsigned int base_addr;
  unsigned char irq;
  unsigned char dma;
  unsigned char port;
};
struct ifreq {
  union {
    char ifrn_name[16];
  } ifr_ifrn;
  union {
    struct sockaddr ifru_addr;
    struct sockaddr ifru_dstaddr;
    struct sockaddr ifru_broadaddr;
    struct sockaddr ifru_netmask;
    struct sockaddr ifru_hwaddr;
    short int ifru_flags;
    int ifru_ivalue;
    int ifru_mtu;
    struct ifmap ifru_map;
    char ifru_slave[16];
    char ifru_newname[16];
    char *ifru_data;
  } ifr_ifru;
};
static const int SIOCGIFHWADDR = 35111;
static const int RTF_UP = 1;
static const int RTF_GATEWAY = 2;
static const int RTF_HOST = 4;
static const int RTF_REINSTATE = 8;
static const int RTF_DYNAMIC = 16;
static const int RTF_MODIFIED = 32;
static const int RTF_DEFAULT = 65536;
static const int RTF_ADDRCONF = 262144;
static const int RTF_CACHE = 16777216;
static const int RTF_REJECT = 512;
static const int RTF_NONEXTHOP = 2097152;
static const int IFF_UP = 1;
static const int IFF_BROADCAST = 2;
static const int IFF_DEBUG = 4;
static const int IFF_LOOPBACK = 8;
static const int IFF_POINTOPOINT = 16;
static const int IFF_RUNNING = 64;
static const int IFF_NOARP = 128;
static const int IFF_PROMISC = 256;
static const int IFF_NOTRAILERS = 32;
static const int IFF_ALLMULTI = 512;
static const int IFF_MASTER = 1024;
static const int IFF_SLAVE = 2048;
static const int IFF_MULTICAST = 4096;
static const int IFF_PORTSEL = 8192;
static const int IFF_AUTOMEDIA = 16384;
static const int IFF_DYNAMIC = 32768;
static const int IFF_LOWER_UP = 65536;
static const int IFF_DORMANT = 131072;
static const int IFF_ECHO = 262144;
]]

-- clock_gettime & friends require librt on old glibc (< 2.17) versions...
if ffi.os == "Linux" then
    -- Load it in the global namespace to make it easier on callers...
    -- NOTE: There's no librt.so symlink, so, specify the SOVER, but not the full path,
    --       in order to let the dynamic loader figure it out on its own (e.g.,  multilib).
    pcall(ffi.load, "rt.so.1", true)
end

-- The clockid_t constants are not portable :/.
if ffi.os == "Linux" then
    ffi.cdef[[
static const int CLOCK_REALTIME = 0;
static const int CLOCK_REALTIME_COARSE = 5;
static const int CLOCK_MONOTONIC = 1;
static const int CLOCK_MONOTONIC_COARSE = 6;
static const int CLOCK_MONOTONIC_RAW = 4;
static const int CLOCK_BOOTTIME = 7;
static const int CLOCK_TAI = 11;
]]
elseif ffi.os == "OSX" then
    -- c.f., https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX10.12.sdk/usr/include/time.h
    --[[
    typedef enum {
    _CLOCK_REALTIME             = 0,
    _CLOCK_MONOTONIC            = 6,
    _CLOCK_MONOTONIC_RAW        = 4,
    _CLOCK_MONOTONIC_RAW_APPROX = 5,
    _CLOCK_UPTIME_RAW           = 8,
    _CLOCK_UPTIME_RAW_APPROX    = 9,
    _CLOCK_PROCESS_CPUTIME_ID   = 12,
    _CLOCK_THREAD_CPUTIME_ID    = 16
    } clockid_t;
    --]]
    -- Portability notes:
    -- Unlike on Linux, MONO ticks during sleep (which is technically the POSIX-compliant behavior).
    -- CLOCK_UPTIME_* doesn't.
    -- (e.g., macOS UPTIME == Linux MONO, and macOS MONO == Linux BOOTTIME)

    -- NOTE: Requires macOS 10.12
    ffi.cdef[[
static const int CLOCK_REALTIME = 0;
static const int CLOCK_REALTIME_COARSE = -1;
static const int CLOCK_MONOTONIC = 6;
static const int CLOCK_MONOTONIC_COARSE = 5;
static const int CLOCK_MONOTONIC_RAW = 4;
static const int CLOCK_BOOTTIME = -1;
static const int CLOCK_TAI = -1;
]]
elseif ffi.os == "BSD" then
    -- OpenBSD
    -- c.f., https://github.com/openbsd/src/blob/master/sys/sys/_time.h
    --[[
    #define CLOCK_REALTIME           0
    #define CLOCK_PROCESS_CPUTIME_ID 2
    #define CLOCK_MONOTONIC          3
    #define CLOCK_THREAD_CPUTIME_ID  4
    #define CLOCK_UPTIME             5
    #define CLOCK_BOOTTIME           6
    --]]
    -- Portability notes:
    -- OpenBSD UPTIME == Linux MONOTONIC, OpenBSD BOOTTIME == Linux BOOTTIME
    -- (Meaning MONOTONIC starts ticking at an *undefined* positive value).

    -- NetBSD
    -- c.f., https://anonhg.netbsd.org/src/file/tip/sys/sys/time.h
    --[[
    #define CLOCK_REALTIME           0
    #define CLOCK_VIRTUAL            1
    #define CLOCK_PROF               2
    #define CLOCK_MONOTONIC          3
    #define CLOCK_THREAD_CPUTIME_ID  0x20000000
    #define CLOCK_PROCESS_CPUTIME_ID 0x40000000
    --]]

    -- FreeBSD
    -- c.f., https://github.com/freebsd/freebsd-src/blob/main/include/time.h
    --[[
    #define CLOCK_REALTIME           0
    #define CLOCK_VIRTUAL            1
    #define CLOCK_PROF               2
    #define CLOCK_MONOTONIC          4
    #define CLOCK_UPTIME             5  /* FreeBSD-specific. */
    #define CLOCK_UPTIME_PRECISE     7  /* FreeBSD-specific. */
    #define CLOCK_UPTIME_FAST        8  /* FreeBSD-specific. */
    #define CLOCK_REALTIME_PRECISE   9  /* FreeBSD-specific. */
    #define CLOCK_REALTIME_FAST      10 /* FreeBSD-specific. */
    #define CLOCK_MONOTONIC_PRECISE  11 /* FreeBSD-specific. */
    #define CLOCK_MONOTONIC_FAST     12 /* FreeBSD-specific. */
    #define CLOCK_SECOND             13 /* FreeBSD-specific. */
    #define CLOCK_THREAD_CPUTIME_ID  14
    #define CLOCK_PROCESS_CPUTIME_ID 15
    --]]
    -- Portability notes:
    -- FreeBSD UPTIME == Linux MONOTONIC
    -- (I assume that, like on OpenBSD, this means MONOTONIC starts ticking at an *undefined* positive value).

    -- So, here comes probey-time!
    local C = ffi.C
    local probe_ts = ffi.new("struct timespec")
    if C.clock_getres(15, probe_ts) == 0 then
        -- FreeBSD
        ffi.cdef[[
static const int CLOCK_REALTIME = 0;
static const int CLOCK_REALTIME_COARSE = 10;
static const int CLOCK_MONOTONIC = 4;
static const int CLOCK_MONOTONIC_COARSE = 12;
static const int CLOCK_MONOTONIC_RAW = 11;
static const int CLOCK_BOOTTIME = -1;
static const int CLOCK_TAI = -1;
]]
    elseif C.clock_getres(0x40000000, probe_ts) == 0 then
        -- NetBSD
        ffi.cdef[[
static const int CLOCK_REALTIME = 0;
static const int CLOCK_REALTIME_COARSE = -1;
static const int CLOCK_MONOTONIC = 3;
static const int CLOCK_MONOTONIC_COARSE = -1;
static const int CLOCK_MONOTONIC_RAW = -1;
static const int CLOCK_BOOTTIME = -1;
static const int CLOCK_TAI = -1;
]]
    else
        -- OpenBSD
        ffi.cdef[[
static const int CLOCK_REALTIME = 0;
static const int CLOCK_REALTIME_COARSE = -1;
static const int CLOCK_MONOTONIC = 3;
static const int CLOCK_MONOTONIC_COARSE = -1;
static const int CLOCK_MONOTONIC_RAW = -1;
static const int CLOCK_BOOTTIME = 6;
static const int CLOCK_TAI = -1;
]]
    end
    probe_ts = nil --luacheck: ignore
else
    -- Assume minimal Linux compat on other OSes.

    -- This holds true for Windows via mingw,
    -- c.f., https://github.com/mirror/mingw-w64/blob/master/mingw-w64-libraries/winpthreads/include/pthread_time.h
    --[[
    #define CLOCK_REALTIME           0
    #define CLOCK_MONOTONIC          1
    #define CLOCK_PROCESS_CPUTIME_ID 2
    #define CLOCK_THREAD_CPUTIME_ID  3
    --]]

    ffi.cdef[[
static const int CLOCK_REALTIME = 0;
static const int CLOCK_REALTIME_COARSE = -1;
static const int CLOCK_MONOTONIC = 1;
static const int CLOCK_MONOTONIC_COARSE = -1;
static const int CLOCK_MONOTONIC_RAW = -1;
static const int CLOCK_BOOTTIME = -1;
static const int CLOCK_TAI = -1;
]]
end
