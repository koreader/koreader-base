PROJECT(sdcv)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

assert_var_defined(PKG_CONFIG_PATH)
assert_var_defined(CMAKE_C_COMPILER)
assert_var_defined(CMAKE_C_COMPILER_LAUNCHER)
assert_var_defined(CMAKE_C_COMPILER_ARG1)
assert_var_defined(CMAKE_CXX_COMPILER)
assert_var_defined(CMAKE_CXX_COMPILER_LAUNCHER)
assert_var_defined(CMAKE_CXX_COMPILER_ARG1)
assert_var_defined(CFLAGS)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(HOST)
assert_var_defined(GETTEXT_DIR)
assert_var_defined(LIBICONV_DIR)
assert_var_defined(GLIB)
assert_var_defined(GLIB_DIR)
assert_var_defined(ZLIB)
assert_var_defined(ZLIB_DIR)

ep_get_source_dir(SOURCE_DIR)

if(DEFINED ENV{ANDROID})
    set(CRIPPLED_BY_ANDROID_FILES "${SOURCE_DIR}/src/libwrapper.cpp ${SOURCE_DIR}/src/sdcv.cpp ${SOURCE_DIR}/src/utils.cpp")
    set(PATCH_CMD "${ISED} 's|_(|(|' ${CRIPPLED_BY_ANDROID_FILES}")
    set(PATCH_CMD "${PATCH_CMD} && ${ISED} 's|#include <glib/gi18n.h>||' ${CRIPPLED_BY_ANDROID_FILES}")
    set(PATCH_CMD sh -c "${PATCH_CMD}")
endif()

# because cmake needs all kinds of annoying special cmake variables
set(CMAKE_EXE_LINKER_FLAGS "${LDFLAGS} -static-libstdc++")
if(DEFINED ENV{DARWIN})
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -framework CoreFoundation -framework Security")
endif()

if(DEFINED ENV{ANDROID})
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libgcc -static")
endif()

# took me an eternity to find $<SEMICOLON>
# important docs here https://cmake.org/cmake/help/v2.8.11/cmake.html#command:add_custom_command
set(GLIB2_INCLUDE_DIRS "${GLIB_DIR}/include/glib-2.0")
set(GLIB2_INCLUDE_DIRS "${GLIB2_INCLUDE_DIRS}$<SEMICOLON>${GLIB_DIR}/lib/glib-2.0/include$<SEMICOLON>${GETTEXT_DIR}/include")
set(GLIB2_LIBRARIES "${GLIB}")

# `CMAKE_PREFIX_PATH`, `CMAKE_INCLUDE_PATH` and `CMAKE_LIBRARY_PATH` are key
# It's very hard to tell CMake to use specific directories, but it's easy to
# tell it to search in specific directories.
set(CMAKE_PREFIX_PATH "${GLIB2_INCLUDE_DIRS}$<SEMICOLON>${ZLIB_DIR}$<SEMICOLON>${LIBICONV_DIR}$<SEMICOLON>${GETTEXT_DIR}")

# For some reason this doesn't actually work and CMake keeps finding mostly .so
# Which is funny, because the .a is in the *same* directory. Just saying.
# Instead we add semi-hardcoded references to the right libraries in GLIB2_LIBRARIES
if(DEFINED ENV{ANDROID} OR DEFINED ENV{DARWIN})
    set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")

    # glib2 also needs to link with libiconv and gettext
    # this is a fairly clean hack
    # CMAKE_CXX_FLAGS with -I and -L doesn't seem to have much of an effect
    set(GLIB2_LIBRARIES "${GLIB2_LIBRARIES}$<SEMICOLON>${LIBICONV_DIR}/lib/libiconv.a$<SEMICOLON>${GETTEXT_DIR}/lib/libintl.a")
endif()

set(ZLIB_INCLUDE_DIR "${ZLIB_DIR}/include")
set(ZLIB_LIBRARIES "${ZLIB}")
# I just want to be able to -I and -L and have things work. CMake, CMake...
set(ZLIB_LIBRARY_RELEASE "${ZLIB}")

### Includes and libraries
# By overspecifying the heck out of everything we hope to force CMake into the
# equivalent of a couple of simple -I and -L flags because the proper method
# with CMAKE_PREFIX_PATH and CMAKE_FIND_LIBRARY_SUFFIXES does. not. work
set(CFG_OPTS "-DGLIB2_INCLUDE_DIRS='${GLIB2_INCLUDE_DIRS}' -DGLIB2_LIBRARIES='${GLIB2_LIBRARIES}' -DZLIB_INCLUDE_DIR='${ZLIB_INCLUDE_DIR}' -DZLIB_LIBRARIES='${ZLIB_LIBRARIES}' -DZLIB_LIBRARY_RELEASE='${ZLIB_LIBRARY_RELEASE}'")
# These are the directories where we tell CMake to search for libs and includes
set(CFG_OPTS "${CFG_OPTS} -DCMAKE_PREFIX_PATH='${CMAKE_PREFIX_PATH}'")
if($ENV{ANDROID})
    # the default `;` causes escape issues
    # we could escape it but on Android we only want .a and otherwise the default
    set(CFG_OPTS "${CFG_OPTS} -DCMAKE_FIND_LIBRARY_SUFFIXES='${CMAKE_FIND_LIBRARY_SUFFIXES}'")
    set(CFG_OPTS "${CFG_OPTS} -DCMAKE_SYSTEM_NAME=Android -DCMAKE_SYSTEM_VERSION=1")
endif()
### Compiler and linker flags
set(CFG_OPTS "${CFG_OPTS} -DCMAKE_C_COMPILER='${CMAKE_C_COMPILER}' -DCMAKE_C_COMPILER_LAUNCHER='${CMAKE_C_COMPILER_LAUNCHER}' -DCMAKE_C_COMPILER_ARG1='${CMAKE_C_COMPILER_ARG1}' -DCMAKE_CXX_COMPILER='${CMAKE_CXX_COMPILER}' -DCMAKE_CXX_COMPILER_LAUNCHER='${CMAKE_CXX_COMPILER_LAUNCHER}' -DCMAKE_CXX_COMPILER_ARG1='${CMAKE_CXX_COMPILER_ARG1}' -DCMAKE_CXX_FLAGS='${CXXFLAGS}' -DCMAKE_EXE_LINKER_FLAGS='${CMAKE_EXE_LINKER_FLAGS}'")
### Disable some sdcv stuff we don't need
set(CFG_OPTS "${CFG_OPTS} -DENABLE_NLS:BOOL=False -DWITH_READLINE:BOOL=False")
### Disable the silly build tree RPATH
set(CFG_OPTS "${CFG_OPTS} -DCMAKE_SKIP_BUILD_RPATH:BOOL=True")
set(CFG_CMD sh -c "${CMAKE_COMMAND} ${CFG_OPTS}")
# Force utf8 command line parsing, and accept not-found -u dictnames
set(PATCH_CMD2 sh -c "patch -N -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/sdcv.patch || true")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/Dushistov/sdcv.git
    v0.5.2
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND COMMAND ${PATCH_CMD} COMMAND ${PATCH_CMD2}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS}
    # skip install
    INSTALL_COMMAND ""
)
