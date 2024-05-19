cmake_minimum_required(VERSION 3.5.1)
project(zstd LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CXX)
assert_var_defined(AR)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

# This a pure Makefile buildsystem, don't enforce CFLAGS via command line args, the buildsystem needs to be able to modify it.
set(BUILD_ENV "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}")

set(BUILD_CMD env ${BUILD_ENV} ${KO_MAKE_RECURSIVE} V=1 "CC=${CC}" "CXX=${CXX}" "AR=${AR}" lib-release)
set(INSTALL_CMD env ${BUILD_ENV} ${KO_MAKE_RECURSIVE} -C lib V=1 "CC=${CC}" "CXX=${CXX}" "AR=${AR}" "prefix=${INSTALL_DIR}" install)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/facebook/zstd.git
    tags/v1.5.5
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_COMMAND COMMAND ${BUILD_CMD}
    INSTALL_COMMAND COMMAND ${INSTALL_CMD}
)
