cmake_minimum_required(VERSION 3.7)
project(libiconv LANGUAGES)

include(koreader_thirdparty_common)

list(APPEND CFG_CMD COMMAND env
    AR=${AR}
    CC=${CC}
    LD=${LD}
    RANLIB=${RANLIB}
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --enable-shared=false --enable-static=true
    --with-threads=none
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} install)

external_project(
    URL http://ftpmirror.gnu.org/libiconv/libiconv-1.15.tar.gz
    http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz
    URL_MD5 ace8b5f2db42f7b3b3057585e80d9808
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
