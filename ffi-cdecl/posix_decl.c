#include <sys/mman.h>
//#include <stropts.h>
#include <unistd.h>
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
#include <errno.h>

#include "ffi-cdecl.h"

cdecl_const(EINTR)
cdecl_const(ETIME)
cdecl_const(EAGAIN)
cdecl_const(EINVAL)
cdecl_const(ENOSYS)
cdecl_const(ETIMEDOUT)

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
cdecl_func(waitpid)
cdecl_func(getpid)
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
cdecl_const(MAP_FAILED)
cdecl_const(PATH_MAX)
cdecl_func(memcmp)
cdecl_func(mmap)  // NOTE: off_t gets squished by ffi-cdecl...
cdecl_func(munmap)

cdecl_func(ioctl)
//cdecl_func(Sleep) // Win32
cdecl_func(sleep)
cdecl_func(usleep)
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

cdecl_func(fopen)
cdecl_func(fclose)
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
