PROJECT(giflib)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# NOTE: reallocarray is in libbsd since glibc 2.26, so, don't even try to test for it, always use the bundled copy.
set(BUILD_CMD sh -c "$(MAKE) -j${PARALLEL_JOBS} CC=\"${CC}\" CFLAGS=\"${CFLAGS} -std=gnu99 -fPIC -Wall -Wno-format-truncation\" LDFLAGS=\"${LDFLAGS}\" --silent")

# use limits.h instead of stdint.h for android build
if($ENV{ANDROID})
    set(PATCH_CMD sh -c "${ISED} \"s|stdint.h|limits.h|g\" ${SOURCE_DIR}/lib/openbsd-reallocarray.c")
else()
    set(PATCH_CMD sh -c "true")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://gitlab.com/koreader/giflib.git
    5.1.6
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND $(MAKE) -j${PARALLEL_JOBS} --silent install PREFIX=${BINARY_DIR}
)
