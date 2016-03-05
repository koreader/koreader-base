PROJECT(zsync)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(HOST)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_OPTS "-q --prefix=${BINARY_DIR} --host=\"${HOST}\"")
set(CFG_CMD_STR "CC=\"${CC}\" CFLAGS=\"$(CFLAGS) -I${SOURCE_DIR}/c\" ${SOURCE_DIR}/c/configure ${CFG_OPTS}")
# fix missing in_port_t in NDK <netinet/in.h>
set(PATCH_CMD sh -c "patch -N -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/zsync.patch || true")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://gitlab.com/koreader/zsync.git
    b89a03f304f9761fe4029fff8f33db6cb12ae002
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND sh -c "cd c && autoreconf -fi" COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND sh -c ${CFG_CMD_STR}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS} --silent
    # skip install
    INSTALL_COMMAND ""
)
