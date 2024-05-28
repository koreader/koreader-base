cmake_minimum_required(VERSION 3.7)
project(gettext LANGUAGES)

include(koreader_thirdparty_common)

assert_var_defined(LIBICONV_DIR)

string(APPEND CPPFLAGS " -I${LIBICONV_DIR}/include")
string(APPEND LDFLAGS " -L${LIBICONV_DIR}/lib")

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    ${SOURCE_DIR}/gettext-runtime/configure --host=${CHOST} --prefix=/
    --enable-shared=false --enable-static=true
    --disable-java
    --disable-threads
    --enable-silent-rules
    --with-included-gettext
)

if(ANDROID)
    # Tools? Where we're going we don't need tools.
    list(APPEND CFG_CMD COMMAND ${ISED} "s/^\\(subdirs\\|SUBDIRS\\)\\( = .*\\) gettext-tools$/\\1\\2/" Makefile)
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C intl)

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} -C intl DESTDIR=${INSTALL_DIR} install)

external_project(
    URL http://ftpmirror.gnu.org/gettext/gettext-0.21.tar.xz
    http://ftp.gnu.org/pub/gnu/gettext/gettext-0.21.tar.xz
    URL_MD5 40996bbaf7d1356d3c22e33a8b255b31
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
