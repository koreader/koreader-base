cmake_minimum_required(VERSION 3.5.1)
project(lua-htmlparser LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LD)
assert_var_defined(LUA_INCDIR)
assert_var_defined(LUA_LIBDIR)
assert_var_defined(LUA_HTMLPARSER_VER)
assert_var_defined(OUTPUT_DIR)
assert_var_defined(LUAROCKS)

ep_get_source_dir(SOURCE_DIR)

set(LUA_HTMLPARSER_ROCKSPEC rockspecs/htmlparser-${LUA_HTMLPARSER_VER}.rockspec)

# We want to run luarocks --version=5.1, not "luarocks --version=5.1"...
# NOTE: The CMake 3.19+ variant is much nicer, but the CI run an older version...
#separate_arguments(ROCKS_CMD NATIVE_COMMAND PROGRAM SEPARATE_ARGS "${LUAROCKS}")
# And that's the poor man's version.
set(ROCKS_CMD ${LUAROCKS})
separate_arguments(ROCKS_CMD)

set(BUILD_CMD ${ROCKS_CMD} make --tree=${OUTPUT_DIR}/rocks ${LUA_HTMLPARSER_ROCKSPEC})
set(BUILD_CMD ${BUILD_CMD} "CC=${CC}" "CFLAGS=${CFLAGS}" "LD=${LD}")
set(BUILD_CMD ${BUILD_CMD} "LUA_INCDIR=${LUA_INCDIR}" "LUA_LIBDIR=${LUA_LIBDIR}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/msva/lua-htmlparser
    5ce9a775a345cf458c0388d7288e246bb1b82bff
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
