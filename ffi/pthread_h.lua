local ffi = require("ffi")

--[[--
The declarations of `pthread_attr_t` and `PTHREAD_CREATE_DETACHED` depend on the arch / OS:

| Target machine                  | `sizeof (pthread_attr_t)` | `PTHREAD_CREATE_DETACHED` |
|---------------------------------|--------------------------:|--------------------------:|
| aarch64-linux-gnu-g++           |                        64 |                         1 |
| aarch64-unknown-linux-android21 |                        56 |                         1 |
| arm-kindlepw2-linux-gnueabi     |                        36 |                         1 |
| arm-linux-gnueabihf             |                        36 |                         1 |
| arm64-apple-darwin23.6.0        |                        64 |                         2 |
| armv7a-unknown-linux-android18  |                        24 |                         1 |
| i386-pc-linux-gnu               |                        36 |                         1 |
| i686-unknown-linux-android18    |                        24 |                         1 |
| x86_64-apple-darwin22.6.0       |                        64 |                         2 |
| x86_64-pc-linux-gnu             |                        56 |                         1 |

The following C++ compiler command can be used to print those values:

```bash
▸ g++ -x c++ -c -o /dev/null - <<\EOF
#include <pthread.h>
template <int val> struct PrintConst;
PrintConst<sizeof (pthread_attr_t)> sizeof_pthread_attr_t;
PrintConst<PTHREAD_CREATE_DETACHED> valueof_PTHREAD_CREATE_DETACHED;
EOF
<stdin>:3:37: error: aggregate ‘PrintConst<56> sizeof_pthread_attr_t’ has incomplete type and cannot be defined
<stdin>:4:37: error: aggregate ‘PrintConst<1> valueof_PTHREAD_CREATE_DETACHED’ has incomplete type and cannot be defined
```
--]]
local sizeof_pthread_attr_t
local valueof_PTHREAD_CREATE_DETACHED
if ffi.os == "OSX" then
    sizeof_pthread_attr_t = 64
    valueof_PTHREAD_CREATE_DETACHED = 2
elseif ffi.os == "Linux" then
    if os.getenv("IS_ANDROID") then
        sizeof_pthread_attr_t = ffi.abi("32bit") and 24 or 56
    elseif ffi.arch == "arm" or ffi.arch == "x86" then
        sizeof_pthread_attr_t = 36
    elseif ffi.arch == "x64" then
        sizeof_pthread_attr_t = 56
    elseif ffi.arch == "arm64" or ffi.arch == "arm64be" then
        sizeof_pthread_attr_t = 64
    end
    valueof_PTHREAD_CREATE_DETACHED = 1
end

if not sizeof_pthread_attr_t or not valueof_PTHREAD_CREATE_DETACHED then
    error("unsupported arch / OS")
end

ffi.cdef(string.format(
    [[
    typedef union {
        char __size[%u];
        long int __align;
    } pthread_attr_t;
    typedef long unsigned int pthread_t;
    static const int PTHREAD_CREATE_DETACHED = %u;
    int pthread_attr_init(pthread_attr_t *);
    int pthread_attr_setdetachstate(pthread_attr_t *, int);
    int pthread_attr_destroy(pthread_attr_t *);
    int pthread_create(pthread_t *restrict, const pthread_attr_t *restrict, void *(*)(void *), void *restrict);
    ]]
    , sizeof_pthread_attr_t, valueof_PTHREAD_CREATE_DETACHED
))
