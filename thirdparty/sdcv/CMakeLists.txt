cmake_minimum_required(VERSION 3.15)
project(sdcv LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

# Revert 6e36e7730caf07b6cd0bfa265cdf9b5e31e7acad, because it's not helpful in our workflow, and just causes logging noise.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/sdcv-no-unknown-dict-warning.patch)
# Force utf8 command line parsing
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/sdcv-locale-hack.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

# took me an eternity to find $<SEMICOLON>
# important docs here https://cmake.org/cmake/help/v2.8.11/cmake.html#command:add_custom_command
string(APPEND GLIB2_INCLUDE_DIRS
    "${STAGING_DIR}/include/glib-2.0"
    $<SEMICOLON>
    "${STAGING_DIR}/lib/glib-2.0/include"
)
list(APPEND CMAKE_ARGS "-DGLIB2_INCLUDE_DIRS=${GLIB2_INCLUDE_DIRS}")

# For some reason this doesn't actually work and CMake keeps finding mostly .so
# Which is funny, because the .a is in the *same* directory. Just saying.
# Instead we add semi-hardcoded references to the right libraries in GLIB2_LIBRARIES
# glib2 also needs to link with libiconv and gettext
# this is a fairly clean hack
# CMAKE_CXX_FLAGS with -I and -L doesn't seem to have much of an effect
string(APPEND GLIB2_LIBRARIES
    "${STAGING_DIR}/lib/libglib-2.0.a"
    $<SEMICOLON>
    "${STAGING_DIR}/lib/libiconv.a"
    $<SEMICOLON>
    "${STAGING_DIR}/lib/libintl.a"
)
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
list(APPEND CMAKE_ARGS "-DGLIB2_LIBRARIES=${GLIB2_LIBRARIES}")

list(APPEND CMAKE_ARGS "-DENABLE_NLS=False")
list(APPEND CMAKE_ARGS "-DWITH_READLINE=False")

if(ANDROID)
    list(APPEND CMAKE_ARGS "-DZLIB_LIBRARY_RELEASE=${STAGING_DIR}/lib/libz.a")
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

thirdparty_project(
    URL https://github.com/Dushistov/sdcv/archive/refs/tags/v0.5.5.tar.gz
    URL_MD5 265dbfda83a57810595d156877f3e6fd
    CMAKE_ARGS ${CMAKE_ARGS}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
