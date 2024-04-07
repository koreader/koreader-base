cmake_minimum_required(VERSION 3.5.1)
project(lunasvg LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CPPFLAGS)
assert_var_defined(CFLAGS)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# Make sure the daisy-chain once again picks up our toolchain file...
if(DEFINED ENV{CMAKE_TCF})
    list(APPEND CMAKE_ARGS "$ENV{CMAKE_TCF}")
endif()
# CMake hell.
# We expect lib later on in Makefile.third, even on multilib systems...
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${BINARY_DIR}")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_LIBDIR=lib")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_INCLUDEDIR=include")
list(APPEND CMAKE_ARGS "-DCMAKE_SKIP_RPATH=TRUE")
#list(APPEND CMAKE_ARGS "-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON")
# Honor the env, dammit.
list(APPEND CMAKE_ARGS "-DCMAKE_EXE_LINKER_FLAGS=${LDFLAGS}")
list(APPEND CMAKE_ARGS "-DCMAKE_MODULE_LINKER_FLAGS=${LDFLAGS}")
list(APPEND CMAKE_ARGS "-DCMAKE_SHARED_LINKER_FLAGS=${LDFLAGS}")
list(APPEND CMAKE_ARGS "-DCMAKE_C_FLAGS=${CPPFLAGS} ${CFLAGS}")
list(APPEND CMAKE_ARGS "-DCMAKE_CXX_FLAGS=${CPPFLAGS} ${CXXFLAGS}")

# Actual LunaSVG build options
list(APPEND CMAKE_ARGS "-DBUILD_SHARED_LIBS=ON")

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/extended.patch)
list(APPEND PATCH_CMD COMMAND cp -rpv ${CMAKE_CURRENT_SOURCE_DIR}/xtended ${SOURCE_DIR}/)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_PROGRAM} install)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/sammycage/lunasvg.git
    59d6f6ba835c1b7c7a0f9d4ea540ec3981777885
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    lunasvg
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD}
    CMAKE_ARGS "${CMAKE_ARGS}"
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
