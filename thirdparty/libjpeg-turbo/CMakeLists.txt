project(libjpeg-turbo)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CHOST)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(STRIP)
assert_var_defined(AR)
assert_var_defined(RANLIB)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# CMake hell.
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=\"${BINARY_DIR}\"")
# We expect lib later on in Makefile.third, even on multilib systems...
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_LIBDIR=\"${BINARY_DIR}/lib\"")
list(APPEND CMAKE_ARGS "-DCMAKE_SKIP_BUILD_RPATH:BOOL=True")

# c.f., https://android.googlesource.com/platform/ndk/+/master/build/cmake/android.toolchain.cmake
# and   https://github.com/taka-no-me/android-cmake
# In the meantime, I'll be sitting in the corner, crying hysterically.
if(DEFINED ENV{ANDROID})
	list(APPEND CMAKE_ARGS "-DCMAKE_SYSTEM_NAME=\"Linux\"")
	# Magical value that inhibits all of CMake's own NDK handling code. (Or shit goes boom.)
	list(APPEND CMAKE_ARGS "-DCMAKE_SYSTEM_VERSION=1")
endif()

# And, finally, the actual libjpeg-turbo build options
list(APPEND CMAKE_ARGS "-DENABLE_STATIC=OFF")
list(APPEND CMAKE_ARGS "-DENABLE_SHARED=ON")
list(APPEND CMAKE_ARGS "-DWITH_JAVA=OFF")
list(APPEND CMAKE_ARGS "-DWITH_JPEG8=ON")

# make sure we disable ASM if we don't support SIMD
if(NOT DEFINED ENV{WANT_SIMD})
    list(APPEND CMAKE_ARGS "-DREQUIRE_SIMD=OFF")
    list(APPEND CMAKE_ARGS "-DWITH_SIMD=OFF")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/libjpeg-turbo/libjpeg-turbo.git
    2.0.2
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    libjpeg-turbo
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ""
    CMAKE_ARGS "${CMAKE_ARGS}"
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} install
)
