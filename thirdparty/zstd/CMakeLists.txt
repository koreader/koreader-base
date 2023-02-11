project(zstd)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CXX)
assert_var_defined(AR)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# Because escaping rpath is even more hellish than usual, for some reason...
# NOTE: In ZSH, passing MOREFLAGS="-Wl,-rpath,'\\\$$\\\$\$ORIGIN/./libs'" works, too.
set(PATCH_CMD "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zstd-rpath.patch")

# This a pure Makefile buildsystem, don't enforce CFLAGS via command line args, the buildsystem needs to be able to modify it.
set(BUILD_ENV "env CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\"")

set(BUILD_CMD sh -c "${BUILD_ENV} ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} V=1 CC=\"${CC}\" CXX=\"${CXX}\" AR=\"${AR}\" lib-release")
set(INSTALL_CMD sh -c "${BUILD_ENV} ${KO_MAKE_RECURSIVE} -C lib -j${PARALLEL_JOBS} V=1 CC=\"${CC}\" CXX=\"${CXX}\" AR=\"${AR}\" prefix=\"${BINARY_DIR}\" install")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/facebook/zstd.git
    tags/v1.5.4
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND COMMAND ${BUILD_CMD}
    INSTALL_COMMAND COMMAND ${INSTALL_CMD}
)
