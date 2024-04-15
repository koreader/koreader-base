cmake_minimum_required(VERSION 3.7)
project(libiconv LANGUAGES)

include("koreader_thirdparty_common")

assert_var_defined(HOST)

set(CFG_ENV_VAR "CC=${CC}" "LD=${LD}" "AR=${AR}" "RANLIB=${RANLIB}")
set(CFG_OPTS --with-threads=none --prefix=${INSTALL_DIR} --enable-shared=false --enable-static=true --host=${HOST})
set(CFG_CMD env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} install)

set(ICONV_VER "1.15")

external_project(
    URL http://ftpmirror.gnu.org/libiconv/libiconv-${ICONV_VER}.tar.gz
    http://ftp.gnu.org/pub/gnu/libiconv/libiconv-${ICONV_VER}.tar.gz
    URL_MD5 ace8b5f2db42f7b3b3057585e80d9808
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
