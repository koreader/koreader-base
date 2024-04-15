cmake_minimum_required(VERSION 3.15)
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
if(ANDROID OR DARWIN)
    string(APPEND GLIB2_INCLUDE_DIRS
        $<SEMICOLON> ${GETTEXT_DIR}/include
        $<SEMICOLON> ${LIBICONV_DIR}/include
    )
    string(APPEND GLIB2_LIBRARIES
        $<SEMICOLON> ${GETTEXT}
        $<SEMICOLON> ${LIBICONV}
    )
endif()
if(DARWIN)
    string(APPEND GLIB2_LIBRARIES
        $<SEMICOLON> "-framework CoreFoundation"
        $<SEMICOLON> "-framework CoreServices"
        $<SEMICOLON> "-framework Security"
    )
else()
    # Need pthread library and rt library on old glibc (for `clock_gettime`).
    string(APPEND GLIB2_LIBRARIES $<SEMICOLON> -pthread)
    if(NOT ANDROID)
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
    -DZLIB_ROOT=${ZLIB_DIR}
    -DZLIB_LIBRARY_RELEASE=${ZLIB}
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

external_project(
    URL https://github.com/Dushistov/sdcv/archive/refs/tags/v0.5.5.tar.gz
    URL_MD5 265dbfda83a57810595d156877f3e6fd
    CMAKE_ARGS ${CMAKE_ARGS}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
