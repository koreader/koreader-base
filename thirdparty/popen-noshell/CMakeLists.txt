project(popen-noshell LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

# Make it build on recent TCs, and implement a
# simple Makefile for building it as a static lib
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

# Install static lib.
append_static_lib_install_command(INSTALL_CMD "${SOURCE_DIR}/libpopen_noshell.a" popen_noshell)

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    "${SOURCE_DIR}/popen_noshell.h"
)

# NOTE: As of right now (1f9eaf4eeef348d1efe0f3c7fe8ab670653cfbb1), wait until stuff settles down before bumping this.
ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/famzah/popen-noshell.git
    e715396a4951ee91c40a98d2824a130f158268bb
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    INSTALL_BYPRODUCTS "${STAGING_DIR}/${PROJECT_NAME}/static/libpopen_noshell.a"
)
