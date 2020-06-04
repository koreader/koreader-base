project(lua-htmlparser)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LD)
assert_var_defined(LUA_INCDIR)
assert_var_defined(LUA_LIBDIR)
assert_var_defined(LUA_HTMLPARSER_VER)
assert_var_defined(OUTPUT_DIR)
assert_var_defined(LUAROCKS)

ep_get_source_dir(SOURCE_DIR)

set(LUA_HTMLPARSER_ROCKSPEC rockspec/htmlparser-${LUA_HTMLPARSER_VER}.rockspec)

set(BUILD_CMD sh -c "${LUAROCKS} make --tree=${OUTPUT_DIR}/rocks ${LUA_HTMLPARSER_ROCKSPEC}")
if(DEFINED LIBFLAG)
    set(BUILD_CMD "${BUILD_CMD} LIBFLAG=\"${LIBFLAG}\"")
endif()
set(BUILD_CMD "${BUILD_CMD} CC=\"${CC}\" CFLAGS=\"${CFLAGS}\" LD=\"${LD}\"")
set(BUILD_CMD "${BUILD_CMD} LUA_INCDIR=\"${LUA_INCDIR}\" LUA_LIBDIR=\"${LUA_LIBDIR}\"")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/msva/lua-htmlparser
    4f6437ebd123c3e552a595fc818fdd952888fff2
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
