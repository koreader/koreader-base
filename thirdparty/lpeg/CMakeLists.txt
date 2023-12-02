cmake_minimum_required(VERSION 3.5.1)
project(lpeg LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

assert_var_defined(LPEG_VER)
assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(LUA_INCDIR)
assert_var_defined(LUA_LIBDIR)
assert_var_defined(OUTPUT_DIR)
assert_var_defined(LUAROCKS)

ep_get_source_dir(SOURCE_DIR)

# For upstream's tarball
set(LPEG_RELEASE "1.0.2")
# For our own rockspec
set(LUA_LPEG_ROCKSPEC lpeg-${LPEG_VER}.rockspec)

# Rewrite Makefile to behave sensibly w/ LuaRocks, and optionally allow linking to the lua lib...
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/lpeg-${LPEG_RELEASE}-standard-makefile.patch)

# Move our custom rockspec to the build dir to fullfil build deps
set(CONFIGURE_CMD ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/${LUA_LPEG_ROCKSPEC} ${SOURCE_DIR}/${LUA_LPEG_ROCKSPEC})

# We want to run luarocks --version=5.1, not "luarocks --version=5.1"...
#separate_arguments(ROCKS_CMD NATIVE_COMMAND PROGRAM SEPARATE_ARGS "${LUAROCKS}")
set(ROCKS_CMD ${LUAROCKS})
separate_arguments(ROCKS_CMD)

set(BUILD_CMD ${ROCKS_CMD} make --tree=${OUTPUT_DIR}/rocks ${LUA_LPEG_ROCKSPEC})
set(BUILD_CMD ${BUILD_CMD} "CC=${CC}")
set(BUILD_CMD ${BUILD_CMD} "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}")
set(BUILD_CMD ${BUILD_CMD} "LUA_INCDIR=${LUA_INCDIR}" "LUA_LIBDIR=${LUA_LIBDIR}")
if(DEFINED LUALIB)
    set(BUILD_CMD ${BUILD_CMD} "LUALIB=${LUALIB}")
endif()
if(DEFINED LIBS)
    set(BUILD_CMD ${BUILD_CMD} "LIBS=${LIBS}")
endif()

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    URL http://distcache.FreeBSD.org/ports-distfiles/lpeg-${LPEG_RELEASE}.tar.gz
    URL_MD5 d342571886f1abcb7afe6a83d024d583
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CONFIGURE_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
