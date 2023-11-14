project(gettext LANGUAGES)

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    "CPPFLAGS=-I${STAGING_DIR}/libiconv/include"
    "LIBS=-L${STAGING_DIR}/libiconv/static"
    ${SOURCE_DIR}/gettext-runtime/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --enable-shared=false --enable-static=true
    --disable-java
    --disable-threads
    --with-included-gettext
    --without-libiconv-prefix
)

if(ANDROID)
    # Tools? Where we're going we don't need tools.
    list(APPEND CFG_CMD COMMAND ${ISED} "s/^\\(subdirs\\|SUBDIRS\\)\\( = .*\\) gettext-tools$/\\1\\2/" Makefile)
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C intl)

# Install static lib.
append_static_lib_install_command(INSTALL_CMD intl/.libs/libintl.a intl)

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    "${BINARY_DIR}/intl/libintl.h"
)

set(GETTEXT_VER "0.21")

thirdparty_project(
    BUILD_ALWAYS
    URL http://ftpmirror.gnu.org/gettext/gettext-${GETTEXT_VER}.tar.gz
    URL_MD5 28b1cd4c94a74428723ed966c38cf479
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
