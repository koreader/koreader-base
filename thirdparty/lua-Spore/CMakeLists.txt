project(lua-Spore)
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
assert_var_defined(LUA_SPORE_VER)
assert_var_defined(OUTPUT_DIR)
assert_var_defined(LUAROCKS)

ep_get_source_dir(SOURCE_DIR)

set(LUA_SPORE_ROCKSPEC rockspec/${LUA_SPORE_VER}.rockspec)

set(BUILD_CMD "${LUAROCKS} make --tree=${OUTPUT_DIR}/rocks ${LUA_SPORE_ROCKSPEC}")
if(DEFINED LIBFLAG)
    set(BUILD_CMD "${BUILD_CMD} LIBFLAG=\"${LIBFLAG}\"")
endif()
set(BUILD_CMD "${BUILD_CMD} CC=\"${CC}\" CFLAGS=\"${CFLAGS}\" LD=\"${LD}\"")
set(BUILD_CMD "${BUILD_CMD} LUA_INCDIR=\"${LUA_INCDIR}\" LUA_LIBDIR=\"${LUA_LIBDIR}\"")

set(PATCH_CMD sh -c "mkdir -p doc && ${ISED} \"s| 'luasocket|--'luasocket|g\" ${LUA_SPORE_ROCKSPEC}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://framagit.org/fperrad/lua-Spore
    tags/0.3.3
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
    # skip install
    INSTALL_COMMAND ""
)
