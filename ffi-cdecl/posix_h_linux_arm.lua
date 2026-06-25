-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
// cdecl_const_EAGAIN
static const unsigned EAGAIN = 11;
// cdecl_const_EINTR
static const unsigned EINTR = 4;
// cdecl_const_EINVAL
static const unsigned EINVAL = 22;
// cdecl_const_ENODEV
static const unsigned ENODEV = 19;
// cdecl_const_ENOSYS
static const unsigned ENOSYS = 38;
// cdecl_const_EPERM
static const unsigned EPERM = 1;
// cdecl_const_EPIPE
static const unsigned EPIPE = 32;
// cdecl_const_ETIME
static const unsigned ETIME = 62;
// cdecl_const_ETIMEDOUT
static const unsigned ETIMEDOUT = 110;
// cdecl_const_O_APPEND
static const unsigned O_APPEND = 1024;
// cdecl_const_O_CLOEXEC
static const unsigned O_CLOEXEC = 524288;
// cdecl_const_O_CREAT
static const unsigned O_CREAT = 64;
// cdecl_const_O_NONBLOCK
static const unsigned O_NONBLOCK = 2048;
// cdecl_const_O_RDONLY
static const unsigned O_RDONLY = 0;
// cdecl_const_O_RDWR
static const unsigned O_RDWR = 2;
// cdecl_const_O_TRUNC
static const unsigned O_TRUNC = 512;
// cdecl_const_O_WRONLY
static const unsigned O_WRONLY = 1;
// cdecl_const_F_OK
static const unsigned F_OK = 0;
// cdecl_const_R_OK
static const unsigned R_OK = 4;
// cdecl_const_W_OK
static const unsigned W_OK = 2;
// cdecl_const_X_OK
static const unsigned X_OK = 1;
// cdecl_const_S_IRGRP
static const unsigned S_IRGRP = 32;
// cdecl_const_S_IROTH
static const unsigned S_IROTH = 4;
// cdecl_const_S_IRUSR
static const unsigned S_IRUSR = 256;
// cdecl_const_S_IRWXG
static const unsigned S_IRWXG = 56;
// cdecl_const_S_IRWXO
static const unsigned S_IRWXO = 7;
// cdecl_const_S_IRWXU
static const unsigned S_IRWXU = 448;
// cdecl_const_S_IWGRP
static const unsigned S_IWGRP = 16;
// cdecl_const_S_IWOTH
static const unsigned S_IWOTH = 2;
// cdecl_const_S_IWUSR
static const unsigned S_IWUSR = 128;
// cdecl_const_S_IXGRP
static const unsigned S_IXGRP = 8;
// cdecl_const_S_IXOTH
static const unsigned S_IXOTH = 1;
// cdecl_const_S_IXUSR
static const unsigned S_IXUSR = 64;
// cdecl_const_SEEK_CUR
static const unsigned SEEK_CUR = 1;
// cdecl_const_SEEK_END
static const unsigned SEEK_END = 2;
// cdecl_const_SEEK_SET
static const unsigned SEEK_SET = 0;
// cdecl_const_PATH_MAX
static const unsigned PATH_MAX = 4096;
// cdecl_const_CLOCK_BOOTTIME
static const unsigned CLOCK_BOOTTIME = 7;
// cdecl_const_CLOCK_MONOTONIC
static const unsigned CLOCK_MONOTONIC = 1;
// cdecl_const_CLOCK_MONOTONIC_COARSE
static const unsigned CLOCK_MONOTONIC_COARSE = 6;
// cdecl_const_CLOCK_REALTIME
static const unsigned CLOCK_REALTIME = 0;
// cdecl_const_CLOCK_REALTIME_COARSE
static const unsigned CLOCK_REALTIME_COARSE = 5;
// cdecl_type_clockid_t
typedef int clockid_t;
// cdecl_const_FIONREAD
static const unsigned FIONREAD = 21531;
// cdecl_type_suseconds_t
typedef long suseconds_t;
// cdecl_type_time_t
typedef long time_t;
// cdecl_type_useconds_t
typedef unsigned useconds_t;
// cdecl_struct_timeval
struct timeval {
  time_t tv_sec;
  suseconds_t tv_usec;
};
// cdecl_struct_timespec
struct timespec {
  time_t tv_sec;
  long tv_nsec;
};
// cdecl_type_blkcnt_t
typedef long blkcnt_t;
// cdecl_type_blksize_t
typedef long blksize_t;
// cdecl_type_id_t
typedef unsigned id_t;
// cdecl_type_mode_t
typedef unsigned mode_t;
// cdecl_type_off_t
typedef long off_t;
// cdecl_type_pid_t
typedef int pid_t;
// cdecl_type_uid_t
typedef unsigned uid_t;
// cdecl_type_fsblkcnt_t
typedef unsigned long fsblkcnt_t;
// cdecl_type_fsfilcnt_t
typedef unsigned long fsfilcnt_t;
// cdecl_struct_statvfs
struct statvfs {
  unsigned long f_bsize;
  unsigned long f_frsize;
  fsblkcnt_t f_blocks;
  fsblkcnt_t f_bfree;
  fsblkcnt_t f_bavail;
  fsfilcnt_t f_files;
  fsfilcnt_t f_ffree;
  fsfilcnt_t f_favail;
  unsigned long f_fsid;
  int __f_unused;
  unsigned long f_flag;
  unsigned long f_namemax;
  int __f_spare[6];
};
// cdecl_const_AF_INET
static const unsigned AF_INET = 2;
// cdecl_const_AF_INET6
static const unsigned AF_INET6 = 10;
// cdecl_const_AF_PACKET
static const unsigned AF_PACKET = 17;
// cdecl_const_AF_UNIX
static const unsigned AF_UNIX = 1;
// cdecl_const_NI_MAXHOST
static const unsigned NI_MAXHOST = 1025;
// cdecl_const_NI_NUMERICHOST
static const unsigned NI_NUMERICHOST = 1;
// cdecl_const_SOCK_CLOEXEC
static const unsigned SOCK_CLOEXEC = 524288;
// cdecl_const_SOCK_DGRAM
static const unsigned SOCK_DGRAM = 2;
// cdecl_const_SOCK_NONBLOCK
static const unsigned SOCK_NONBLOCK = 2048;
// cdecl_const_SOCK_RAW
static const unsigned SOCK_RAW = 3;
// cdecl_const_SOCK_SEQPACKET
static const unsigned SOCK_SEQPACKET = 5;
// cdecl_type_caddr_t
typedef char *caddr_t;
// cdecl_type_in_addr_t
typedef uint32_t in_addr_t;
// cdecl_type_in_port_t
typedef uint16_t in_port_t;
// cdecl_type_sa_family_t
typedef unsigned short sa_family_t;
// cdecl_type_socklen_t
typedef unsigned socklen_t;
// cdecl_struct_in_addr
struct in_addr {
  in_addr_t s_addr;
};
// cdecl_struct_in6_addr
struct in6_addr {
  union {
    uint8_t __u6_addr8[16];
    uint16_t __u6_addr16[8];
    uint32_t __u6_addr32[4];
  } __in6_u;
};
// cdecl_struct_sockaddr
struct sockaddr {
  sa_family_t sa_family;
  char sa_data[14];
};
// cdecl_struct_sockaddr_ll
struct sockaddr_ll {
  unsigned short sll_family;
  unsigned short sll_protocol;
  int sll_ifindex;
  unsigned short sll_hatype;
  unsigned char sll_pkttype;
  unsigned char sll_halen;
  unsigned char sll_addr[8];
};
// cdecl_struct_sockaddr_in
struct sockaddr_in {
  sa_family_t sin_family;
  in_port_t sin_port;
  struct in_addr sin_addr;
  unsigned char sin_zero[sizeof (struct sockaddr) - (sizeof (unsigned short)) - sizeof (in_port_t) - sizeof (struct in_addr)];
};
// cdecl_struct_sockaddr_in6
struct sockaddr_in6 {
  sa_family_t sin6_family;
  in_port_t sin6_port;
  uint32_t sin6_flowinfo;
  struct in6_addr sin6_addr;
  uint32_t sin6_scope_id;
};
// cdecl_struct_sockaddr_un
struct sockaddr_un {
  sa_family_t sun_family;
  char sun_path[108];
};
// cdecl_struct_sockaddr_storage
struct sockaddr_storage {
  sa_family_t ss_family;
  unsigned long __ss_align;
  char __ss_padding[(128 - (2 * sizeof (unsigned long)))];
};
// cdecl_struct_ifaddrs
struct ifaddrs {
  struct ifaddrs *ifa_next;
  char *ifa_name;
  unsigned ifa_flags;
  struct sockaddr *ifa_addr;
  struct sockaddr *ifa_netmask;
  union {
    struct sockaddr *ifu_broadaddr;
    struct sockaddr *ifu_dstaddr;
  } ifa_ifu;
  void *ifa_data;
};
// cdecl_struct_ifmap
struct ifmap {
  unsigned long mem_start;
  unsigned long mem_end;
  unsigned short base_addr;
  unsigned char irq;
  unsigned char dma;
  unsigned char port;
};
// cdecl_struct_ifreq
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
    short ifru_flags;
    int ifru_ivalue;
    int ifru_mtu;
    struct ifmap ifru_map;
    char ifru_slave[16];
    char ifru_newname[16];
    caddr_t ifru_data;
  } ifr_ifru;
};
// cdecl_const_SIOCGIWESSID
static const unsigned SIOCGIWESSID = 35611;
// cdecl_const_IW_ENCODE_INDEX
static const unsigned IW_ENCODE_INDEX = 255;
// cdecl_const_IW_ESSID_MAX_SIZE
static const unsigned IW_ESSID_MAX_SIZE = 32;
// cdecl_struct_iw_freq
struct iw_freq {
  int32_t m;
  int16_t e;
  uint8_t i;
  uint8_t flags;
};
// cdecl_struct_iw_param
struct iw_param {
  int32_t value;
  uint8_t fixed;
  uint8_t disabled;
  uint16_t flags;
};
// cdecl_struct_iw_point
struct iw_point {
  void *pointer;
  uint16_t length;
  uint16_t flags;
};
// cdecl_struct_iw_quality
struct iw_quality {
  uint8_t qual;
  uint8_t level;
  uint8_t noise;
  uint8_t updated;
};
// cdecl_union_iwreq_data
union iwreq_data {
  char name[16];
  struct iw_point essid;
  struct iw_param nwid;
  struct iw_freq freq;
  struct iw_param sens;
  struct iw_param bitrate;
  struct iw_param txpower;
  struct iw_param rts;
  struct iw_param frag;
  uint32_t mode;
  struct iw_param retry;
  struct iw_point encoding;
  struct iw_param power;
  struct iw_quality qual;
  struct sockaddr ap_addr;
  struct sockaddr addr;
  struct iw_param param;
  struct iw_point data;
};
// cdecl_struct_iwreq
struct iwreq {
  union {
    char ifrn_name[16];
  } ifr_ifrn;
  union iwreq_data u;
};
// cdecl_type_nfds_t
typedef unsigned long nfds_t;
// cdecl_type_mqd_t
typedef int mqd_t;
// cdecl_func_mq_close
int mq_close(mqd_t);
// cdecl_func_mq_open
mqd_t mq_open(const char *, int, ...);
// cdecl_func_mq_receive
ssize_t mq_receive(mqd_t, char *, size_t, unsigned *);
// cdecl_const_PTHREAD_CREATE_DETACHED
static const unsigned PTHREAD_CREATE_DETACHED = 1;
// cdecl_type_pthread_attr_t
typedef union {
  char __size[36];
  long __align;
} pthread_attr_t;
// cdecl_type_pthread_t
typedef unsigned long pthread_t;
// cdecl_func_pthread_attr_destroy
int pthread_attr_destroy(pthread_attr_t *);
// cdecl_func_pthread_attr_init
int pthread_attr_init(pthread_attr_t *);
// cdecl_func_pthread_attr_setdetachstate
int pthread_attr_setdetachstate(pthread_attr_t *, int);
// cdecl_func_pthread_create
int pthread_create(pthread_t *, const pthread_attr_t *, void *(*)(void *), void *);
// cdecl_const_SCHED_BATCH
static const unsigned SCHED_BATCH = 3;
// cdecl_struct_sched_param
struct sched_param {
  int __sched_priority;
};
// cdecl_func_sched_setscheduler
int sched_setscheduler(pid_t, int, const struct sched_param *);
// cdecl_func_shm_open
int shm_open(const char *, int, mode_t);
// cdecl_const_POLLERR
static const unsigned POLLERR = 8;
// cdecl_const_POLLHUP
static const unsigned POLLHUP = 16;
// cdecl_const_POLLIN
static const unsigned POLLIN = 1;
// cdecl_const_POLLOUT
static const unsigned POLLOUT = 4;
// cdecl_struct_pollfd
struct pollfd {
  int fd;
  short events;
  short revents;
};
// cdecl_func_poll
int poll(struct pollfd *, nfds_t, int);
// cdecl_func_calloc
void *calloc(size_t, size_t);
// cdecl_func_free
void free(void *);
// cdecl_func_malloc
void *malloc(size_t);
// cdecl_func_mkdtemp
char *mkdtemp(char *);
// cdecl_func_mkstemps
int mkstemps(char *, int);
// cdecl_func_realloc
void *realloc(void *, size_t);
// cdecl_func_realpath
char *realpath(const char *, char *);
// cdecl_func_setenv
int setenv(const char *, const char *, int);
// cdecl_func_unsetenv
int unsetenv(const char *);
// cdecl_func_unlockpt
int unlockpt(int);
// cdecl_func_grantpt
int grantpt(int);
// cdecl_func_ptsname
char *ptsname(int);
// cdecl_func_basename
char *basename(char *);
// cdecl_func_dirname
char *dirname(char *);
// cdecl_func_fcntl
int fcntl(int, int, ...);
// cdecl_func_open
int open(const char *, int, ...);
// cdecl_const_HAVE_POSIX_FALLOCATE
static const unsigned HAVE_POSIX_FALLOCATE = 1;
// cdecl_func_posix_fallocate
int posix_fallocate(int, off_t, off_t);
// cdecl_type_FILE
typedef struct _IO_FILE FILE;
// cdecl_func_fclose
int fclose(FILE *);
// cdecl_func_ferror
int ferror(FILE *);
// cdecl_func_fflush
int fflush(FILE *);
// cdecl_func_fileno
int fileno(FILE *);
// cdecl_func_fopen
FILE *fopen(const char *, const char *);
// cdecl_func_fputs
int fputs(const char *, FILE *);
// cdecl_func_fread
size_t fread(void *, size_t, size_t, FILE *);
// cdecl_func_fwrite
size_t fwrite(const void *, size_t, size_t, FILE *);
// cdecl_func_sprintf
int sprintf(char *, const char *, ...);
// cdecl_func__exit
void _exit(int);
// cdecl_func_access
int access(const char *, int);
// cdecl_func_close
int close(int);
// cdecl_func_dup2
int dup2(int, int);
// cdecl_func_execl
int execl(const char *, const char *, ...);
// cdecl_func_execlp
int execlp(const char *, const char *, ...);
// cdecl_func_execvp
int execvp(const char *, char *const[]);
// cdecl_func_fdatasync
int fdatasync(int);
// cdecl_func_fork
pid_t fork(void);
// cdecl_func_fsync
int fsync(int);
// cdecl_func_ftruncate
int ftruncate(int, off_t);
// cdecl_func_getpid
pid_t getpid(void);
// cdecl_func_getppid
pid_t getppid(void);
// cdecl_func_getuid
uid_t getuid(void);
// cdecl_func_lseek
off_t lseek(int, off_t, int);
// cdecl_func_pause
int pause(void);
// cdecl_func_pipe
int pipe(int[2]);
// cdecl_func_read
ssize_t read(int, void *, size_t);
// cdecl_func_setpgid
int setpgid(pid_t, pid_t);
// cdecl_func_setsid
pid_t setsid(void);
// cdecl_func_sleep
unsigned sleep(unsigned);
// cdecl_func_usleep
int usleep(useconds_t);
// cdecl_func_write
ssize_t write(int, const void *, size_t);
// cdecl_func_memchr
void *memchr(const void *, int, size_t);
// cdecl_func_memcmp
int memcmp(const void *, const void *, size_t);
// cdecl_func_memmove
void *memmove(void *, const void *, size_t);
// cdecl_func_strcasecmp
int strcasecmp(const char *, const char *);
// cdecl_func_strcmp
int strcmp(const char *, const char *);
// cdecl_func_strcoll
int strcoll(const char *, const char *);
// cdecl_func_strdup
char *strdup(const char *);
// cdecl_func_strerror
char *strerror(int);
// cdecl_func_strncasecmp
int strncasecmp(const char *, const char *, size_t);
// cdecl_func_strnlen
size_t strnlen(const char *, size_t);
// cdecl_const_SIGTERM
static const unsigned SIGTERM = 15;
// cdecl_func_kill
int kill(pid_t, int);
// cdecl_const_IFNAMSIZ
static const unsigned IFNAMSIZ = 16;
// cdecl_const_IFF_LOOPBACK
static const unsigned IFF_LOOPBACK = 8;
// cdecl_const_IFF_UP
static const unsigned IFF_UP = 1;
// cdecl_const_IPPROTO_IP
static const unsigned IPPROTO_IP = 0;
// cdecl_const_IPPROTO_ICMP
static const unsigned IPPROTO_ICMP = 1;
// cdecl_const_RTF_GATEWAY
static const unsigned RTF_GATEWAY = 2;
// cdecl_const_RTF_UP
static const unsigned RTF_UP = 1;
// cdecl_func_connect
int connect(int, const struct sockaddr *, socklen_t);
// cdecl_func_recv
ssize_t recv(int, void *, size_t, int);
// cdecl_func_send
ssize_t send(int, const void *, size_t, int);
// cdecl_func_sendto
ssize_t sendto(int, const void *, size_t, int, const struct sockaddr *, socklen_t);
// cdecl_func_socket
int socket(int, int, int);
// cdecl_func_gai_strerror
const char *gai_strerror(int);
// cdecl_func_getnameinfo
int getnameinfo(const struct sockaddr *, socklen_t, char *, socklen_t, char *, socklen_t, int);
// cdecl_func_inet_aton
int inet_aton(const char *, struct in_addr *);
// cdecl_func_statvfs
int statvfs(const char *, struct statvfs *);
// cdecl_const_WNOHANG
static const unsigned WNOHANG = 1;
// cdecl_func_waitpid
pid_t waitpid(pid_t, int *, int);
// cdecl_const_MAP_ANONYMOUS
static const unsigned MAP_ANONYMOUS = 32;
// cdecl_const_MAP_FAILED
static const int MAP_FAILED = -1;
// cdecl_const_MAP_SHARED
static const unsigned MAP_SHARED = 1;
// cdecl_const_PROT_READ
static const unsigned PROT_READ = 1;
// cdecl_const_PROT_WRITE
static const unsigned PROT_WRITE = 2;
// cdecl_func_mmap
void *mmap(void *, size_t, int, int, int, off_t);
// cdecl_func_munmap
int munmap(void *, size_t);
// cdecl_struct_tm
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
// cdecl_func_clock_getres
int clock_getres(clockid_t, struct timespec *);
// cdecl_func_clock_gettime
int clock_gettime(clockid_t, struct timespec *);
// cdecl_func_gmtime
struct tm *gmtime(const time_t *);
// cdecl_func_gmtime_r
struct tm *gmtime_r(const time_t *, struct tm *);
// cdecl_func_localtime
struct tm *localtime(const time_t *);
// cdecl_func_strftime
size_t strftime(char *, size_t, const char *, const struct tm *);
// cdecl_func_time
time_t time(time_t *);
// cdecl_func_timegm
time_t timegm(struct tm *);
// cdecl_struct_timezone
struct timezone {
  int tz_minuteswest;
  int tz_dsttime;
};
// cdecl_func_gettimeofday
int gettimeofday(struct timeval *, struct timezone *);
// cdecl_func_settimeofday
int settimeofday(const struct timeval *, const struct timezone *);
// cdecl_const_PRIO_PROCESS
static const unsigned PRIO_PROCESS = 0;
// cdecl_const_PRIO_PGRP
static const unsigned PRIO_PGRP = 1;
// cdecl_const_PRIO_USER
static const unsigned PRIO_USER = 2;
// cdecl_func_setpriority
int setpriority(int, id_t, int);
// cdecl_const_TCIFLUSH
static const unsigned TCIFLUSH = 0;
// cdecl_func_tcdrain
int tcdrain(int);
// cdecl_func_tcflush
int tcflush(int, int);
// cdecl_func_htonl
uint32_t htonl(uint32_t);
// cdecl_func_htons
uint16_t htons(uint16_t);
// cdecl_func_ntohl
uint32_t ntohl(uint32_t);
// cdecl_func_ntohs
uint16_t ntohs(uint16_t);
// cdecl_func_freeifaddrs
void freeifaddrs(struct ifaddrs *);
// cdecl_func_getifaddrs
int getifaddrs(struct ifaddrs **);
// cdecl_func_ioctl
int ioctl(int, unsigned long, ...);
// cdecl_const_ICMP_ECHO
static const unsigned ICMP_ECHO = 8;
// cdecl_const_ICMP_ECHOREPLY
static const unsigned ICMP_ECHOREPLY = 0;
// cdecl_const_ICMP_MINLEN
static const unsigned ICMP_MINLEN = 8;
]]
