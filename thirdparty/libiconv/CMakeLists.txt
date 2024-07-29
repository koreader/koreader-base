list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=/
    --enable-shared=false --enable-static=true
    --with-threads=none
)

list(APPEND BUILD_CMD COMMAND make)

list(APPEND INSTALL_CMD COMMAND make DESTDIR=${STAGING_DIR} install)
# Get rid of libtool crap…
list(APPEND INSTALL_CMD COMMAND rm -f ${STAGING_DIR}/lib/libiconv.la ${STAGING_DIR}/lib/libcharset.la)

external_project(
    DOWNLOAD URL ace8b5f2db42f7b3b3057585e80d9808
    http://ftpmirror.gnu.org/libiconv/libiconv-1.15.tar.gz
    https://ftp.wayne.edu/gnu/libiconv/libiconv-1.15.tar.gz
    http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
