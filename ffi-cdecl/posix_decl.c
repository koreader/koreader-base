// For Linux <sched.h> stuff
#define _GNU_SOURCE

#include <sys/mman.h>
//#include <stropts.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <poll.h>
#include <sys/statvfs.h>
#include <sys/time.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <linux/limits.h>
#include <libgen.h>
#include <sys/ioctl.h>
#include <mqueue.h>
#include <time.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sched.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netdb.h>
#include <ifaddrs.h>
#include <linux/if_link.h>
#include <net/if.h>
#include <linux/in.h>
#include <net/route.h>
#include <linux/if.h>
#include <linux/wireless.h>
#include <linux/types.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/ip_icmp.h>
#include <errno.h>

#include "ffi-cdecl.h"

cdecl_const(EPERM)
cdecl_const(EINTR)
cdecl_const(EAGAIN)
cdecl_const(EINVAL)
cdecl_const(ENODEV)
cdecl_const(ENOSYS)
cdecl_const(EPIPE)
cdecl_const(ETIME)
cdecl_const(ETIMEDOUT)

// NOTE: Let's hope we'll all have moved to 64-bit by the time Y2038 becomes an issue...
//       c.f., https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit?id=152194fe9c3f
cdecl_type(off_t)
cdecl_type(time_t)
cdecl_type(suseconds_t)

cdecl_struct(timeval)
cdecl_struct(timezone)
cdecl_struct(statvfs)

cdecl_func(pipe)
cdecl_func(fork)
cdecl_func(dup)
cdecl_func(dup2)

cdecl_const(O_APPEND)
cdecl_const(O_CREAT)
cdecl_const(O_TRUNC)
cdecl_const(O_RDWR)
cdecl_const(O_RDONLY)
cdecl_const(O_WRONLY)
cdecl_const(O_NONBLOCK)
cdecl_const(O_CLOEXEC)
cdecl_const(S_IRUSR)
cdecl_const(S_IWUSR)
cdecl_const(S_IXUSR)
cdecl_const(S_IRWXU)
cdecl_const(S_IRGRP)
cdecl_const(S_IWGRP)
cdecl_const(S_IXGRP)
cdecl_const(S_IRWXG)
cdecl_const(S_IROTH)
cdecl_const(S_IWOTH)
cdecl_const(S_IXOTH)
cdecl_const(S_IRWXO)
cdecl_func(open)
cdecl_func(mq_open)
cdecl_func(mq_receive)
cdecl_func(mq_close)
cdecl_func(close)
cdecl_func(fcntl)
cdecl_func(execl)
cdecl_func(execlp)
cdecl_func(execv)
cdecl_func(execvp)
cdecl_func(write)
cdecl_func(read)
cdecl_func(kill)
cdecl_const(WNOHANG)
cdecl_func(waitpid)
cdecl_func(getpid)
cdecl_func(getppid)
cdecl_func(setpgid)

cdecl_struct(pollfd)
cdecl_const(POLLIN)
cdecl_const(POLLOUT)
cdecl_const(POLLERR)
cdecl_const(POLLHUP)
cdecl_func(poll)

cdecl_const(PROT_READ)
cdecl_const(PROT_WRITE)
cdecl_const(MAP_SHARED)
cdecl_const(MAP_ANONYMOUS)
cdecl_const(MAP_FAILED)
cdecl_const(PATH_MAX)
cdecl_func(memcmp)
cdecl_func(mmap)  // NOTE: off_t gets squished by ffi-cdecl...
cdecl_func(munmap)

cdecl_func(ioctl)
//cdecl_func(Sleep) // Win32
cdecl_func(sleep)
cdecl_func(usleep)
cdecl_func(nanosleep)
cdecl_func(statvfs)
cdecl_func(gettimeofday)
cdecl_func(realpath)
cdecl_func(basename) // NOTE: We'll want the GNU one (c.f., https://github.com/koreader/koreader/issues/4543)
cdecl_func(dirname)

// May require librt at runtime!
cdecl_struct(timespec)
cdecl_type(clockid_t)
cdecl_const(CLOCK_REALTIME)
cdecl_const(CLOCK_REALTIME_COARSE)
cdecl_const(CLOCK_MONOTONIC)
cdecl_const(CLOCK_MONOTONIC_COARSE)
cdecl_const(CLOCK_MONOTONIC_RAW)
cdecl_const(CLOCK_BOOTTIME)
cdecl_const(CLOCK_TAI)
cdecl_func(clock_getres)
cdecl_func(clock_gettime)
cdecl_func(clock_settime)
cdecl_const(TIMER_ABSTIME)
cdecl_func(clock_nanosleep)

cdecl_func(malloc)
cdecl_func(calloc)
cdecl_func(free)
cdecl_func(memset)

cdecl_func(strdup)
cdecl_func(strndup)
cdecl_func(strcoll)
cdecl_func(strcmp)
cdecl_func(strcasecmp)

cdecl_const(F_OK)
cdecl_func(access)

cdecl_type(FILE)
cdecl_type(dev_t)
cdecl_type(ino_t)
cdecl_type(mode_t)
cdecl_type(nlink_t)
cdecl_type(uid_t)
cdecl_type(gid_t)
cdecl_type(blksize_t)
cdecl_type(blkcnt_t)
cdecl_struct(stat)

cdecl_func(getuid)

cdecl_func(fopen)
// NOTE: Requires a somewhat recent glibc to actually have those symbols, as, on older versions,
//       they're simply macros redirecting to __xstat...
cdecl_func(stat)
cdecl_func(fstat)
cdecl_func(lstat)
cdecl_func(fread)
cdecl_func(fwrite)
cdecl_func(fclose)
cdecl_func(fflush)
cdecl_func(feof)
cdecl_func(ferror)
cdecl_func(printf)
cdecl_func(sprintf)
cdecl_func(fprintf)
cdecl_func(fputc)

cdecl_const(FIONREAD)
cdecl_func(fileno)
cdecl_func(strerror)
cdecl_func(fsync)
cdecl_func(fdatasync)

cdecl_func(setenv)
cdecl_func(unsetenv)
//cdecl_func(_putenv) // Win32

cdecl_type(id_t)
cdecl_enum(__priority_which)
cdecl_type(__priority_which_t)
cdecl_func(getpriority)
cdecl_func(setpriority)

cdecl_type(pid_t)
cdecl_struct(sched_param)
cdecl_const(SCHED_OTHER)
cdecl_const(SCHED_BATCH)
cdecl_const(SCHED_IDLE)
cdecl_const(SCHED_FIFO)
cdecl_const(SCHED_RR)
cdecl_const(SCHED_RESET_ON_FORK)
cdecl_func(sched_getscheduler)
cdecl_func(sched_setscheduler)
cdecl_func(sched_getparam)
cdecl_func(sched_setparam)
// No Glibc wrappers around these syscalls:
/*
cdecl_struct(sched_attr)
cdecl_const(SCHED_FLAG_RESET_ON_FORK)
cdecl_const(SCHED_FLAG_RECLAIM)
cdecl_const(SCHED_FLAG_DL_OVERRUN)
cdecl_const(SCHED_FLAG_KEEP_POLICY)
cdecl_const(SCHED_FLAG_KEEP_PARAMS)
cdecl_func(sched_getattr)
cdecl_func(sched_setattr)
*/
cdecl_type(cpu_set_t)
cdecl_func(sched_getaffinity)
cdecl_func(sched_setaffinity)
cdecl_func(sched_yield)

cdecl_struct(sockaddr) // May be provided by lj-wpaclient (... which is platform-specific)
cdecl_struct(ifaddrs)
cdecl_const(NI_MAXHOST)
cdecl_func(getifaddrs)
cdecl_const(AF_INET)
cdecl_const(AF_INET6)
cdecl_func(getnameinfo)
cdecl_struct(in_addr)
cdecl_struct(sockaddr_in)
cdecl_struct(in6_addr)
cdecl_struct(sockaddr_in6)
cdecl_const(NI_NUMERICHOST)
cdecl_func(gai_strerror)
cdecl_func(freeifaddrs)
cdecl_func(socket)
cdecl_const(PF_INET)
cdecl_const(SOCK_DGRAM)
cdecl_const(SOCK_RAW)
cdecl_const(SOCK_NONBLOCK)
cdecl_const(SOCK_CLOEXEC)
cdecl_const(IPPROTO_IP)
cdecl_const(IPPROTO_ICMP)
cdecl_const(IFNAMSIZ)
cdecl_struct(ifmap)
cdecl_struct(ifreq)
cdecl_const(SIOCGIFHWADDR)
cdecl_const(RTF_UP)
cdecl_const(RTF_GATEWAY)
/*
cdecl_const(RTF_HOST)
cdecl_const(RTF_REINSTATE)
cdecl_const(RTF_DYNAMIC)
cdecl_const(RTF_MODIFIED)
cdecl_const(RTF_DEFAULT)
cdecl_const(RTF_ADDRCONF)
cdecl_const(RTF_CACHE)
cdecl_const(RTF_REJECT)
cdecl_const(RTF_NONEXTHOP)
*/
cdecl_const(IFF_UP)
/*
cdecl_const(IFF_BROADCAST)
cdecl_const(IFF_DEBUG)
*/
cdecl_const(IFF_LOOPBACK)
/*
cdecl_const(IFF_POINTOPOINT)
cdecl_const(IFF_RUNNING)
cdecl_const(IFF_NOARP)
cdecl_const(IFF_PROMISC)
cdecl_const(IFF_NOTRAILERS)
cdecl_const(IFF_ALLMULTI)
cdecl_const(IFF_MASTER)
cdecl_const(IFF_SLAVE)
cdecl_const(IFF_MULTICAST)
cdecl_const(IFF_PORTSEL)
cdecl_const(IFF_AUTOMEDIA)
cdecl_const(IFF_DYNAMIC)
cdecl_const(IFF_LOWER_UP)
cdecl_const(IFF_DORMANT)
cdecl_const(IFF_ECHO)
*/
cdecl_struct(iw_point)
cdecl_struct(iw_param)
cdecl_struct(iw_freq)
cdecl_struct(iw_quality)
cdecl_union(iwreq_data)
cdecl_struct(iwreq)
cdecl_const(SIOCGIWNAME)
cdecl_const(SIOCGIWESSID)
cdecl_type(caddr_t)
cdecl_const(IW_ESSID_MAX_SIZE)
cdecl_const(IW_ENCODE_INDEX)
cdecl_type(socklen_t)
cdecl_struct(icmphdr)
cdecl_struct(ih_idseq)
cdecl_struct(ih_pmtu)
cdecl_struct(ih_rtradv)
cdecl_struct(ip)
cdecl_struct(icmp_ra_addr)
cdecl_struct(icmp)
cdecl_const(ICMP_MINLEN)
cdecl_const(ICMP_ECHO)
cdecl_const(ICMP_ECHOREPLY)
cdecl_func(sendto)
cdecl_func(recv)
cdecl_struct(iphdr)
cdecl_func(inet_aton)
cdecl_func(htonl)
cdecl_func(htons)
