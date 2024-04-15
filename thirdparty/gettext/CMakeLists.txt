cmake_minimum_required(VERSION 3.7)
project(gettext LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

assert_var_defined(CC)
assert_var_defined(AR)
assert_var_defined(RANLIB)
assert_var_defined(CPPFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(LIBICONV_PREFIX)
assert_var_defined(CHOST_OPTS)

set(CFG_ENV_VAR "CC=${CC}" "AR=${AR}" "RANLIB=${RANLIB}" "CPPFLAGS=${CPPFLAGS}" "LDFLAGS=${LDFLAGS}")
set(CFG_OPTS --enable-silent-rules --disable-threads --disable-java)
set(CFG_OPTS ${CFG_OPTS} --prefix=${INSTALL_DIR} --with-libiconv-prefix=${LIBICONV_PREFIX} --with-included-gettext)
set(CFG_OPTS ${CFG_OPTS} --enable-shared=false --enable-static=true ${CHOST_OPTS})
list(APPEND CFG_CMD COMMAND env ${CFG_ENV_VAR} ${SOURCE_DIR}/gettext-runtime/configure ${CFG_OPTS})

if(DEFINED ENV{ANDROID})
    # Tools? Where we're going we don't need tools.
    list(APPEND CFG_CMD COMMAND ${ISED} "s/^\\(subdirs\\|SUBDIRS\\)\\( = .*\\) gettext-tools$/\\1\\2/" Makefile)
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C intl)

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} -C intl install)

set(GETTEXT_VER "0.21")

external_project(
    URL http://ftpmirror.gnu.org/gettext/gettext-${GETTEXT_VER}.tar.gz
    http://ftp.gnu.org/pub/gnu/gettext/gettext-${GETTEXT_VER}.tar.gz
    URL_MD5 28b1cd4c94a74428723ed966c38cf479
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
