cmake_minimum_required(VERSION 3.5.1)
project(luasec LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(LD)
assert_var_defined(INC_PATH)
assert_var_defined(LIB_PATH)
assert_var_defined(LUAPATH)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

# Don't enforce CFLAGS
list(APPEND PATCH_CMD COMMAND ${ISED} "s|-O2 ||g" src/Makefile)

list(APPEND MAKE_CMD COMMAND ${KO_MAKE_RECURSIVE} "CC=${CC}" "CCLD=${LD}" "AR=${AR}" "RANLIB=${RANLIB}" "INC_PATH=${INC_PATH}" "LIB_PATH=${LIB_PATH}" "LUAPATH=${LUAPATH}" "LUACPATH=${LUAPATH}")
if(DEFINED LIBS)
    list(APPEND MAKE_CMD "LIBS=${LIBS}")
endif()
if (DARWIN)
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

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
