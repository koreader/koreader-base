project(openssh LANGUAGES)

set(PATCH_CMD sh -c "autoreconf -fi")

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    "CPPFLAGS=-I${STAGING_DIR}/openssl/include -I${STAGING_DIR}/zlib/include"
    "LIBS=${LDFLAGS} -L${STAGING_DIR}/openssl/shared -L${STAGING_DIR}/zlib/shared"
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --disable-etc-default-login
    --disable-lastlog
    --with-md5-passwords
    --with-openssl
    --with-ssl-engine
    --without-hardening
    --without-stackprotect
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} sftp-server scp)

# Install executables.
append_install_command(INSTALL_CMD scp sftp-server)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/openssh/openssh-portable.git
    V_8_6_P1
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
