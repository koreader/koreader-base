PROJECT(libjpeg-turbo)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

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
if((NOT DEFINED $ENV{ANDROID}) AND (NOT DEFINED $ENV{DARWIN}) AND (NOT DEFINED $ENV{WIN32}) AND (NOT DEFINED $ENV{SDL}))
	set(CFG_OPTS "${CFG_OPTS} -DCMAKE_SYSTEM_NAME=Linux")
endif()
if("${CHOST}" MATCHES "^arm-.*")
	set(CFG_OPTS "${CFG_OPTS} -DCMAKE_SYSTEM_PROCESSOR=arm")
endif()

# Follow sdcv's lead
if(DEFINED $ENV{ANDROID})
	set(CFG_OPTS "${CFG_OPTS} -DCMAKE_SYSTEM_NAME=Android -DCMAKE_SYSTEM_VERSION=1")
endif()

# set various other toolchain tools
set(CFG_OPTS "${CFG_OPTS} -DCMAKE_STRIP='${STRIP}'")
set(CFG_OPTS "${CFG_OPTS} -DCMAKE_AR='${AR}'")
set(CFG_OPTS "${CFG_OPTS} -DCMAKE_RANLIB='${RANLIB}'")

# And, finally, the actual libjpeg-turbo build options
set(CFG_OPTS "${CFG_OPTS} -DENABLE_STATIC=OFF -DENABLE_SHARED=ON -DWITH_JAVA=OFF -DWITH_JPEG8=ON")
if(DEFINED ${WITHOUT_SIMD})
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
