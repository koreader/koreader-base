PROJECT(fbink)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CROSS_TC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# Minimal, statically linked build, we don't care about extra fonts
set(BUILD_CMD sh -c "$(MAKE) MINIMAL=1 CROSS_TC=\"${CROSS_TC}\" CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\" strip")
# We build in-tree...
set(INSTALL_CMD1 ${CMAKE_COMMAND} -E make_directory ${BINARY_DIR})
if($ENV{DEBUG})
    set(INSTALL_CMD2 ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/Debug/fbink ${BINARY_DIR}/fbink)
else()
    set(INSTALL_CMD2 ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/Release/fbink ${BINARY_DIR}/fbink)
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/NiLuJe/FBInk.git
    v1.2.5
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
    # The buildsystem outputs binaries in a subdirectory...
    INSTALL_COMMAND COMMAND ${INSTALL_CMD1} COMMAND ${INSTALL_CMD2}
)
