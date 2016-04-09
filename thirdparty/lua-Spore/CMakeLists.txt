PROJECT(lua-Spore)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LD)
assert_var_defined(LUA_INCDIR)
assert_var_defined(LUA_LIBDIR)
assert_var_defined(LUA_SPORE_VER)
assert_var_defined(OUTPUT_DIR)

ep_get_source_dir(SOURCE_DIR)

set(LUA_SPORE_ROCKSPEC rockspec/${LUA_SPORE_VER}.rockspec)

set(BUILD_CMD_STR "luarocks make --tree=${OUTPUT_DIR}/rocks ${LUA_SPORE_ROCKSPEC}")
if(DEFINED LDFLAGS)
    set(BUILD_CMD_STR "${BUILD_CMD_STR} LDFLAGS=\"${LDFLAGS}\"")
endif()
set(BUILD_CMD_STR "${BUILD_CMD_STR} CC=\"${CC}\" CFLAGS=\"${CFLAGS}\" LD=\"${LD}\"")
set(BUILD_CMD_STR "${BUILD_CMD_STR} LUA_INCDIR=\"${LUA_INCDIR}\" LUA_LIBDIR=\"${LUA_LIBDIR}\"")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/fperrad/lua-Spore
    8e96c4adc6e900e259aea400ce8e5fe8f6158d59
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND sh -c "mkdir -p doc && sed -i \"s| 'luasocket|--'luasocket|g\" ${LUA_SPORE_ROCKSPEC}"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND sh -c ${BUILD_CMD_STR}
    # skip install
    INSTALL_COMMAND ""
)
