cmake_minimum_required(VERSION 3.5.1)
project(luasec LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(LD)
assert_var_defined(INC_PATH)
assert_var_defined(LIB_PATH)
assert_var_defined(LUAPATH)

ep_get_source_dir(SOURCE_DIR)

# Don't enforce CFLAGS
list(APPEND PATCH_CMD COMMAND ${ISED} "s|-O2 ||g" src/Makefile)

list(APPEND MAKE_CMD COMMAND ${KO_MAKE_RECURSIVE} "CC=${CC}" "CCLD=${LD}" "AR=${AR}" "RANLIB=${RANLIB}" "INC_PATH=${INC_PATH}" "LIB_PATH=${LIB_PATH}" "LUAPATH=${LUAPATH}" "LUACPATH=${LUAPATH}")
if(DEFINED LIBS)
    list(APPEND MAKE_CMD "LIBS=${LIBS}")
endif()
if (DEFINED ENV{DARWIN})
    set(INSTALL_CMD ${MAKE_CMD} macosx install)
    set(BUILD_CMD ${MAKE_CMD} macosx)
else()
    set(INSTALL_CMD ${MAKE_CMD} linux install)
    set(BUILD_CMD ${MAKE_CMD} linux)
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/brunoos/luasec
    tags/v1.3.2
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
