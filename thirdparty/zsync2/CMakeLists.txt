project(zsync2)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CPPFLAGS)
assert_var_defined(CFLAGS)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(CURL_DIR)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# Make sure the daisy-chain once again picks up our toolchain file...
if(DEFINED ENV{CMAKE_TCF})
	list(APPEND CMAKE_ARGS "$ENV{CMAKE_TCF}")
endif()

# CMake hell.
# We expect lib later on in Makefile.third, even on multilib systems...
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${BINARY_DIR}")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_LIBDIR=lib")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_INCLUDEDIR=include")
list(APPEND CMAKE_ARGS "-DCMAKE_SKIP_BUILD_RPATH:BOOL=True")
#list(APPEND CMAKE_ARGS "-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON")

# Honor the env, dammit.
list(APPEND CMAKE_ARGS "-DCMAKE_EXE_LINKER_FLAGS=${LDFLAGS}")
list(APPEND CMAKE_ARGS "-DCMAKE_MODULE_LINKER_FLAGS=${LDFLAGS}")
list(APPEND CMAKE_ARGS "-DCMAKE_SHARED_LINKER_FLAGS=${LDFLAGS}")
list(APPEND CMAKE_ARGS "-DCMAKE_C_FLAGS=${CPPFLAGS} ${CFLAGS}")
list(APPEND CMAKE_ARGS "-DCMAKE_CXX_FLAGS=${CPPFLAGS} ${CXXFLAGS}")

# And, finally, the actual zsync2 build options
list(APPEND CMAKE_ARGS "-DBUILD_CPR_TESTS=0")
list(APPEND CMAKE_ARGS "-DUSE_SYSTEM_CURL=1")
list(APPEND CMAKE_ARGS "-DCURL_INCLUDE_DIR=${CURL_DIR}/include")
list(APPEND CMAKE_ARGS "-DCURL_LIBRARY=curl")
# And because CMake is being stupid on the bots...
#list(APPEND CMAKE_ARGS "-DCURL_FOUND=1")
list(APPEND CMAKE_ARGS "-DCURL_LIBRARIES=curl")
#list(APPEND CMAKE_ARGS "-DCURL_INCLUDE_DIRS=${CURL_DIR}/include")

# NOTE: We're currently using our own fork instead of upstream's (https://github.com/AppImage/zsync2):
## * Enable range requests optimizations on the CLI
## * Re-implement the -u flag for compatibility w/ the old zsync CLI
## * Minor CLI output cleanup
## * Squish all the warnings
## * Prevent passing a malformed referer URL
## * Don't print seven billion progress bars
## * Rebase against zsync master (c.f., rebase-zsync-libs branch)
## * Rebase against zlib 1.2.11 (c.f., rebase-zlib branch)
## * Workaround potential download loops, like what happened w/ the 2019.12 -> 2020.01 update.
## * Mangle logging to play nice w/ FBInk
## * Plug memory leaks
# c.f., https://github.com/NiLuJe/zsync2 for more details.

# Workaround various issues related to PocketBook's old TC using an awfully old GCC version
# Inspired by https://github.com/nlohmann/json/issues/136
if(DEFINED ENV{POCKETBOOK})
    set(PATCH_CMD "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zsync2-pocketbook-old-gcc.diff")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/NiLuJe/zsync2.git
    7565c081d581706c6a7859cf41eec976811180b6
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    zsync2
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD}
    CMAKE_ARGS "${CMAKE_ARGS}"
    CMAKE_GENERATOR "Unix Makefiles"
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} install
)
