project(zlib LANGUAGES)

# Whelp, apparently the 1.2.12 release was a fun one, so apply the full Gentoo patchset...
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zlib-1.2.11-minizip-drop-crypt-header.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zlib-1.2.11-configure-fix-AR-RANLIB-NM-detection.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zlib-1.2.13-use-LDFLAGS-in-configure.patch)

list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")

list(APPEND BUILD_CMD ${KO_MAKE_PROGRAM})

set(LIB_SPEC z VERSION 1)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD ${LIB} ${LIB_SPEC})

# Install static lib.
append_static_lib_install_command(INSTALL_CMD libz.a ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    "${BINARY_DIR}/zconf.h"
    "${SOURCE_DIR}/zlib.h"
)
# For MuPDF.
append_headers_install_command(
    INSTALL_CMD SUBDIR contrib/minizip
    "${SOURCE_DIR}/contrib/minizip/crypt.h"
)

set(ZLIB_VER "1.2.13")
set(ZLIB_MD5 "7d9fc1d78ae2fa3e84fe98b77d006c63")

thirdparty_project(
    BUILD_ALWAYS
    URL https://github.com/madler/zlib/releases/download/v${ZLIB_VER}/zlib-${ZLIB_VER}.tar.xz
    URL_MD5 ${ZLIB_MD5}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    INSTALL_BYPRODUCTS ${STAGING_DIR}/${PROJECT_NAME}/shared/libz${LIB_EXT}
)
