cmake_minimum_required(VERSION 3.5.1)
project(sdcv LANGUAGES)

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

list(APPEND PATCH_CMD COMMAND ${KO_PATCH}
    # Revert 6e36e7730caf07b6cd0bfa265cdf9b5e31e7acad, because it's
    # not helpful in our workflow, and just causes logging noise.
    ${CMAKE_CURRENT_SOURCE_DIR}/sdcv-no-unknown-dict-warning.patch
    # Force UTF-8 command line parsing.
    ${CMAKE_CURRENT_SOURCE_DIR}/sdcv-locale-hack.patch
)

# took me an eternity to find $<SEMICOLON>
# important docs here https://cmake.org/cmake/help/v2.8.11/cmake.html#command:add_custom_command
string(APPEND GLIB2_INCLUDE_DIRS
    ${GLIB_DIR}/include/glib-2.0
    $<SEMICOLON>
    ${GLIB_DIR}/lib/glib-2.0/include
)
string(APPEND GLIB2_LIBRARIES ${GLIB})
if(DEFINED ENV{ANDROID} OR DEFINED ENV{DARWIN})
    string(APPEND GLIB2_INCLUDE_DIRS
        $<SEMICOLON> ${GETTEXT_DIR}/include
        $<SEMICOLON> ${LIBICONV_DIR}/include
    )
    string(APPEND GLIB2_LIBRARIES
        $<SEMICOLON> ${GETTEXT}
        $<SEMICOLON> ${LIBICONV}
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

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}
    # Project options.
    -DENABLE_NLS=False
    -DWITH_READLINE=False
    # GLib.
    -DGLIB2_INCLUDE_DIRS=${GLIB2_INCLUDE_DIRS}
    -DGLIB2_LIBRARIES=${GLIB2_LIBRARIES}
    # Zlib.
    -DZLIB_INCLUDE_DIR=${ZLIB_DIR}/include
    -DZLIB_LIBRARIES=${ZLIB}
    # I just want to be able to -I and -L and have things work. CMake, CMake...
    -DZLIB_LIBRARY_RELEASE=${ZLIB}
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

set(SDCV_GIT_COMMIT v0.5.5)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/Dushistov/sdcv.git
    ${SDCV_GIT_COMMIT}
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    CMAKE_ARGS ${CMAKE_ARGS}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
