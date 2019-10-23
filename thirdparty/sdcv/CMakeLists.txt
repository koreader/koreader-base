project(sdcv)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")
include("DownloadProject")

enable_language(C CXX)

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

# because cmake needs all kinds of annoying special cmake variables
# Compiler and linker flags
if(DEFINED ENV{DARWIN})
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -framework CoreFoundation -framework Security")
endif()

if(DEFINED ENV{ANDROID})
    set(CMAKE_SYSTEM_NAME Android)
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
    # glib2 also needs to link with libiconv and gettext
    # this is a fairly clean hack
    # CMAKE_CXX_FLAGS with -I and -L doesn't seem to have much of an effect
    set(GLIB2_LIBRARIES "${GLIB2_LIBRARIES}$<SEMICOLON>${LIBICONV_DIR}/lib/libiconv.a$<SEMICOLON>${GETTEXT_DIR}/lib/libintl.a")
endif()

set(ZLIB_INCLUDE_DIR "${ZLIB_DIR}/include")
set(ZLIB_LIBRARIES "${ZLIB}")
# I just want to be able to -I and -L and have things work. CMake, CMake...
set(ZLIB_LIBRARY_RELEASE "${ZLIB}")

### Disable the silly build tree RPATH
set(CMAKE_SKIP_BUILD_RPATH True)

set(ENABLE_NLS False CACHE BOOL "")
set(WITH_READLINE False CACHE BOOL "")

# Force utf8 command line parsing, and accept not-found -u dictnames
set(PATCH_CMD "${KO_PATCH_SH} ${CMAKE_CURRENT_SOURCE_DIR}/sdcv.patch")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/Dushistov/sdcv.git
    v0.5.2
    ${SOURCE_DIR}
)

download_project(
    PROJ ${PROJECT_NAME}
    GIT_REPOSITORY
    https://github.com/Dushistov/sdcv.git
    GIT_TAG
    v0.5.2
    #DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD}
)

add_subdirectory("${CMAKE_BINARY_DIR}/sdcv-src"
                 "${CMAKE_BINARY_DIR}/sdcv-build")
