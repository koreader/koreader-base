list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    ${SOURCE_DIR}/configure --host=${CHOST}
    --disable-etc-default-login
    --disable-lastlog
    --with-md5-passwords
    --with-openssl
    --with-ssl-engine
    --without-hardening
    --without-stackprotect
    --with-ssl-dir=${STAGING_DIR}
    --with-zlib=${STAGING_DIR}
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} sftp-server scp)

append_binary_install_command(INSTALL_CMD scp sftp-server)

external_project(
    URL https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-9.6p1.tar.gz
    https://mirror.edgecast.com/pub/OpenBSD/OpenSSH/portable/openssh-9.6p1.tar.gz
    URL_MD5 5e90def5af3ffb27e149ca6fff12bef3
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
