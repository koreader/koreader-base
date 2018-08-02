PROJECT(libjpeg-turbo)
cmake_minimum_required(VERSION 2.8.3)

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
set(CFG_OPTS "-DCMAKE_INSTALL_PREFIX='${BINARY_DIR}'")
set(CFG_OPTS "${CFG_OPTS} -DCMAKE_SKIP_BUILD_RPATH:BOOL=True")

# Compiler and linker flags
set(CFG_OPTS "${CFG_OPTS} -DCMAKE_C_COMPILER='${CMAKE_C_COMPILER}' -DCMAKE_C_COMPILER_LAUNCHER='${CMAKE_C_COMPILER_LAUNCHER}' -DCMAKE_C_COMPILER_ARG1='${CMAKE_C_COMPILER_ARG1}' -DCMAKE_C_FLAGS='${CFLAGS}'")
set(CFG_OPTS "${CFG_OPTS} -DCMAKE_EXE_LINKER_FLAGS='${LDFLAGS}'")

# c.f., http://trac.ak-team.com/trac/browser/niluje/Configs/trunk/Kindle/Misc/CMakeCross.txt
if(($ENV{KINDLE}) OR ($ENV{LEGACY}) OR ($ENV{KOBO}) OR ($ENV{POCKETBOOK}))
	set(CFG_OPTS "${CFG_OPTS} -DCMAKE_SYSTEM_NAME='Linux'")
endif(($ENV{KINDLE}) OR ($ENV{LEGACY}) OR ($ENV{KOBO}) OR ($ENV{POCKETBOOK}))

# c.f., https://android.googlesource.com/platform/ndk/+/master/build/cmake/android.toolchain.cmake
# and   https://github.com/taka-no-me/android-cmake
# In the meantime, I'll be sitting in the corner, crying hysterically.
if($ENV{ANDROID})
	set(CFG_OPTS "${CFG_OPTS} -DCMAKE_SYSTEM_NAME='Android'")
	# Magical value that inhibits all of CMake's own NDK handling code. (Or shit goes boom.)
	set(CFG_OPTS "${CFG_OPTS} -DCMAKE_SYSTEM_VERSION=1")

	# x86 Android, because we can't set CMAKE_SYSTEM_NAME without setting CMAKE_SYSTEM_PROCESSOR too...
	if(${CHOST} MATCHES "^i686-.*")
		set(CFG_OPTS "${CFG_OPTS} -DCMAKE_SYSTEM_PROCESSOR='i686'")
	endif(${CHOST} MATCHES "^i686-.*")

	# Handle AArch64 NDKs while we're here...
	if(${CHOST} MATCHES "^aarch64-.*")
		set(CFG_OPTS "${CFG_OPTS} -DCMAKE_SYSTEM_PROCESSOR='aarch64'")
	endif(${CHOST} MATCHES "^aarch64-.*")

	# And x86_64 too, because why the hell stop there.
	if(${CHOST} MATCHES "^x86_64-.*")
		set(CFG_OPTS "${CFG_OPTS} -DCMAKE_SYSTEM_PROCESSOR='x86_64'")
	endif(${CHOST} MATCHES "^x86_64-.*")
endif($ENV{ANDROID})

# Needed so that libjpeg-turbo tries to build the right set of SIMD routines for the target when cross-compiling...
# NOTE: When CMAKE_SYSTEM_PROCESSOR is set, CMAKE_SYSTEM_NAME MUST be too (or vice versa).
#       Failure to do so is a sure recipe for disaster in weird and interesting ways...
if(${CHOST} MATCHES "^arm-.*")
	set(CFG_OPTS "${CFG_OPTS} -DCMAKE_SYSTEM_PROCESSOR='arm'")
endif(${CHOST} MATCHES "^arm-.*")

# set various other toolchain tools
set(CFG_OPTS "${CFG_OPTS} -DCMAKE_STRIP='${STRIP}'")
set(CFG_OPTS "${CFG_OPTS} -DCMAKE_AR='${AR}'")
set(CFG_OPTS "${CFG_OPTS} -DCMAKE_RANLIB='${RANLIB}'")

# And, finally, the actual libjpeg-turbo build options
set(CFG_OPTS "${CFG_OPTS} -DENABLE_STATIC=OFF -DENABLE_SHARED=ON -DWITH_JAVA=OFF -DWITH_JPEG8=ON")
if(${WITHOUT_SIMD})
    set(CFG_OPTS "${CFG_OPTS} -DREQUIRE_SIMD=OFF -DWITH_SIMD=OFF")
endif(${WITHOUT_SIMD})

set(CFG_CMD sh -c "${CMAKE_COMMAND} ${CFG_OPTS}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/libjpeg-turbo/libjpeg-turbo.git
    2.0.0
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    libjpeg-turbo
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ""
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS}
    INSTALL_COMMAND $(MAKE) -j${PARALLEL_JOBS} install
)
