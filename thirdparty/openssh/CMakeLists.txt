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
    --without-hardening
    --without-openssl
    --without-stackprotect
    --without-zlib
)

set(PROGRAMS sftp-server)

list(APPEND BUILD_CMD COMMAND make ${PROGRAMS})

append_binary_install_command(INSTALL_CMD ${PROGRAMS})

external_project(
    DOWNLOAD URL 689148621a2eaa734497b12bed1c5202
    https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.0p1.tar.gz
    https://mirror.edgecast.com/pub/OpenBSD/OpenSSH/portable/openssh-10.0p1.tar.gz
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
