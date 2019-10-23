project(zsync)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(HOST)
assert_var_defined(LIBS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(RECONF_CMD sh -c "cd c && autoreconf -fi")
set(CFG_OPTS "-q --prefix=${BINARY_DIR} --host=\"${HOST}\"")
set(CFG_CMD sh -c "CC=\"${CC}\" CFLAGS=\"${CFLAGS} -I${SOURCE_DIR}/c\" LDFLAGS=\"${LDFLAGS}\" LIBS=\"${LIBS}\" ${SOURCE_DIR}/c/configure ${CFG_OPTS}")
# Pickup some build fixes from https://github.com/ahmedammar/zsync
# Plus, abort if we hit an OpenStack container to avoid infinite loops
set(PATCH_CMD1 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zsync-openstack-abort.patch")
# don't check missing definition of in_port_t in NDK <netinet/in.h>
set(PATCH_CMD2 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zsync-android-build-p1.patch")
# fix "rename: Invalid cross-device link" error for Android
set(PATCH_CMD3 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zsync-android-build-p2.patch")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://gitlab.com/koreader/zsync.git
    6cfe374f8f2310cbd624664ca98e5bb28244ba7a
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD1} COMMAND ${PATCH_CMD2} COMMAND ${PATCH_CMD3} COMMAND ${RECONF_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    # skip install
    INSTALL_COMMAND ""
)
