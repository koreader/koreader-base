project(libiconv LANGUAGES)

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --enable-shared=false --enable-static=true
    --with-threads=none
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} lib/localcharset.h)
list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C lib)

# Install static lib.
append_static_lib_install_command(INSTALL_CMD lib/.libs/libiconv.a iconv)

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    "${BINARY_DIR}/include/iconv.h"
)

set(LIBICONV_VER "1.15")

thirdparty_project(
    BUILD_ALWAYS
    URL http://ftpmirror.gnu.org/libiconv/libiconv-${LIBICONV_VER}.tar.gz
    URL_MD5 ace8b5f2db42f7b3b3057585e80d9808
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
