/* #define __APPLE__ */
/* #undef __linux__ */

#if defined(__ANDROID__)
# define __asm__(...)
// Avoid duplicate `ioctl` prototypes.
# define BIONIC_IOCTL_NO_SIGNEDNESS_OVERLOAD
// `basename(…)` if macro for `__posix_basename(…)`.
# define __posix_basename  basename
#elif defined(__APPLE__)
# define __asm(...)
#elif defined(__linux__)
# define _BSD_SOURCE
# define _DEFAULT_SOURCE
# define _XOPEN_SOURCE  800
// tree-sitter-c does not automatically handle `__const` as an alias for `const`.
# define __const const
// `basename(…)` if macro for `__xpg_basename(…)`.
# define __xpg_basename  basename
#endif

#include <libgen.h>

#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/resource.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/un.h>
#include <sys/wait.h>

#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <ifaddrs.h>
#include <limits.h>
#if !defined(__ANDROID__) && !defined(__APPLE__)
# include <mqueue.h>
#endif
#include <net/if.h>
#if defined(__APPLE__)
# include <net/if_dl.h>
# include <net/if_types.h>
#endif
#include <net/route.h>
#include <netdb.h>
#include <netinet/ip.h>
#include <netinet/ip_icmp.h>
#if defined(__linux__)
# include <netpacket/packet.h>
#endif
#include <poll.h>
#include <pthread.h>
#if defined(__linux__)
# include <sched.h>
#endif
#include <signal.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>

#if defined(__linux__)
// Avoid conflicts with <net/if.h>.
# define ifconf  linux_ifconf
# define ifmap   linux_ifmap
# define ifreq   linux_ifreq
# include <linux/sched.h>
# include <linux/socket.h>
# include <linux/wireless.h>
# undef ifconf
# undef ifmap
# undef ifreq
#endif

#if defined(__ANDROID__)
cdecl_type_replace(__be16, uint16_t);
cdecl_type_replace(__be32, uint32_t);
cdecl_type_replace(__u8, uint8_t);
cdecl_type_replace(__u16, uint16_t);
cdecl_type_replace(__u32, uint32_t);
cdecl_type_replace(__kernel_long_t, long);
cdecl_type_replace(__kernel_ulong_t, unsigned long);
#elif defined(__APPLE__)
cdecl_type_replace(__int8_t, int8_t);
cdecl_type_replace(__int16_t, int16_t);
cdecl_type_replace(__int32_t, int32_t);
cdecl_type_replace(__int64_t, int64_t);
cdecl_type_replace(__uint8_t, uint8_t);
cdecl_type_replace(__uint16_t, uint16_t);
cdecl_type_replace(__uint32_t, uint32_t);
cdecl_type_replace(__uint64_t, uint64_t);
cdecl_type_replace(u_char, unsigned char);
cdecl_type_replace(u_short, unsigned short);
cdecl_type_replace(u_int, unsigned);
cdecl_type_replace(u_long, unsigned long);
cdecl_type_replace(u_int8_t, uint8_t);
cdecl_type_replace(u_int16_t, uint16_t);
cdecl_type_replace(u_int32_t, uint32_t);
#elif defined(__linux__)
cdecl_type_replace(__s8, int8_t);
cdecl_type_replace(__s16, int16_t);
cdecl_type_replace(__s32, int32_t);
cdecl_type_replace(__u8, uint8_t);
cdecl_type_replace(__u16, uint16_t);
cdecl_type_replace(__u32, uint32_t);
# if defined(__SYSCALL_SLONG_TYPE)
cdecl_type_replace(__syscall_slong_t, long);
# endif
# if __WORDSIZE == 32
cdecl_type_replace(__u_quad_t, unsigned long long);
# endif
#endif

cdecl_const(EAGAIN);
cdecl_const(EINTR);
cdecl_const(EINVAL);
cdecl_const(ENODEV);
cdecl_const(ENOSYS);
cdecl_const(EPERM);
cdecl_const(EPIPE);
cdecl_const(ETIME);
cdecl_const(ETIMEDOUT);

cdecl_const(O_APPEND);
#if defined(O_CLOEXEC)
cdecl_const(O_CLOEXEC);
#endif
cdecl_const(O_CREAT);
cdecl_const(O_NONBLOCK);
cdecl_const(O_RDONLY);
cdecl_const(O_RDWR);
cdecl_const(O_TRUNC);
cdecl_const(O_WRONLY);

cdecl_const(F_OK);
cdecl_const(R_OK);
cdecl_const(W_OK);
cdecl_const(X_OK);

cdecl_const(S_IRGRP);
cdecl_const(S_IROTH);
cdecl_const(S_IRUSR);
cdecl_const(S_IRWXG);
cdecl_const(S_IRWXO);
cdecl_const(S_IRWXU);
cdecl_const(S_IWGRP);
cdecl_const(S_IWOTH);
cdecl_const(S_IWUSR);
cdecl_const(S_IXGRP);
cdecl_const(S_IXOTH);
cdecl_const(S_IXUSR);

cdecl_const(SEEK_CUR);
cdecl_const(SEEK_END);
cdecl_const(SEEK_SET);

cdecl_const(PATH_MAX);

#if defined(__ANDROID__)
#elif defined(__APPLE__)
# define CLOCK_BOOTTIME          -1 // not available
# define CLOCK_MONOTONIC_COARSE  CLOCK_MONOTONIC_RAW_APPROX
# define CLOCK_REALTIME_COARSE   -1 // not available
#elif defined(__linux__)
# if !defined(CLOCK_BOOTTIME)
#  define CLOCK_BOOTTIME  7
# endif
#endif

cdecl_const(CLOCK_BOOTTIME);
cdecl_const(CLOCK_MONOTONIC);
cdecl_const(CLOCK_MONOTONIC_COARSE);
cdecl_const(CLOCK_REALTIME);
cdecl_const(CLOCK_REALTIME_COARSE);

#if defined(__ANDROID__)
cdecl_type_replace(__kernel_clockid_t, clockid_t);
cdecl_type(__kernel_clockid_t);
#elif defined(__APPLE__)
// On macOS, `clockid_t` is an enum.
_Static_assert(__builtin_types_compatible_p(unsigned, clockid_t), "unsigned != clockid_t");
cdecl_out(type_clockid_t, typedef unsigned clockid_t;);
#elif defined(__linux__)
cdecl_type_replace(__clockid_t, clockid_t);
cdecl_type(__clockid_t);
#endif

cdecl_const(FIONREAD);

#if defined(__ANDROID__)
_Static_assert(__builtin_types_compatible_p(__kernel_old_time_t, __kernel_time_t), "__kernel_old_time_t != __kernel_time_t");
cdecl_type_replace(__kernel_old_time_t, time_t);
cdecl_type_replace(__kernel_suseconds_t, suseconds_t);
cdecl_type_replace(__kernel_time_t, time_t);
cdecl_type_replace(__time_t, time_t);
cdecl_type_replace(__useconds_t, useconds_t);
cdecl_type(__kernel_suseconds_t);
cdecl_type(__kernel_time_t);
cdecl_type(__useconds_t);
#elif defined(__APPLE__)
cdecl_type_replace(__darwin_suseconds_t, suseconds_t);
cdecl_type_replace(__darwin_time_t, time_t);
cdecl_type_replace(__darwin_useconds_t, useconds_t);
cdecl_type(__darwin_suseconds_t);
cdecl_type(__darwin_time_t);
cdecl_type(__darwin_useconds_t);
#elif defined(__linux__)
cdecl_type_replace(__suseconds_t, suseconds_t);
cdecl_type_replace(__time_t, time_t);
cdecl_type_replace(__useconds_t, useconds_t);
cdecl_type(__suseconds_t);
cdecl_type(__time_t);
cdecl_type(__useconds_t);
#endif

cdecl_struct(timeval);
cdecl_struct(timespec);

#if defined(__ANDROID__)
cdecl_type_replace(__id_t, id_t);
cdecl_type_replace(__kernel_gid32_t, uint32_t);
cdecl_type_replace(__kernel_mode_t, mode_t);
cdecl_type_replace(__kernel_off_t, off_t);
cdecl_type_replace(__kernel_pid_t, pid_t);
cdecl_type_replace(__kernel_uid32_t, uint32_t);
cdecl_type_replace(__mode_t, mode_t);
cdecl_type_replace(__pid_t, pid_t);
cdecl_type_replace(__uid_t, uid_t);
cdecl_type(__id_t);
cdecl_type(__kernel_mode_t);
cdecl_type(__kernel_off_t);
cdecl_type(__kernel_pid_t);
cdecl_type(__uid_t);
#elif defined(__APPLE__)
cdecl_type_replace(__darwin_blkcnt_t, blkcnt_t);
cdecl_type_replace(__darwin_blksize_t, blksize_t);
cdecl_type_replace(__darwin_id_t, id_t);
cdecl_type_replace(__darwin_mode_t, mode_t);
cdecl_type_replace(__darwin_off_t, off_t);
cdecl_type_replace(__darwin_pid_t, pid_t);
cdecl_type_replace(__darwin_uid_t, uid_t);
cdecl_type(__darwin_blkcnt_t);
cdecl_type(__darwin_blksize_t);
cdecl_type(__darwin_id_t);
cdecl_type(__darwin_ino64_t);
cdecl_type(__darwin_mode_t);
cdecl_type(__darwin_off_t);
cdecl_type(__darwin_pid_t);
cdecl_type(__darwin_uid_t);
#elif defined(__linux__)
cdecl_type_replace(__blkcnt_t, blkcnt_t);
cdecl_type_replace(__blksize_t, blksize_t);
cdecl_type_replace(__id_t, id_t);
cdecl_type_replace(__mode_t, mode_t);
cdecl_type_replace(__off_t, off_t);
cdecl_type_replace(__pid_t, pid_t);
cdecl_type_replace(__uid_t, uid_t);
cdecl_type(__blkcnt_t);
cdecl_type(__blksize_t);
cdecl_type(__id_t);
cdecl_type(__mode_t);
cdecl_type(__off_t);
cdecl_type(__pid_t);
cdecl_type(__uid_t);
#endif

#if defined(__ANDROID__)
cdecl_type(fsblkcnt_t);
cdecl_type(fsfilcnt_t);
#elif defined(__APPLE__)
cdecl_type_replace(__darwin_fsblkcnt_t, fsblkcnt_t);
cdecl_type_replace(__darwin_fsfilcnt_t, fsfilcnt_t);
cdecl_type(__darwin_fsblkcnt_t);
cdecl_type(__darwin_fsfilcnt_t);
#elif defined(__linux__)
cdecl_type_replace(__fsblkcnt_t, fsblkcnt_t);
cdecl_type_replace(__fsfilcnt_t, fsfilcnt_t);
cdecl_type(__fsblkcnt_t);
cdecl_type(__fsfilcnt_t);
#endif

cdecl_struct(statvfs);

#if defined(__APPLE__)
cdecl_const(IFT_ETHER);
#endif

cdecl_const(AF_INET);
cdecl_const(AF_INET6);
#if defined(__APPLE__)
cdecl_const(AF_LINK);
#endif
#if defined(__linux__)
cdecl_const(AF_PACKET);
#endif
cdecl_const(AF_UNIX);

cdecl_const(NI_MAXHOST);
cdecl_const(NI_NUMERICHOST);

#if defined(__APPLE__)
# define SOCK_CLOEXEC   0 // not available
# define SOCK_NONBLOCK  0 // not available
#endif
cdecl_const(SOCK_CLOEXEC);
cdecl_const(SOCK_DGRAM);
cdecl_const(SOCK_NONBLOCK);
cdecl_const(SOCK_RAW);
cdecl_const(SOCK_SEQPACKET);

#if defined(__ANDROID__)
#elif defined(__APPLE__)
cdecl_type(caddr_t);
#elif defined(__linux__)
cdecl_type_replace(__caddr_t, caddr_t);
cdecl_type(__caddr_t);
#endif

cdecl_type(in_addr_t);
cdecl_type(in_port_t);

#if defined(__ANDROID__)
cdecl_type_replace(__kernel_sa_family_t, sa_family_t);
cdecl_type(__kernel_sa_family_t);
#elif defined(__APPLE__)
cdecl_type(sa_family_t);
#elif defined(__linux__)
cdecl_type(sa_family_t);
#endif

#if defined(__APPLE__)
cdecl_type_replace(__darwin_socklen_t, socklen_t);
cdecl_type(__darwin_socklen_t);
#elif defined(__linux__)
cdecl_type_replace(__socklen_t, socklen_t);
cdecl_type(__socklen_t);
#endif

cdecl_struct(in_addr);
cdecl_struct(in6_addr);
cdecl_struct(sockaddr);
#if defined(__APPLE__)
cdecl_struct(sockaddr_dl);
#endif
#if defined(__linux__)
cdecl_struct(sockaddr_ll);
#endif
cdecl_struct(sockaddr_in);
cdecl_struct(sockaddr_in6);
cdecl_struct(sockaddr_un);
cdecl_struct(sockaddr_storage);

cdecl_struct(ifaddrs);
#if !defined(__ANDROID__)
# if defined(__APPLE__)
cdecl_struct(ifdevmtu);
cdecl_struct(ifkpi);
# else
cdecl_struct(ifmap);
# endif
cdecl_struct(ifreq);
#endif

#if defined(__linux__) && !defined(__ANDROID__)

cdecl_const(SIOCGIWESSID);

cdecl_const(IW_ENCODE_INDEX);
cdecl_const(IW_ESSID_MAX_SIZE);

cdecl_struct(iw_freq);
cdecl_struct(iw_param);
cdecl_struct(iw_point);
cdecl_struct(iw_quality);
cdecl_union(iwreq_data);
cdecl_struct(iwreq);

#endif

cdecl_type(nfds_t);

#if !defined(__ANDROID__) && !defined(__APPLE__)

cdecl_type(mqd_t);

cdecl_func(mq_close);
cdecl_func(mq_open);
cdecl_func(mq_receive);

#endif

cdecl_const(PTHREAD_CREATE_DETACHED);

#if defined(__ANDROID__)
cdecl_type(pthread_attr_t);
cdecl_type(pthread_t);
#elif defined(__APPLE__)
cdecl_type_replace(__darwin_pthread_attr_t, pthread_attr_t);
cdecl_type_replace(__darwin_pthread_t, pthread_t);
cdecl_struct(_opaque_pthread_attr_t);
cdecl_type(__darwin_pthread_attr_t);
cdecl_type(__darwin_pthread_t);
#elif defined(__linux__)
# if defined(__have_pthread_attr_t)
cdecl_union(pthread_attr_t);
# endif
cdecl_type(pthread_attr_t);
cdecl_type(pthread_t);
#endif

cdecl_func(pthread_attr_destroy);
cdecl_func(pthread_attr_init);
cdecl_func(pthread_attr_setdetachstate);
cdecl_func(pthread_create);

#if defined(__linux__)

cdecl_const(SCHED_BATCH);

cdecl_struct(sched_param);

cdecl_func(sched_setscheduler);

#endif

#if defined(__linux__) && !defined(__ANDROID__)

cdecl_func(shm_open);

#endif

cdecl_const(POLLERR);
cdecl_const(POLLHUP);
cdecl_const(POLLIN);
cdecl_const(POLLOUT);

cdecl_struct(pollfd);

cdecl_func(poll);

cdecl_func(calloc);
cdecl_func(free);
cdecl_func(malloc);
cdecl_func(mkdtemp);
cdecl_func(mkstemps);
cdecl_func(realloc);
cdecl_func(realpath);
cdecl_func(setenv);
cdecl_func(unsetenv);
cdecl_func(unlockpt);
cdecl_func(grantpt);
cdecl_func(ptsname);

cdecl_func(basename);
cdecl_func(dirname);

cdecl_func(fcntl);
cdecl_func(open);

#if defined(__ANDROID__)
# if __ANDROID_API__ >= 21
#  define HAVE_POSIX_FALLOCATE  1
# endif
#elif defined(__linux__)
# define HAVE_POSIX_FALLOCATE  1
#endif
#if !defined(HAVE_POSIX_FALLOCATE)
# define HAVE_POSIX_FALLOCATE  0
#endif
cdecl_const(HAVE_POSIX_FALLOCATE);
#if HAVE_POSIX_FALLOCATE
cdecl_func(posix_fallocate);
#endif

cdecl_out(type_FILE, typedef struct _IO_FILE FILE;);

cdecl_func(fclose);
cdecl_func(ferror);
cdecl_func(fflush);
cdecl_func(fileno);
cdecl_func(fopen);
cdecl_func(fputs);
cdecl_func(fread);
cdecl_func(fwrite);
cdecl_func(sprintf);

#if !defined(__APPLE__)
# if !defined(__ANDROID__)
cdecl_type_replace(__off_t, off_t);
# endif
cdecl_type_replace(__pid_t, pid_t);
cdecl_type_replace(__uid_t, uid_t);
cdecl_type_replace(__useconds_t, useconds_t);
#endif

cdecl_func(_exit);
cdecl_func(access);
cdecl_func(close);
cdecl_func(dup2);
cdecl_func(execl);
cdecl_func(execlp);
cdecl_func(execvp);
#if defined(__APPLE__)
// Available, even if not declared anywhere…
cdecl_out(func_fdatasync, int fdatasync(int););
#else
cdecl_func(fdatasync);
#endif
cdecl_func(fork);
cdecl_func(fsync);
cdecl_func(ftruncate);
cdecl_func(getpid);
cdecl_func(getppid);
cdecl_func(getuid);
cdecl_func(lseek);
cdecl_func(pause);
cdecl_func(pipe);
cdecl_func(read);
cdecl_func(setpgid);
cdecl_func(setsid);
cdecl_func(sleep);
cdecl_func(usleep);
cdecl_func(write);

cdecl_func(memchr);
cdecl_func(memcmp);
cdecl_func(memmove);

cdecl_func(strcasecmp);
cdecl_func(strcmp);
cdecl_func(strcoll);
cdecl_func(strdup);
cdecl_func(strerror);
cdecl_func(strncasecmp);
cdecl_func(strnlen);

cdecl_const(SIGTERM);

cdecl_func(kill);

cdecl_const(IFNAMSIZ);

cdecl_const(IFF_LOOPBACK);
cdecl_const(IFF_UP);

cdecl_const(IPPROTO_IP);
cdecl_const(IPPROTO_ICMP);

cdecl_const(RTF_GATEWAY);
cdecl_const(RTF_UP);

cdecl_func(connect);
cdecl_func(recv);
cdecl_func(send);
cdecl_func(sendto);
cdecl_func(socket);

cdecl_func(gai_strerror);
cdecl_func(getnameinfo);

cdecl_func(inet_aton);

cdecl_func(statvfs);

cdecl_const(WNOHANG);

cdecl_func(waitpid);

// _Static_assert(MAP_FAILED == (void *)-1, "MAP_FAILED != -1");
cdecl_const(MAP_ANONYMOUS);
cdecl_out(const_MAP_FAILED, static const int MAP_FAILED = -1;);
cdecl_const(MAP_SHARED);
cdecl_const(PROT_READ);
cdecl_const(PROT_WRITE);

cdecl_func(mmap);
cdecl_func(munmap);

cdecl_struct(tm);

cdecl_func(clock_getres);
cdecl_func(clock_gettime);
cdecl_func(gmtime);
cdecl_func(gmtime_r);
cdecl_func(localtime);
cdecl_func(strftime);
cdecl_func(time);
cdecl_func(timegm);

cdecl_struct(timezone);
#if defined(__linux__) && defined(__arm__) && !defined(__ANDROID__)
cdecl_type_replace(__timezone_ptr_t, struct timezone *);
#endif

cdecl_func(gettimeofday);
cdecl_func(settimeofday);

cdecl_const(PRIO_PROCESS);
cdecl_const(PRIO_PGRP);
cdecl_const(PRIO_USER);

#if defined(__linux__) && !defined(__ANDROID__)
cdecl_type_replace(__priority_which_t, int);
#endif

cdecl_func(setpriority);

cdecl_const(TCIFLUSH);

cdecl_func(tcdrain);
cdecl_func(tcflush);

#if defined(__ANDROID__) && __ANDROID_API__ < 21 || defined(__APPLE__)
# undef htonl
# undef htons
# undef ntohl
# undef ntohs
uint32_t htonl(uint32_t);
uint16_t htons(uint16_t);
uint32_t ntohl(uint32_t);
uint16_t ntohs(uint16_t);
#endif

cdecl_func(htonl);
cdecl_func(htons);
cdecl_func(ntohl);
cdecl_func(ntohs);

#if defined(__ANDROID__) && __ANDROID_API__ < 24
void freeifaddrs(struct ifaddrs *);
int getifaddrs(struct ifaddrs **);
#endif

cdecl_func(freeifaddrs);
cdecl_func(getifaddrs);

cdecl_func(ioctl);

cdecl_const(ICMP_ECHO);
cdecl_const(ICMP_ECHOREPLY);
cdecl_const(ICMP_MINLEN);
