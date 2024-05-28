cmake_minimum_required(VERSION 3.5.1)
project(lua-rapidjson LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(CXX)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(LUA_INCDIR)
assert_var_defined(LUA_LIBDIR)
assert_var_defined(LUA_RAPIDJSON_VER)
assert_var_defined(OUTPUT_DIR)
assert_var_defined(LUAROCKS)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

set(LUA_RAPIDJSON_ROCKSPEC rapidjson-${LUA_RAPIDJSON_VER}.rockspec)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/lua-rapidjson-never-native.patch)
if(DEFINED ENV{ANDROID})
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/lua-rapidjson-android-link-to-lua.patch)
endif()

# We want to run luarocks --version=5.1, not "luarocks --version=5.1"...
#separate_arguments(ROCKS_CMD NATIVE_COMMAND PROGRAM SEPARATE_ARGS "${LUAROCKS}")
set(ROCKS_CMD ${LUAROCKS})
separate_arguments(ROCKS_CMD)

list(APPEND BUILD_CMD COMMAND ${ROCKS_CMD} make --tree=${OUTPUT_DIR}/rocks ${LUA_RAPIDJSON_ROCKSPEC})
list(APPEND BUILD_CMD "CC=${CC}" "CXX=${CXX}")
list(APPEND BUILD_CMD "CFLAGS=${CFLAGS}" "CXXFLAGS=${CXXFLAGS}" "LDFLAGS=${LDFLAGS} ${LIBFLAG}")
list(APPEND BUILD_CMD "LUA_INCDIR=${LUA_INCDIR}" "LUA_LIBDIR=${LUA_LIBDIR}")
if(DEFINED LUALIB)
    list(APPEND BUILD_CMD "LUALIB=${LUALIB}")
endif()
if(DEFINED LIBFLAG)
    list(APPEND BUILD_CMD "LIBFLAG=${LIBFLAG}")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/xpol/lua-rapidjson
    242b40c8eaceb0cc43bcab88309736461cac1234
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
