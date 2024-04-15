cmake_minimum_required(VERSION 3.5.1)
project(openssh LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(OPENSSL_DIR)
assert_var_defined(ZLIB_DIR)

list(APPEND PATCH_CMD COMMAND autoreconf -fi)

list(APPEND CFG_CMD COMMAND env
    CC=${CC}
    CFLAGS=${CFLAGS}
    "CPPFLAGS=-I${OPENSSL_DIR}/include -I${ZLIB_DIR}/include"
    "LDFLAGS=${LDFLAGS} -L${OPENSSL_DIR} -L${ZLIB_DIR}/lib"
    ${SOURCE_DIR}/configure --host=${CHOST}
    --disable-etc-default-login
    --disable-lastlog
    --with-md5-passwords
    --with-openssl
    --with-ssl-engine
    --without-hardening
    --without-stackprotect
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} sftp-server scp)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/openssh/openssh-portable.git
    V_9_6_P1
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
