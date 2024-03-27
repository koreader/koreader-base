cmake_minimum_required(VERSION 3.5.1)
project(sdcv LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(GETTEXT)
assert_var_defined(GETTEXT_DIR)
assert_var_defined(LIBICONV)
assert_var_defined(LIBICONV_DIR)
assert_var_defined(GLIB)
assert_var_defined(GLIB_DIR)
assert_var_defined(ZLIB)
assert_var_defined(ZLIB_DIR)

ep_get_source_dir(SOURCE_DIR)

# Revert 6e36e7730caf07b6cd0bfa265cdf9b5e31e7acad, because it's not helpful in our workflow, and just causes logging noise.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/sdcv-no-unknown-dict-warning.patch)
# Force utf8 command line parsing
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/sdcv-locale-hack.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
if(DEFINED ENV{CMAKE_TCF})
    list(APPEND CMAKE_ARGS "$ENV{CMAKE_TCF}")
endif()
list(APPEND CMAKE_ARGS "-DCMAKE_SKIP_RPATH=TRUE")

# took me an eternity to find $<SEMICOLON>
# important docs here https://cmake.org/cmake/help/v2.8.11/cmake.html#command:add_custom_command
string(APPEND GLIB2_INCLUDE_DIRS
    "${GLIB_DIR}/include/glib-2.0"
    $<SEMICOLON>
    "${GLIB_DIR}/lib/glib-2.0/include"
)
string(APPEND GLIB2_LIBRARIES "${GLIB}")
if(DEFINED ENV{ANDROID} OR DEFINED ENV{DARWIN})
    string(APPEND GLIB2_INCLUDE_DIRS
        $<SEMICOLON> "${GETTEXT_DIR}/include"
        $<SEMICOLON> "${LIBICONV_DIR}/include"
    )
    string(APPEND GLIB2_LIBRARIES
        $<SEMICOLON> "${GETTEXT}"
        $<SEMICOLON> "${LIBICONV}"
    )
endif()
if(DEFINED ENV{DARWIN})
    string(APPEND GLIB2_LIBRARIES
        $<SEMICOLON> "-framework CoreFoundation"
        $<SEMICOLON> "-framework CoreServices"
        $<SEMICOLON> "-framework Security"
    )
else()
    # Need pthread library and rt library on old glibc (for `clock_gettime`).
    string(APPEND GLIB2_LIBRARIES $<SEMICOLON> -pthread)
    if(NOT DEFINED ENV{ANDROID})
        string(APPEND GLIB2_LIBRARIES $<SEMICOLON> -lrt)
    endif()
endif()
list(APPEND CMAKE_ARGS "-DGLIB2_INCLUDE_DIRS=${GLIB2_INCLUDE_DIRS}")
list(APPEND CMAKE_ARGS "-DGLIB2_LIBRARIES=${GLIB2_LIBRARIES}")

list(APPEND CMAKE_ARGS "-DENABLE_NLS=False")
list(APPEND CMAKE_ARGS "-DWITH_READLINE=False")

list(APPEND CMAKE_ARGS "-DZLIB_INCLUDE_DIR=${ZLIB_DIR}/include")
list(APPEND CMAKE_ARGS "-DZLIB_LIBRARIES=${ZLIB}")
# I just want to be able to -I and -L and have things work. CMake, CMake...
list(APPEND CMAKE_ARGS "-DZLIB_LIBRARY_RELEASE=${ZLIB}")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS})

set(SDCV_GIT_COMMIT v0.5.5)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/Dushistov/sdcv.git
    ${SDCV_GIT_COMMIT}
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    CMAKE_ARGS ${CMAKE_ARGS}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_GENERATOR "Unix Makefiles"
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND COMMAND
)
