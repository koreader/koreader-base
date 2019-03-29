local ffi = require("ffi")

-- Handle arch-dependent typedefs...
if ffi.arch == "x64" then
    require("ffi/posix_types_x64_h")
elseif ffi.arch == "x86" then
    require("ffi/posix_types_x86_h")
else
    require("ffi/posix_types_def_h")
end

ffi.cdef[[
int pipe(int *) __attribute__((__nothrow__, __leaf__));
int fork(void) __attribute__((nothrow));
int dup(int) __attribute__((__nothrow__, __leaf__));
int dup2(int, int) __attribute__((__nothrow__, __leaf__));
static const int O_RDWR = 2;
static const int O_RDONLY = 0;
static const int O_NONBLOCK = 2048;
int open(const char *, int, ...);
int close(int);
int fcntl(int, int, ...);
int execl(const char *, const char *, ...) __attribute__((__nothrow__, __leaf__));
int execlp(const char *, const char *, ...) __attribute__((__nothrow__, __leaf__));
int execv(const char *, char *const *) __attribute__((__nothrow__, __leaf__));
int execvp(const char *, char *const *) __attribute__((__nothrow__, __leaf__));
ssize_t write(int, const void *, size_t);
ssize_t read(int, void *, size_t);
int kill(int, int) __attribute__((__nothrow__, __leaf__));
int waitpid(int, int *, int);
int getpid(void) __attribute__((__nothrow__, __leaf__));
int setpgid(int, int) __attribute__((__nothrow__, __leaf__));
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
static const int MAP_FAILED = 4294967295;
static const int PATH_MAX = 4096;
int memcmp(const void *, const void *, size_t) __attribute__((pure, leaf, nothrow));
void *mmap(void *, size_t, int, int, int, long int) __attribute__((__nothrow__, __leaf__));
int munmap(void *, size_t) __attribute__((__nothrow__, __leaf__));
int ioctl(int, long unsigned int, ...) __attribute__((__nothrow__, __leaf__));
void Sleep(int ms);
unsigned int sleep(unsigned int);
int usleep(unsigned int);
int statvfs(const char *restrict, struct statvfs *restrict) __attribute__((__nothrow__, __leaf__));
int gettimeofday(struct timeval *restrict, struct timezone *restrict) __attribute__((__nothrow__, __leaf__));
char *realpath(const char *restrict, char *restrict) __attribute__((__nothrow__, __leaf__));
char *basename(char *) __attribute__((__nothrow__, __leaf__));
char *dirname(char *) __attribute__((__nothrow__, __leaf__));
void *malloc(size_t) __attribute__((malloc, leaf, nothrow));
void free(void *) __attribute__((leaf, nothrow));
void *memset(void *, int, size_t) __attribute__((leaf, nothrow));
char *strdup(const char *) __attribute__((malloc, leaf, nothrow));
char *strndup(const char *, size_t) __attribute__((malloc, leaf, nothrow));
struct _IO_FILE *fopen(const char *restrict, const char *restrict);
int fclose(struct _IO_FILE *);
int printf(const char *, ...);
int sprintf(char *, const char *, ...) __attribute__((nothrow));
int fprintf(struct _IO_FILE *restrict, const char *restrict, ...);
int fputc(int, struct _IO_FILE *);
static const int FIONREAD = 21531;
int fileno(struct _IO_FILE *) __attribute__((__nothrow__, __leaf__));
char *strerror(int) __attribute__((__nothrow__, __leaf__));
int setenv(const char *, const char *, int) __attribute__((__nothrow__, __leaf__));
int unsetenv(const char *) __attribute__((__nothrow__, __leaf__));
int _putenv(const char *);
]]
