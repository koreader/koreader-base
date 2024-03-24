list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    "${SOURCE_DIR}/configure" --host=${CHOST} "--prefix=/"
    --enable-shared=false --enable-static=true
    --with-threads=none
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

# Install static lib.
append_static_lib_install_command(INSTALL_CMD BYPRODUCTS lib/.libs/libiconv.a iconv)

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    "${BINARY_DIR}/include/iconv.h"
)

thirdparty_project(
    URL http://ftpmirror.gnu.org/libiconv/libiconv-1.15.tar.gz
    http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz
    URL_MD5 ace8b5f2db42f7b3b3057585e80d9808
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
