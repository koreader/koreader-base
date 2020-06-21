local ffi = require("ffi")

ffi.cdef[[
typedef long int off_t;
struct timeval {
  long int tv_sec;
  long int tv_usec;
};
struct statvfs {
  long unsigned int f_bsize;
  long unsigned int f_frsize;
  long unsigned int f_blocks;
  long unsigned int f_bfree;
  long unsigned int f_bavail;
  long unsigned int f_files;
  long unsigned int f_ffree;
  long unsigned int f_favail;
  long unsigned int f_fsid;
  long unsigned int f_flag;
  long unsigned int f_namemax;
  int __f_spare[6];
};
]]
