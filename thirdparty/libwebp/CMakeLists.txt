project(libwebp)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_ENV_VAR "PKG_CONFIG=/bin/false CCC=\"${CC}\" CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\"")
set(CFG_OPTS "-q --prefix=${BINARY_DIR} --disable-static --enable-shared --disable-neon --host=\"${CHOST}\"")

set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")


ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/webmproject/libwebp
    v1.1.0
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    BUILD_IN_SOURCE 1
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND sh -c "${ISED} \"s|\\$srcdir\\/configure \\$\\*||g\" autogen.sh" COMMAND ./autogen.sh
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} install
)
