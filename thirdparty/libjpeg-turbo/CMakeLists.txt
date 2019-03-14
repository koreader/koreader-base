PROJECT(libjpeg-turbo)
cmake_minimum_required(VERSION 3.5.1)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CHOST)
assert_var_defined(CMAKE_C_COMPILER)
assert_var_defined(CMAKE_C_COMPILER_LAUNCHER)
assert_var_defined(CMAKE_C_COMPILER_ARG1)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(STRIP)
assert_var_defined(AR)
assert_var_defined(RANLIB)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# CMake hell.
set(CMAKE_INSTALL_DEFAULT_PREFIX "${BINARY_DIR}")
set(CMAKE_INSTALL_PREFIX "${BINARY_DIR}")
# We expect lib later on in Makefile.third, even on multilib systems...
set(CMAKE_INSTALL_LIBDIR "${BINARY_DIR}/lib")
set(CMAKE_SKIP_BUILD_RPATH True)

# To make CMake 3.5 behave better (not necessary on 3.13)
set(PATCH_CMD "${ISED} 's|set(CMAKE_INSTALL_DEFAULT_PREFIX /opt/\${CMAKE_PROJECT_NAME})||' ${SOURCE_DIR}/CMakeLists.txt")
set(PATCH_CMD "sh -c \"${PATCH_CMD}\"")

# Compiler and linker flags
set(CMAKE_C_FLAGS "${CFLAGS}")
set(CMAKE_EXE_LINKER_FLAGS "${LDFLAGS}")

# c.f., http://trac.ak-team.com/trac/browser/niluje/Configs/trunk/Kindle/Misc/CMakeCross.txt
if((DEFINED ENV{CERVANTES}) OR (DEFINED ENV{DEBIAN_CROSS}) OR (DEFINED ENV{KINDLE}) OR (DEFINED ENV{KOBO}) OR (DEFINED ENV{LEGACY}) OR (DEFINED ENV{POCKETBOOK}) OR (DEFINED ENV{SONY_PRSTUX}) OR (DEFINED ENV{UBUNTUTOUCH}))
    set(CMAKE_SYSTEM_NAME Linux)
endif((DEFINED ENV{CERVANTES}) OR (DEFINED ENV{DEBIAN_CROSS}) OR (DEFINED ENV{KINDLE}) OR (DEFINED ENV{KOBO}) OR (DEFINED ENV{LEGACY}) OR (DEFINED ENV{POCKETBOOK}) OR (DEFINED ENV{SONY_PRSTUX}) OR (DEFINED ENV{UBUNTUTOUCH}))

# c.f., https://android.googlesource.com/platform/ndk/+/master/build/cmake/android.toolchain.cmake
# and   https://github.com/taka-no-me/android-cmake
# In the meantime, I'll be sitting in the corner, crying hysterically.
if(DEFINED ENV{ANDROID})
    set(CMAKE_SYSTEM_NAME Linux)
    # Magical value that inhibits all of CMake's own NDK handling code. (Or shit goes boom.)
    set(CMAKE_SYSTEM_VERSION 1)

    # x86 Android, because we can't set CMAKE_SYSTEM_NAME without setting CMAKE_SYSTEM_PROCESSOR too...
    if(${CHOST} MATCHES "^i686-.*")
        set(CMAKE_SYSTEM_PROCESSOR i686)
    endif(${CHOST} MATCHES "^i686-.*")

    # Handle AArch64 NDKs while we're here...
    if(${CHOST} MATCHES "^aarch64-.*")
        set(CMAKE_SYSTEM_PROCESSOR aarch64)
    endif(${CHOST} MATCHES "^aarch64-.*")

    # And x86_64 too, because why the hell stop there.
    if(${CHOST} MATCHES "^x86_64-.*")
        set(CMAKE_SYSTEM_PROCESSOR x86_64)
    endif(${CHOST} MATCHES "^x86_64-.*")
endif(DEFINED ENV{ANDROID})

# Needed so that libjpeg-turbo tries to build the right set of SIMD routines for the target when cross-compiling...
# NOTE: When CMAKE_SYSTEM_PROCESSOR is set, CMAKE_SYSTEM_NAME MUST be too (or vice versa).
#       Failure to do so is a sure recipe for disaster in weird and interesting ways...
if(${CHOST} MATCHES "^arm-.*")
    set(CMAKE_SYSTEM_PROCESSOR arm)
endif(${CHOST} MATCHES "^arm-.*")

# set various other toolchain tools
set(CMAKE_STRIP "${STRIP}")
set(CMAKE_AR "${AR}")
set(CMAKE_RANLIB "${RANLIB}")

# And, finally, the actual libjpeg-turbo build options
set(ENABLE_STATIC False CACHE BOOL "")
set(ENABLE_SHARED True CACHE BOOL "")
set(WITH_JAVA False CACHE BOOL "")
set(WITH_JPEG8 True CACHE BOOL "")

# make sure we disable ASM if we don't support SIMD
if(NOT DEFINED ENV{WANT_SIMD})
    set(REQUIRE_SIMD False CACHE BOOL "")
    set(WITH_SIMD False CACHE BOOL "")
endif(NOT DEFINED ENV{WANT_SIMD})

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/libjpeg-turbo/libjpeg-turbo.git
    2.0.2
    ${SOURCE_DIR}
)

include(DownloadProject)
download_project(
    PROJ ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_CMD COMMAND ${PATCH_CMD}
)

add_subdirectory(${SOURCE_DIR})
