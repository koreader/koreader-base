PROJECT(fbink)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CROSS_TC)

ep_get_source_dir(SOURCE_DIR)
ep_get_source_dir(BINARY_DIR)

# Minimal, statically linked build, we don't care about extra fonts
set(BUILD_CMD sh -c "$(MAKE) MINIMAL=1 CROSS_TC=\"${CROSS_TC}\" strip")

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
    PATCH_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # The buildsystem outputs binaries in a subdirectory...
    INSTALL_COMMAND ${CMAKE_COMMAND} -E rename ${BINARY_DIR}/Release/fbink ${BINARY_DIR}/fbink
)
