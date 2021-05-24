project(lua-serialize)
cmake_minimum_required(VERSION 3.10.2)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(LDFLAGS)
assert_var_defined(OUTPUT_DIR)

ep_get_source_dir(SOURCE_DIR)

set(PATCH_CMD "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/lua-serialize-lto.patch")

set(BUILD_CMD sh -c "${KO_MAKE_RECURSIVE} -j1 CC=\"${CC}\" LDFLAGS=\"${LDFLAGS}\" OUTPUT_DIR=\"${OUTPUT_DIR}\"")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/lua-serialize
    decd0f171cb61f3919d2441a3f0d9b3174b951e2
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD}
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
