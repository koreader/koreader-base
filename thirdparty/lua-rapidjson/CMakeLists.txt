project(lua-rapidjson)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

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

ep_get_source_dir(SOURCE_DIR)

set(LUA_RAPIDJSON_ROCKSPEC rapidjson-${LUA_RAPIDJSON_VER}.rockspec)
set(PATCH_CMD "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/lua-rapidjson-never-native.patch")
if(DEFINED ENV{ANDROID})
    set(PATCH_CMD2 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/lua-rapidjson-android-link-to-lua.patch")
endif()

# We want to run luarocks --version=5.1, not "luarocks --version=5.1"...
separate_arguments(ROCKS_CMD NATIVE_COMMAND PROGRAM SEPARATE_ARGS "${LUAROCKS}")

set(BUILD_CMD ${ROCKS_CMD} make --tree=${OUTPUT_DIR}/rocks ${LUA_RAPIDJSON_ROCKSPEC})
set(BUILD_CMD ${BUILD_CMD} "CC=${CC}" "CXX=${CXX}")
set(BUILD_CMD ${BUILD_CMD} "CFLAGS=${CFLAGS}" "CXXFLAGS=${CXXFLAGS}" "LDFLAGS=${LDFLAGS} ${LIBFLAG}")
set(BUILD_CMD ${BUILD_CMD} "LUA_INCDIR=${LUA_INCDIR}" "LUA_LIBDIR=${LUA_LIBDIR}")
if(DEFINED LUALIB)
    set(BUILD_CMD ${BUILD_CMD} LUALIB="${LUALIB}")
endif()
if(DEFINED LIBFLAG)
    set(BUILD_CMD ${BUILD_CMD} LIBFLAG="${LIBFLAG}")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/xpol/lua-rapidjson
    242b40c8eaceb0cc43bcab88309736461cac1234
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD} COMMAND ${PATCH_CMD2}
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
