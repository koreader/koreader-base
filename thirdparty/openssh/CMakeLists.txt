if(NOT APPLE AND MONOLIBTIC)
    # Need `-pthread` for static OpenSSL's crypto library.
    string(APPEND LDFLAGS " -pthread")
endif()
list(APPEND CFG_CMD COMMAND env)
if(LEGACY OR POCKETBOOK)
    # Avoid pulling-in `utimensat@@GLIBC_2.6` in `sftp-server`.
    list(APPEND CFG_CMD ac_cv_func_utimensat=no)
endif()
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

list(APPEND BUILD_CMD COMMAND make sftp-server scp)

append_binary_install_command(INSTALL_CMD scp sftp-server)

external_project(
    DOWNLOAD URL 5e90def5af3ffb27e149ca6fff12bef3
    https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-9.6p1.tar.gz
    https://mirror.edgecast.com/pub/OpenBSD/OpenSSH/portable/openssh-9.6p1.tar.gz
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
