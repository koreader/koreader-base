#include <sys/mman.h>
#include <stropts.h>
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

#include "ffi-cdecl.h"

cdecl_type(size_t)
cdecl_type(off_t)

cdecl_struct(timeval)
cdecl_struct(statvfs)

cdecl_func(pipe)
cdecl_func(fork)
cdecl_func(dup)
cdecl_func(dup2)

cdecl_const(O_RDWR)
cdecl_const(O_RDONLY)
cdecl_const(O_NONBLOCK)
cdecl_func(open)
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
cdecl_func(mmap)

cdecl_func(ioctl)
cdecl_func(sleep)
cdecl_func(usleep)
cdecl_func(statvfs)
cdecl_func(gettimeofday)
cdecl_func(realpath)
cdecl_func(basename)
cdecl_func(dirname)

cdecl_func(malloc)
cdecl_func(free)

cdecl_func(strdup)
cdecl_func(strndup)

cdecl_func(fopen)
cdecl_func(fclose)
cdecl_func(printf)
cdecl_func(sprintf)
cdecl_func(fprintf)
cdecl_func(fputc)
