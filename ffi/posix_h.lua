-- Automatically generated with ./utils/gen_merged_cdecl_h.py.

local ffi = require("ffi")

local platform_str
if os.getenv("IS_ANDROID") then
    platform_str = "android_" .. ffi.arch
elseif ffi.os == "OSX" then
    platform_str = "macos"
else
    platform_str = ffi.os:lower() .. "_" .. ffi.arch
end
local platform = ({ android_arm=0x1, android_arm64=0x2, android_x64=0x4, android_x86=0x8, linux_arm=0x10, linux_arm64=0x20, linux_x64=0x40, macos=0x80 })[platform_str]
if not platform then
    error("unsupported platform: " .. platform_str)
end

-- clock_gettime & friends require librt on old glibc (< 2.17) versions...
if ffi.os == "Linux" then
    -- Load it in the global namespace to make it easier on callers...
    -- NOTE: There's no librt.so symlink, so, specify the SOVER, but not the full path,
    --       in order to let the dynamic loader figure it out on its own (e.g.,  multilib).
    pcall(ffi.load, "rt.so.1", true)
end

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[ static const unsigned EAGAIN = 11; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ static const unsigned EAGAIN = 35; ]]
end

ffi.cdef[[
static const unsigned EINTR = 4;
static const unsigned EINVAL = 22;
static const unsigned ENODEV = 19;
]]

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[ static const unsigned ENOSYS = 38; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ static const unsigned ENOSYS = 78; ]]
end

ffi.cdef[[
static const unsigned EPERM = 1;
static const unsigned EPIPE = 32;
]]

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[
static const unsigned ETIME = 62;
static const unsigned ETIMEDOUT = 110;
static const unsigned O_APPEND = 1024;
static const unsigned O_CLOEXEC = 524288;
static const unsigned O_CREAT = 64;
static const unsigned O_NONBLOCK = 2048;
]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[
static const unsigned ETIME = 101;
static const unsigned ETIMEDOUT = 60;
static const unsigned O_APPEND = 8;
static const unsigned O_CLOEXEC = 16777216;
static const unsigned O_CREAT = 512;
static const unsigned O_NONBLOCK = 4;
]]
end

ffi.cdef[[
static const unsigned O_RDONLY = 0;
static const unsigned O_RDWR = 2;
]]

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[ static const unsigned O_TRUNC = 512; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ static const unsigned O_TRUNC = 1024; ]]
end

ffi.cdef[[
static const unsigned O_WRONLY = 1;
static const unsigned F_OK = 0;
static const unsigned R_OK = 4;
static const unsigned W_OK = 2;
static const unsigned X_OK = 1;
static const unsigned S_IRGRP = 32;
static const unsigned S_IROTH = 4;
static const unsigned S_IRUSR = 256;
static const unsigned S_IRWXG = 56;
static const unsigned S_IRWXO = 7;
static const unsigned S_IRWXU = 448;
static const unsigned S_IWGRP = 16;
static const unsigned S_IWOTH = 2;
static const unsigned S_IWUSR = 128;
static const unsigned S_IXGRP = 8;
static const unsigned S_IXOTH = 1;
static const unsigned S_IXUSR = 64;
static const unsigned SEEK_CUR = 1;
static const unsigned SEEK_END = 2;
static const unsigned SEEK_SET = 0;
]]

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[
static const unsigned PATH_MAX = 4096;
static const unsigned CLOCK_BOOTTIME = 7;
static const unsigned CLOCK_MONOTONIC = 1;
static const unsigned CLOCK_MONOTONIC_COARSE = 6;
]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[
static const unsigned PATH_MAX = 1024;
static const int CLOCK_BOOTTIME = -1;
static const unsigned CLOCK_MONOTONIC = 6;
static const unsigned CLOCK_MONOTONIC_COARSE = 5;
]]
end

ffi.cdef[[ static const unsigned CLOCK_REALTIME = 0; ]]

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[
static const unsigned CLOCK_REALTIME_COARSE = 5;
typedef int clockid_t;
static const unsigned FIONREAD = 21531;
typedef long suseconds_t;
]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[
static const int CLOCK_REALTIME_COARSE = -1;
typedef unsigned clockid_t;
static const unsigned FIONREAD = 1074030207;
typedef int32_t suseconds_t;
]]
end

ffi.cdef[[ typedef long time_t; ]]

if --[[ android_arm|android_arm64|android_x64|android_x86|macos ]] bit.band(platform, 0x8f) ~= 0 then
ffi.cdef[[ typedef uint32_t useconds_t; ]]
elseif --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[ typedef unsigned useconds_t; ]]
end

ffi.cdef[[
struct timeval {
  time_t tv_sec;
  suseconds_t tv_usec;
};
struct timespec {
  time_t tv_sec;
  long tv_nsec;
};
]]

if --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[ typedef long blkcnt_t; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ typedef int64_t blkcnt_t; ]]
end

if --[[ linux_arm|linux_x64 ]] bit.band(platform, 0x50) ~= 0 then
ffi.cdef[[ typedef long blksize_t; ]]
elseif --[[ linux_arm64 ]] platform == 0x20 then
ffi.cdef[[ typedef int blksize_t; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ typedef int32_t blksize_t; ]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86|macos ]] bit.band(platform, 0x8f) ~= 0 then
ffi.cdef[[ typedef uint32_t id_t; ]]
elseif --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[ typedef unsigned id_t; ]]
end

if --[[ macos ]] platform == 0x80 then
ffi.cdef[[ typedef uint64_t __darwin_ino64_t; ]]
end

if --[[ android_arm|android_x86 ]] bit.band(platform, 0x9) ~= 0 then
ffi.cdef[[ typedef unsigned short mode_t; ]]
elseif --[[ android_arm64|android_x64|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x76) ~= 0 then
ffi.cdef[[ typedef unsigned mode_t; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ typedef uint16_t mode_t; ]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[
typedef long off_t;
typedef int pid_t;
]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[
typedef int64_t off_t;
typedef int32_t pid_t;
]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86|macos ]] bit.band(platform, 0x8f) ~= 0 then
ffi.cdef[[ typedef uint32_t uid_t; ]]
elseif --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[ typedef unsigned uid_t; ]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[
typedef unsigned long fsblkcnt_t;
typedef unsigned long fsfilcnt_t;
]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[
typedef unsigned fsblkcnt_t;
typedef unsigned fsfilcnt_t;
]]
end

if --[[ android_arm|android_x86|macos ]] bit.band(platform, 0x89) ~= 0 then
ffi.cdef[[
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
  unsigned long f_flag;
  unsigned long f_namemax;
};
]]
elseif --[[ android_arm64|android_x64 ]] bit.band(platform, 0x6) ~= 0 then
ffi.cdef[[
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
  unsigned long f_flag;
  unsigned long f_namemax;
  uint32_t __f_reserved[6];
};
]]
elseif --[[ linux_arm ]] platform == 0x10 then
ffi.cdef[[
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
]]
elseif --[[ linux_arm64 ]] platform == 0x20 then
ffi.cdef[[
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
  unsigned long f_flag;
  unsigned long f_namemax;
  int __f_spare[6];
};
]]
elseif --[[ linux_x64 ]] platform == 0x40 then
ffi.cdef[[
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
  unsigned long f_flag;
  unsigned long f_namemax;
  unsigned f_type;
  int __f_spare[5];
};
]]
end

if --[[ macos ]] platform == 0x80 then
ffi.cdef[[ static const unsigned IFT_ETHER = 6; ]]
end

ffi.cdef[[ static const unsigned AF_INET = 2; ]]

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[ static const unsigned AF_INET6 = 10; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ static const unsigned AF_INET6 = 30; ]]
end

if --[[ macos ]] platform == 0x80 then
ffi.cdef[[ static const unsigned AF_LINK = 18; ]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[ static const unsigned AF_PACKET = 17; ]]
end

ffi.cdef[[
static const unsigned AF_UNIX = 1;
static const unsigned NI_MAXHOST = 1025;
]]

if --[[ android_arm|android_arm64|android_x64|android_x86|macos ]] bit.band(platform, 0x8f) ~= 0 then
ffi.cdef[[ static const unsigned NI_NUMERICHOST = 2; ]]
elseif --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[ static const unsigned NI_NUMERICHOST = 1; ]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[ static const unsigned SOCK_CLOEXEC = 524288; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ static const unsigned SOCK_CLOEXEC = 0; ]]
end

ffi.cdef[[ static const unsigned SOCK_DGRAM = 2; ]]

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[ static const unsigned SOCK_NONBLOCK = 2048; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ static const unsigned SOCK_NONBLOCK = 0; ]]
end

ffi.cdef[[
static const unsigned SOCK_RAW = 3;
static const unsigned SOCK_SEQPACKET = 5;
]]

if --[[ linux_arm|linux_arm64|linux_x64|macos ]] bit.band(platform, 0xf0) ~= 0 then
ffi.cdef[[ typedef char *caddr_t; ]]
end

ffi.cdef[[
typedef uint32_t in_addr_t;
typedef uint16_t in_port_t;
]]

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[ typedef unsigned short sa_family_t; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ typedef uint8_t sa_family_t; ]]
end

if --[[ android_arm|android_x86 ]] bit.band(platform, 0x9) ~= 0 then
ffi.cdef[[ typedef int32_t socklen_t; ]]
elseif --[[ android_arm64|android_x64|macos ]] bit.band(platform, 0x86) ~= 0 then
ffi.cdef[[ typedef uint32_t socklen_t; ]]
elseif --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[ typedef unsigned socklen_t; ]]
end

ffi.cdef[[
struct in_addr {
  in_addr_t s_addr;
};
]]

if --[[ android_arm|android_arm64|android_x64|android_x86 ]] bit.band(platform, 0xf) ~= 0 then
ffi.cdef[[
struct in6_addr {
  union {
    uint8_t u6_addr8[16];
    uint16_t u6_addr16[8];
    uint32_t u6_addr32[4];
  } in6_u;
};
]]
elseif --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[
struct in6_addr {
  union {
    uint8_t __u6_addr8[16];
    uint16_t __u6_addr16[8];
    uint32_t __u6_addr32[4];
  } __in6_u;
};
]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[
struct in6_addr {
  union {
    uint8_t __u6_addr8[16];
    uint16_t __u6_addr16[8];
    uint32_t __u6_addr32[4];
  } __u6_addr;
};
]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[
struct sockaddr {
  sa_family_t sa_family;
  char sa_data[14];
};
]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[
struct sockaddr {
  uint8_t sa_len;
  sa_family_t sa_family;
  char sa_data[14];
};
]]
end

if --[[ macos ]] platform == 0x80 then
ffi.cdef[[
struct sockaddr_dl {
  unsigned char sdl_len;
  unsigned char sdl_family;
  unsigned short sdl_index;
  unsigned char sdl_type;
  unsigned char sdl_nlen;
  unsigned char sdl_alen;
  unsigned char sdl_slen;
  char sdl_data[12];
};
]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86 ]] bit.band(platform, 0xf) ~= 0 then
ffi.cdef[[
struct sockaddr_ll {
  unsigned short sll_family;
  uint16_t sll_protocol;
  int sll_ifindex;
  unsigned short sll_hatype;
  unsigned char sll_pkttype;
  unsigned char sll_halen;
  unsigned char sll_addr[8];
};
]]
elseif --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[
struct sockaddr_ll {
  unsigned short sll_family;
  unsigned short sll_protocol;
  int sll_ifindex;
  unsigned short sll_hatype;
  unsigned char sll_pkttype;
  unsigned char sll_halen;
  unsigned char sll_addr[8];
};
]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86 ]] bit.band(platform, 0xf) ~= 0 then
ffi.cdef[[
struct sockaddr_in {
  sa_family_t sin_family;
  uint16_t sin_port;
  struct in_addr sin_addr;
  unsigned char __pad[16 - sizeof (short) - sizeof (unsigned short) - sizeof (struct in_addr)];
};
struct sockaddr_in6 {
  unsigned short sin6_family;
  uint16_t sin6_port;
  uint32_t sin6_flowinfo;
  struct in6_addr sin6_addr;
  uint32_t sin6_scope_id;
};
]]
elseif --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[
struct sockaddr_in {
  sa_family_t sin_family;
  in_port_t sin_port;
  struct in_addr sin_addr;
  unsigned char sin_zero[sizeof (struct sockaddr) - (sizeof (unsigned short)) - sizeof (in_port_t) - sizeof (struct in_addr)];
};
struct sockaddr_in6 {
  sa_family_t sin6_family;
  in_port_t sin6_port;
  uint32_t sin6_flowinfo;
  struct in6_addr sin6_addr;
  uint32_t sin6_scope_id;
};
]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[
struct sockaddr_in {
  uint8_t sin_len;
  sa_family_t sin_family;
  in_port_t sin_port;
  struct in_addr sin_addr;
  char sin_zero[8];
};
struct sockaddr_in6 {
  uint8_t sin6_len;
  sa_family_t sin6_family;
  in_port_t sin6_port;
  uint32_t sin6_flowinfo;
  struct in6_addr sin6_addr;
  uint32_t sin6_scope_id;
};
]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[
struct sockaddr_un {
  sa_family_t sun_family;
  char sun_path[108];
};
]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[
struct sockaddr_un {
  unsigned char sun_len;
  sa_family_t sun_family;
  char sun_path[104];
};
]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86 ]] bit.band(platform, 0xf) ~= 0 then
ffi.cdef[[
struct sockaddr_storage {
  union {
    struct {
      sa_family_t ss_family;
      char __data[128 - sizeof (sa_family_t)];
    };
    void *__align;
  };
};
]]
elseif --[[ linux_arm ]] platform == 0x10 then
ffi.cdef[[
struct sockaddr_storage {
  sa_family_t ss_family;
  unsigned long __ss_align;
  char __ss_padding[(128 - (2 * sizeof (unsigned long)))];
};
]]
elseif --[[ linux_arm64|linux_x64 ]] bit.band(platform, 0x60) ~= 0 then
ffi.cdef[[
struct sockaddr_storage {
  sa_family_t ss_family;
  char __ss_padding[(128 - (sizeof (unsigned short)) - sizeof (unsigned long))];
  unsigned long __ss_align;
};
]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[
struct sockaddr_storage {
  uint8_t ss_len;
  sa_family_t ss_family;
  char __ss_pad1[((sizeof (int64_t)) - sizeof (uint8_t) - sizeof (sa_family_t))];
  int64_t __ss_align;
  char __ss_pad2[(128 - sizeof (uint8_t) - sizeof (sa_family_t) - ((sizeof (int64_t)) - sizeof (uint8_t) - sizeof (sa_family_t)) - (sizeof (int64_t)))];
};
]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[
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
]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[
struct ifaddrs {
  struct ifaddrs *ifa_next;
  char *ifa_name;
  unsigned ifa_flags;
  struct sockaddr *ifa_addr;
  struct sockaddr *ifa_netmask;
  struct sockaddr *ifa_dstaddr;
  void *ifa_data;
};
]]
end

if --[[ macos ]] platform == 0x80 then
ffi.cdef[[
struct ifdevmtu {
  int ifdm_current;
  int ifdm_min;
  int ifdm_max;
};
struct ifkpi {
  unsigned ifk_module_id;
  unsigned ifk_type;
  union {
    void *ifk_ptr;
    int ifk_value;
  } ifk_data;
};
]]
end

if --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[
struct ifmap {
  unsigned long mem_start;
  unsigned long mem_end;
  unsigned short base_addr;
  unsigned char irq;
  unsigned char dma;
  unsigned char port;
};
]]
end

if --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[
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
]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[
struct ifreq {
  char ifr_name[16];
  union {
    struct sockaddr ifru_addr;
    struct sockaddr ifru_dstaddr;
    struct sockaddr ifru_broadaddr;
    short ifru_flags;
    int ifru_metric;
    int ifru_mtu;
    int ifru_phys;
    int ifru_media;
    int ifru_intval;
    caddr_t ifru_data;
    struct ifdevmtu ifru_devmtu;
    struct ifkpi ifru_kpi;
    uint32_t ifru_wake_flags;
    uint32_t ifru_route_refcnt;
    int ifru_cap[2];
    uint32_t ifru_functional_type;
    uint32_t ifru_peer_egress_functional_type;
    uint8_t ifru_is_directlink;
    uint8_t ifru_is_vpn;
  } ifr_ifru;
};
]]
end

if --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[
static const unsigned SIOCGIWESSID = 35611;
static const unsigned IW_ENCODE_INDEX = 255;
static const unsigned IW_ESSID_MAX_SIZE = 32;
struct iw_freq {
  int32_t m;
  int16_t e;
  uint8_t i;
  uint8_t flags;
};
struct iw_param {
  int32_t value;
  uint8_t fixed;
  uint8_t disabled;
  uint16_t flags;
};
struct iw_point {
  void *pointer;
  uint16_t length;
  uint16_t flags;
};
struct iw_quality {
  uint8_t qual;
  uint8_t level;
  uint8_t noise;
  uint8_t updated;
};
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
struct iwreq {
  union {
    char ifrn_name[16];
  } ifr_ifrn;
  union iwreq_data u;
};
]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86|macos ]] bit.band(platform, 0x8f) ~= 0 then
ffi.cdef[[ typedef unsigned nfds_t; ]]
elseif --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[ typedef unsigned long nfds_t; ]]
end

if --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[
typedef int mqd_t;
int mq_close(mqd_t);
mqd_t mq_open(const char *, int, ...);
ssize_t mq_receive(mqd_t, char *, size_t, unsigned *);
]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[ static const unsigned PTHREAD_CREATE_DETACHED = 1; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ static const unsigned PTHREAD_CREATE_DETACHED = 2; ]]
end

if --[[ macos ]] platform == 0x80 then
ffi.cdef[[
struct _opaque_pthread_attr_t {
  long __sig;
  char __opaque[56];
};
]]
end

if --[[ linux_arm64 ]] platform == 0x20 then
ffi.cdef[[
union pthread_attr_t {
  char __size[64];
  long __align;
};
]]
elseif --[[ linux_x64 ]] platform == 0x40 then
ffi.cdef[[
union pthread_attr_t {
  char __size[56];
  long __align;
};
]]
end

if --[[ android_arm|android_x86 ]] bit.band(platform, 0x9) ~= 0 then
ffi.cdef[[
typedef struct {
  uint32_t flags;
  void *stack_base;
  size_t stack_size;
  size_t guard_size;
  int32_t sched_policy;
  int32_t sched_priority;
} pthread_attr_t;
]]
elseif --[[ android_arm64|android_x64 ]] bit.band(platform, 0x6) ~= 0 then
ffi.cdef[[
typedef struct {
  uint32_t flags;
  void *stack_base;
  size_t stack_size;
  size_t guard_size;
  int32_t sched_policy;
  int32_t sched_priority;
  char __reserved[16];
} pthread_attr_t;
]]
elseif --[[ linux_arm ]] platform == 0x10 then
ffi.cdef[[
typedef union {
  char __size[36];
  long __align;
} pthread_attr_t;
]]
elseif --[[ linux_arm64|linux_x64 ]] bit.band(platform, 0x60) ~= 0 then
ffi.cdef[[ typedef union pthread_attr_t pthread_attr_t; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ typedef struct _opaque_pthread_attr_t pthread_attr_t; ]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86 ]] bit.band(platform, 0xf) ~= 0 then
ffi.cdef[[ typedef long pthread_t; ]]
elseif --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[ typedef unsigned long pthread_t; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ typedef struct _opaque_pthread_t *pthread_t; ]]
end

ffi.cdef[[
int pthread_attr_destroy(pthread_attr_t *);
int pthread_attr_init(pthread_attr_t *);
int pthread_attr_setdetachstate(pthread_attr_t *, int);
]]

if --[[ android_arm|android_arm64|android_x64|android_x86 ]] bit.band(platform, 0xf) ~= 0 then
ffi.cdef[[ int pthread_create(pthread_t *, pthread_attr_t const *, void *(*)(void *), void *); ]]
elseif --[[ linux_arm|linux_arm64|linux_x64|macos ]] bit.band(platform, 0xf0) ~= 0 then
ffi.cdef[[ int pthread_create(pthread_t *, const pthread_attr_t *, void *(*)(void *), void *); ]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[ static const unsigned SCHED_BATCH = 3; ]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm64|linux_x64 ]] bit.band(platform, 0x6f) ~= 0 then
ffi.cdef[[
struct sched_param {
  int sched_priority;
};
]]
elseif --[[ linux_arm ]] platform == 0x10 then
ffi.cdef[[
struct sched_param {
  int __sched_priority;
};
]]
end

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[ int sched_setscheduler(pid_t, int, const struct sched_param *); ]]
end

if --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[ int shm_open(const char *, int, mode_t); ]]
end

ffi.cdef[[
static const unsigned POLLERR = 8;
static const unsigned POLLHUP = 16;
static const unsigned POLLIN = 1;
static const unsigned POLLOUT = 4;
struct pollfd {
  int fd;
  short events;
  short revents;
};
int poll(struct pollfd *, nfds_t, int);
void *calloc(size_t, size_t);
void free(void *);
void *malloc(size_t);
char *mkdtemp(char *);
int mkstemps(char *, int);
void *realloc(void *, size_t);
char *realpath(const char *, char *);
int setenv(const char *, const char *, int);
int unsetenv(const char *);
int unlockpt(int);
int grantpt(int);
char *ptsname(int);
]]

if --[[ android_arm|android_arm64|android_x64|android_x86 ]] bit.band(platform, 0xf) ~= 0 then
ffi.cdef[[
char *basename(const char *);
char *dirname(const char *);
]]
elseif --[[ linux_arm|linux_arm64|linux_x64|macos ]] bit.band(platform, 0xf0) ~= 0 then
ffi.cdef[[
char *basename(char *);
char *dirname(char *);
]]
end

ffi.cdef[[
int fcntl(int, int, ...);
int open(const char *, int, ...);
]]

if --[[ android_arm|android_x86|macos ]] bit.band(platform, 0x89) ~= 0 then
ffi.cdef[[ static const unsigned HAVE_POSIX_FALLOCATE = 0; ]]
elseif --[[ android_arm64|android_x64|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x76) ~= 0 then
ffi.cdef[[ static const unsigned HAVE_POSIX_FALLOCATE = 1; ]]
end

if --[[ android_arm64|android_x64|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x76) ~= 0 then
ffi.cdef[[ int posix_fallocate(int, off_t, off_t); ]]
end

ffi.cdef[[
typedef struct _IO_FILE FILE;
int fclose(FILE *);
int ferror(FILE *);
int fflush(FILE *);
int fileno(FILE *);
FILE *fopen(const char *, const char *);
int fputs(const char *, FILE *);
size_t fread(void *, size_t, size_t, FILE *);
size_t fwrite(const void *, size_t, size_t, FILE *);
int sprintf(char *, const char *, ...);
void _exit(int);
int access(const char *, int);
int close(int);
int dup2(int, int);
int execl(const char *, const char *, ...);
int execlp(const char *, const char *, ...);
]]

if --[[ android_arm|android_arm64|android_x64|android_x86|macos ]] bit.band(platform, 0x8f) ~= 0 then
ffi.cdef[[ int execvp(const char *, char *const *); ]]
elseif --[[ linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x70) ~= 0 then
ffi.cdef[[ int execvp(const char *, char *const[]); ]]
end

ffi.cdef[[
int fdatasync(int);
pid_t fork(void);
int fsync(int);
int ftruncate(int, off_t);
pid_t getpid(void);
pid_t getppid(void);
uid_t getuid(void);
off_t lseek(int, off_t, int);
int pause(void);
int pipe(int[2]);
ssize_t read(int, void *, size_t);
int setpgid(pid_t, pid_t);
pid_t setsid(void);
unsigned sleep(unsigned);
int usleep(useconds_t);
ssize_t write(int, const void *, size_t);
void *memchr(const void *, int, size_t);
int memcmp(const void *, const void *, size_t);
void *memmove(void *, const void *, size_t);
int strcasecmp(const char *, const char *);
int strcmp(const char *, const char *);
int strcoll(const char *, const char *);
char *strdup(const char *);
char *strerror(int);
int strncasecmp(const char *, const char *, size_t);
size_t strnlen(const char *, size_t);
static const unsigned SIGTERM = 15;
int kill(pid_t, int);
static const unsigned IFNAMSIZ = 16;
static const unsigned IFF_LOOPBACK = 8;
static const unsigned IFF_UP = 1;
static const unsigned IPPROTO_IP = 0;
static const unsigned IPPROTO_ICMP = 1;
static const unsigned RTF_GATEWAY = 2;
static const unsigned RTF_UP = 1;
int connect(int, const struct sockaddr *, socklen_t);
ssize_t recv(int, void *, size_t, int);
ssize_t send(int, const void *, size_t, int);
ssize_t sendto(int, const void *, size_t, int, const struct sockaddr *, socklen_t);
int socket(int, int, int);
const char *gai_strerror(int);
]]

if --[[ android_arm|android_arm64|android_x64|android_x86 ]] bit.band(platform, 0xf) ~= 0 then
ffi.cdef[[ int getnameinfo(const struct sockaddr *, socklen_t, char *, size_t, char *, size_t, int); ]]
elseif --[[ linux_arm|linux_arm64|linux_x64|macos ]] bit.band(platform, 0xf0) ~= 0 then
ffi.cdef[[ int getnameinfo(const struct sockaddr *, socklen_t, char *, socklen_t, char *, socklen_t, int); ]]
end

ffi.cdef[[
int inet_aton(const char *, struct in_addr *);
int statvfs(const char *, struct statvfs *);
static const unsigned WNOHANG = 1;
pid_t waitpid(pid_t, int *, int);
]]

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[ static const unsigned MAP_ANONYMOUS = 32; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ static const unsigned MAP_ANONYMOUS = 4096; ]]
end

ffi.cdef[[
static const int MAP_FAILED = -1;
static const unsigned MAP_SHARED = 1;
static const unsigned PROT_READ = 1;
static const unsigned PROT_WRITE = 2;
void *mmap(void *, size_t, int, int, int, off_t);
int munmap(void *, size_t);
]]

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[
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
]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[
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
  char *tm_zone;
};
]]
end

ffi.cdef[[
int clock_getres(clockid_t, struct timespec *);
int clock_gettime(clockid_t, struct timespec *);
struct tm *gmtime(const time_t *);
struct tm *gmtime_r(const time_t *, struct tm *);
struct tm *localtime(const time_t *);
size_t strftime(char *, size_t, const char *, const struct tm *);
time_t time(time_t *);
]]

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[ time_t timegm(struct tm *); ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ time_t timegm(struct tm *const); ]]
end

ffi.cdef[[
struct timezone {
  int tz_minuteswest;
  int tz_dsttime;
};
]]

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm ]] bit.band(platform, 0x1f) ~= 0 then
ffi.cdef[[ int gettimeofday(struct timeval *, struct timezone *); ]]
elseif --[[ linux_arm64|linux_x64|macos ]] bit.band(platform, 0xe0) ~= 0 then
ffi.cdef[[ int gettimeofday(struct timeval *, void *); ]]
end

ffi.cdef[[
int settimeofday(const struct timeval *, const struct timezone *);
static const unsigned PRIO_PROCESS = 0;
static const unsigned PRIO_PGRP = 1;
static const unsigned PRIO_USER = 2;
int setpriority(int, id_t, int);
]]

if --[[ android_arm|android_arm64|android_x64|android_x86|linux_arm|linux_arm64|linux_x64 ]] bit.band(platform, 0x7f) ~= 0 then
ffi.cdef[[ static const unsigned TCIFLUSH = 0; ]]
elseif --[[ macos ]] platform == 0x80 then
ffi.cdef[[ static const unsigned TCIFLUSH = 1; ]]
end

ffi.cdef[[
int tcdrain(int);
int tcflush(int, int);
uint32_t htonl(uint32_t);
uint16_t htons(uint16_t);
uint32_t ntohl(uint32_t);
uint16_t ntohs(uint16_t);
void freeifaddrs(struct ifaddrs *);
int getifaddrs(struct ifaddrs **);
]]

if --[[ android_arm|android_arm64|android_x64|android_x86 ]] bit.band(platform, 0xf) ~= 0 then
ffi.cdef[[ int ioctl(int, int, ...); ]]
elseif --[[ linux_arm|linux_arm64|linux_x64|macos ]] bit.band(platform, 0xf0) ~= 0 then
ffi.cdef[[ int ioctl(int, unsigned long, ...); ]]
end

ffi.cdef[[
static const unsigned ICMP_ECHO = 8;
static const unsigned ICMP_ECHOREPLY = 0;
static const unsigned ICMP_MINLEN = 8;
]]
