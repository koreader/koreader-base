cmake_minimum_required(VERSION 3.5.1)
project(popen-noshell LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

# Make it build on recent TCs, and implement a
# simple Makefile for building it as a static lib.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/popen_noshell.patch)

if(LEGACY)
    # Revert 8d7a98d on legacy devices, pipe2 was introduced in Linux 2.6.27 & glibc 2.9
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/kindle_legacy.patch)
endif()

if(ANDROID)
    set(CFLAGS "${CFLAGS} --sysroot=$ENV{SYSROOT}")
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})
append_autotools_vars(BUILD_CMD)

# NOTE: we always update lib timestamp to notify Make for a fresh build
list(APPEND BUILD_CMD COMMAND ${CMAKE_COMMAND} -E touch ${SOURCE_DIR}/libpopen_noshell.a)

# NOTE: As of right now (1f9eaf4eeef348d1efe0f3c7fe8ab670653cfbb1), wait until stuff settles down before bumping this.
ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/famzah/popen-noshell.git
    e715396a4951ee91c40a98d2824a130f158268bb
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
