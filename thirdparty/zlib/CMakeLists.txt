# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM} zlib zlibstatic)

set(LIB_SPEC z VERSION 1)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${LIB} ${LIB_SPEC})

# Install static lib.
append_static_lib_install_command(INSTALL_CMD BYPRODUCTS libz.a ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    "${BINARY_DIR}/zconf.h"
    "${SOURCE_DIR}/zlib.h"
)
# For MuPDF.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    SUBDIR contrib/minizip
    "${SOURCE_DIR}/contrib/minizip/crypt.h"
)

thirdparty_project(
    URL https://github.com/madler/zlib/releases/download/v1.3/zlib-1.3.tar.xz
    URL_MD5 b49e70aacafacfceb1107943497f5545
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
