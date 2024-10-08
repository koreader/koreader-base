list(APPEND PATCH_FILES
    # Revert 6e36e7730caf07b6cd0bfa265cdf9b5e31e7acad, because it's
    # not helpful in our workflow, and just causes logging noise.
    sdcv-no-unknown-dict-warning.patch
    # Force UTF-8 command line parsing.
    sdcv-locale-hack.patch
    # Fix compilation with newer GLib.
    compat_with_newer_glib.patch
)

string(APPEND GLIB2_INCLUDE_DIRS
    ${STAGING_DIR}/include/glib-2.0
    $<SEMICOLON>
    ${STAGING_DIR}/lib/glib-2.0/include
)
string(APPEND GLIB2_LIBRARIES ${STAGING_DIR}/lib/libglib-2.0.a)
if(NOT HAS_GETTEXT)
    string(APPEND GLIB2_LIBRARIES $<SEMICOLON> ${STAGING_DIR}/lib/libintl.a)
endif()
if(NOT HAS_ICONV)
    string(APPEND GLIB2_LIBRARIES $<SEMICOLON> ${STAGING_DIR}/lib/libiconv.a)
endif()
if(APPLE)
    string(APPEND GLIB2_LIBRARIES
        $<SEMICOLON> "-framework Foundation"
        $<SEMICOLON> "-framework AppKit"
    )
else()
    # Need pthread library and rt library on old glibc (for `clock_gettime`).
    string(APPEND GLIB2_LIBRARIES $<SEMICOLON> -pthread)
    if(NOT ANDROID)
        string(APPEND GLIB2_LIBRARIES $<SEMICOLON> -lrt)
    endif()
endif()

if(ANDROID OR MONOLIBTIC)
    set(ZLIB ${STAGING_DIR}/lib/libz.a)
else()
    set(ZLIB ${STAGING_DIR}/lib/libz${LIB_EXT})
endif()

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DENABLE_NLS=False
    -DWITH_READLINE=False
    # GLib.
    -DGLIB2_INCLUDE_DIRS=${GLIB2_INCLUDE_DIRS}
    -DGLIB2_LIBRARIES=${GLIB2_LIBRARIES}
    # Zlib.
    -DZLIB_LIBRARY_RELEASE=${ZLIB}
)

list(APPEND BUILD_CMD COMMAND ninja)

append_binary_install_command(INSTALL_CMD sdcv)

external_project(
    DOWNLOAD URL 265dbfda83a57810595d156877f3e6fd
    https://github.com/Dushistov/sdcv/archive/refs/tags/v0.5.5.tar.gz
    CMAKE_ARGS ${CMAKE_ARGS}
    PATCH_FILES ${PATCH_FILES}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
