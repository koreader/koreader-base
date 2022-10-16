project(lpeg)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)

assert_var_defined(LPEG_VER)
assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(LUA_INCDIR)
assert_var_defined(LUA_LIBDIR)
assert_var_defined(OUTPUT_DIR)
assert_var_defined(LUAROCKS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# NOTE: Possibly needs a similar fix as LFS: https://github.com/keplerproject/luafilesystem/commit/a84d81bc52590f930e54f108099df5d155bdc8bf
set(LUA_LPEG_ROCKSPEC lpeg-${LPEG_VER}.rockspec)

# Move our custom rockspec to the build dir to fullfil build deps
set(CONFIGURE_CMD ${CMAKE_COMMAND} -E copy ${SOURCE_DIR}/${LUA_LPEG_ROCKSPEC} ${BINARY_DIR}/${LUA_LPEG_ROCKSPEC})

set(BUILD_CMD sh -c "${LUAROCKS} make --tree=${OUTPUT_DIR}/rocks ${LUA_RAPIDJSON_ROCKSPEC}")
set(BUILD_CMD "${BUILD_CMD} CC=\"${CC}\"")
set(BUILD_CMD "${BUILD_CMD} CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS} ${LIBFLAG}\"")
set(BUILD_CMD "${BUILD_CMD} LUA_INCDIR=\"${LUA_INCDIR}\" LUA_LIBDIR=\"${LUA_LIBDIR}\"")
if(DEFINED LUALIB)
    set(BUILD_CMD "${BUILD_CMD} LUALIB=\"${LUALIB}\"")
endif()
if(DEFINED LIBS)
    set(BUILD_CMD "${BUILD_CMD} LIBS=\"${LIBS}\"")
endif()

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    # skip download
    DOWNLOAD_COMMAND ""
    BUILD_IN_SOURCE 1
    # skip configure
    CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
