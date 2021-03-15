local ffi = require("ffi")

-- clock_gettime & friends require librt on old glibc versions...
if ffi.os == "Linux" then
   pcall(ffi.load, "rt")
end

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
int waitpid(int, int *, int);
int getpid(void) __attribute__((nothrow, leaf));
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
static const int MAP_FAILED = -1;
static const int PATH_MAX = 4096;
int memcmp(const void *, const void *, size_t) __attribute__((pure, leaf, nothrow));
void *mmap(void *, size_t, int, int, int, off_t) __attribute__((nothrow, leaf));
int munmap(void *, size_t) __attribute__((nothrow, leaf));
int ioctl(int, long unsigned int, ...) __attribute__((nothrow, leaf));
void Sleep(int ms);
unsigned int sleep(unsigned int);
int usleep(unsigned int);
int statvfs(const char *restrict, struct statvfs *restrict) __attribute__((nothrow, leaf));
int gettimeofday(struct timeval *restrict, struct timezone *restrict) __attribute__((nothrow, leaf));
char *realpath(const char *restrict, char *restrict) __attribute__((nothrow, leaf));
char *basename(char *) __attribute__((nothrow, leaf));
char *dirname(char *) __attribute__((nothrow, leaf));
typedef int clockid_t;
static const int CLOCK_REALTIME = 0;
static const int CLOCK_REALTIME_COARSE = 5;
static const int CLOCK_MONOTONIC = 1;
static const int CLOCK_MONOTONIC_COARSE = 6;
static const int CLOCK_MONOTONIC_RAW = 4;
static const int CLOCK_BOOTTIME = 7;
int clock_gettime(clockid_t, struct timespec *) __attribute__((nothrow, leaf));
int clock_settime(clockid_t, const struct timespec *) __attribute__((nothrow, leaf));
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
struct _IO_FILE *fopen(const char *restrict, const char *restrict);
int fclose(struct _IO_FILE *);
int printf(const char *, ...);
int sprintf(char *, const char *, ...) __attribute__((nothrow));
int fprintf(struct _IO_FILE *restrict, const char *restrict, ...);
int fputc(int, struct _IO_FILE *);
static const int FIONREAD = 21531;
int fileno(struct _IO_FILE *) __attribute__((nothrow, leaf));
char *strerror(int) __attribute__((nothrow, leaf));
int fsync(int);
int fdatasync(int);
int setenv(const char *, const char *, int) __attribute__((nothrow, leaf));
int unsetenv(const char *) __attribute__((nothrow, leaf));
int _putenv(const char *);
]]
