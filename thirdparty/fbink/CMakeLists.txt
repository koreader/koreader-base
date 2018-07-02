PROJECT(fbink)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
enable_language(C)

assert_var_defined(CROSS_TC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)

# Minimal, statically linked build, we don't care about extra fonts
set(BUILD_CMD "$(MAKE) strip MINIMAL=1 CROSS_TC=\"${CROSS_TC}\" CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\"")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/NiLuJe/FBInk.git
    v0.9.12
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ""
)
