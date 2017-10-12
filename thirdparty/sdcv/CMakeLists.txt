PROJECT(sdcv)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

assert_var_defined(PKG_CONFIG_PATH)
assert_var_defined(CMAKE_CXX_COMPILER)
assert_var_defined(CMAKE_CXX_COMPILER_LAUNCHER)
assert_var_defined(CMAKE_CXX_COMPILER_ARG1)
assert_var_defined(LDFLAGS)
assert_var_defined(HOST)
assert_var_defined(GETTEXT_DIR)
assert_var_defined(LIBICONV_DIR)
assert_var_defined(GLIB)
assert_var_defined(GLIB_DIR)
assert_var_defined(ZLIB)
assert_var_defined(ZLIB_DIR)

ep_get_source_dir(SOURCE_DIR)

if($ENV{ANDROID})
    set(CRIPPLED_BY_ANDROID_FILES "${SOURCE_DIR}/src/libwrapper.cpp ${SOURCE_DIR}/src/sdcv.cpp ${SOURCE_DIR}/src/utils.cpp")
    set(PATCH_CMD "${ISED} 's|_(|(|' ${CRIPPLED_BY_ANDROID_FILES}")
    set(PATCH_CMD "${PATCH_CMD} && ${ISED} 's|#include <glib/gi18n.h>||' ${CRIPPLED_BY_ANDROID_FILES}")
    set(PATCH_CMD sh -c "${PATCH_CMD}")
endif()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -I$(ZLIB_DIR)")
if($ENV{ANDROID})
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -I${LIBICONV_DIR}/include -I${GETTEXT_DIR}/include")
else()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -lpthread -lrt")
endif()

# because cmake needs all kinds of annoying special cmake variables
set(CMAKE_EXE_LINKER_FLAGS "${LDFLAGS} -static-libgcc -static-libstdc++")
if($ENV{ANDROID})
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L${LIBICONV_DIR}/lib -L${GETTEXT_DIR}/lib")
endif()

# took me an eternity to find $<SEMICOLON>
# important docs here https://cmake.org/cmake/help/v2.8.11/cmake.html#command:add_custom_command
set(GLIB2_INCLUDE_DIRS "${GLIB_DIR}/include/glib-2.0")
set(GLIB2_INCLUDE_DIRS "${GLIB2_INCLUDE_DIRS}$<SEMICOLON>${GLIB_DIR}/lib/glib-2.0/include")
set(GLIB2_LIBRARIES "${GLIB}")
# glib2 also needs to link with libiconv and gettext
# this is the only cleanish hack I've been able to come up with
# CMAKE_CXX_FLAGS doesn't seem to have much of an effect
if($ENV{ANDROID})
    set(GLIB2_LIBRARIES "${GLIB2_LIBRARIES}$<SEMICOLON>${LIBICONV_DIR}/lib/libiconv.a$<SEMICOLON>${GETTEXT_DIR}/lib/libintl.a")
endif()


set(ZLIB_INCLUDE_DIR "${ZLIB_DIR}/include")
set(ZLIB_LIBRARIES "${ZLIB}")
# f*ck cmake, I just want to be able to -I and -L and have things work
set(ZLIB_LIBRARY_RELEASE "${ZLIB}")

# includes and libraries
set(CFG_OPTS "-DGLIB2_INCLUDE_DIRS='${GLIB2_INCLUDE_DIRS}' -DGLIB2_LIBRARIES='${GLIB2_LIBRARIES}' -DZLIB_INCLUDE_DIR='${ZLIB_INCLUDE_DIR}' -DZLIB_LIBRARIES='${ZLIB_LIBRARIES}' -DZLIB_LIBRARY_RELEASE='${ZLIB_LIBRARY_RELEASE}'")
# compiler and linker flags
set(CFG_OPTS "${CFG_OPTS} -DCMAKE_CXX_COMPILER='${CMAKE_CXX_COMPILER}' -DCMAKE_CXX_COMPILER_LAUNCHER='${CMAKE_CXX_COMPILER_LAUNCHER}' -DCMAKE_CXX_COMPILER_ARG1='${CMAKE_CXX_COMPILER_ARG1}' -DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}' -DCMAKE_EXE_LINKER_FLAGS='${CMAKE_EXE_LINKER_FLAGS}'")
# disable some stuff we don't need
set(CFG_OPTS "${CFG_OPTS} -DENABLE_NLS:BOOL=False -DWITH_READLINE:BOOL=False")
set(CFG_CMD sh -c "${CMAKE_COMMAND} ${CFG_OPTS}")

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
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS}
    # skip install
    INSTALL_COMMAND ""
)
