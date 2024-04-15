cmake_minimum_required(VERSION 3.5.1)
project(lua-Spore LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LD)
assert_var_defined(LUA_INCDIR)
assert_var_defined(LUA_LIBDIR)
assert_var_defined(LUA_SPORE_VER)
assert_var_defined(OUTPUT_DIR)
assert_var_defined(LUAROCKS)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

set(LUA_SPORE_ROCKSPEC rockspec/lua-spore-${LUA_SPORE_VER}.rockspec)

# We want to run luarocks --version=5.1, not "luarocks --version=5.1"...
#separate_arguments(ROCKS_CMD NATIVE_COMMAND PROGRAM SEPARATE_ARGS "${LUAROCKS}")
set(ROCKS_CMD ${LUAROCKS})
separate_arguments(ROCKS_CMD)

list(APPEND BUILD_CMD COMMAND ${ROCKS_CMD} make --tree=${OUTPUT_DIR}/rocks ${LUA_SPORE_ROCKSPEC})
list(APPEND BUILD_CMD "CC=${CC}" "CFLAGS=${CFLAGS}" "LD=${LD}")
list(APPEND BUILD_CMD "LUA_INCDIR=${LUA_INCDIR}" "LUA_LIBDIR=${LUA_LIBDIR}")

list(APPEND PATCH_CMD COMMAND mkdir -p doc)
list(APPEND PATCH_CMD COMMAND ${ISED} "s| 'luasocket|--&|g" ${LUA_SPORE_ROCKSPEC})

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://framagit.org/fperrad/lua-Spore
    tags/0.3.3
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
