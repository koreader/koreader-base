project(popen-noshell)
cmake_minimum_required(VERSION 3.10.2)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_asm")
include("koreader_thirdparty_git")

enable_language(C CXX ASM)

ep_get_source_dir(SOURCE_DIR)

if(${LEGACY})
    # Revert 8d7a98d on legacy devices, pipe2 was introduced in Linux 2.6.27 & glibc 2.9
    set(EXTRA_PATCH_CMD "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/kindle_legacy.patch")
endif()

assert_var_defined(CC)
assert_var_defined(AR)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

set(MAKE_ENV_VAR "CC=\"${CC}\" AR=\"${AR}\" CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\"")
set(BUILD_CMD sh -c "${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} ${MAKE_ENV_VAR}")

# NOTE: As of right now (1f9eaf4eeef348d1efe0f3c7fe8ab670653cfbb1), wait until stuff settles down before bumping this.
ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/famzah/popen-noshell.git
    e715396a4951ee91c40a98d2824a130f158268bb
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    popen-noshell
    BUILD_IN_SOURCE 1
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    # popen_noshell patch: Make it build on recent TCs, and implement
    # a simple Makefile for building it as a static lib
    PATCH_COMMAND COMMAND "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/popen_noshell.patch" COMMAND ${EXTRA_PATCH_CMD}
    # skip configure
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    # NOTE: we always update lib timestamp to notify Make for a fresh build
    INSTALL_COMMAND ${CMAKE_COMMAND} -E touch ${SOURCE_DIR}/libpopen_noshell.a
)
