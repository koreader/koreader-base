# Revert 6e36e7730caf07b6cd0bfa265cdf9b5e31e7acad, because it's not helpful in our workflow, and just causes logging noise.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/sdcv-no-unknown-dict-warning.patch)
# Force utf8 command line parsing
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/sdcv-locale-hack.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

set(GLIB2_LIBRARIES "${STAGING_DIR}/lib/libglib-2.0.a")
if(ANDROID OR DARWIN)
    string(APPEND GLIB2_LIBRARIES
        $<SEMICOLON> "${STAGING_DIR}/lib/libiconv.a"
        $<SEMICOLON> "${STAGING_DIR}/lib/libintl.a"
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
        string(APPEND GLIB2_LIBRARIES $<SEMICOLON> rt)
    endif()
endif()

list(APPEND CMAKE_ARGS "-DGLIB2_INCLUDE_DIRS=${STAGING_DIR}/include")
list(APPEND CMAKE_ARGS "-DGLIB2_LIBRARIES=${GLIB2_LIBRARIES}")

list(APPEND CMAKE_ARGS "-DENABLE_NLS=False")
list(APPEND CMAKE_ARGS "-DWITH_READLINE=False")

if(ANDROID)
    list(APPEND CMAKE_ARGS "-DZLIB_LIBRARY_RELEASE=${STAGING_DIR}/lib/libz.a")
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

# Install executable.
append_binary_install_command(INSTALL_CMD BYPRODUCTS sdcv)

thirdparty_project(
    URL https://github.com/Dushistov/sdcv/archive/refs/tags/v0.5.5.tar.gz
    URL_MD5 265dbfda83a57810595d156877f3e6fd
    CMAKE_ARGS ${CMAKE_ARGS}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
