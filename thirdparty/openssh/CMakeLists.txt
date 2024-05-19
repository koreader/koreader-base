cmake_minimum_required(VERSION 3.5.1)
project(openssh LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CPPFLAGS)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(CHOST)

set(PATCH_CMD sh -c "autoreconf -fi")

set(CFG_ENV_VAR "CC=${CC}" "CPPFLAGS=${CPPFLAGS} -I${SOURCE_DIR}" "CFLAGS=${CFLAGS}" "LIBS=${LIBS}" "LDFLAGS=${LDFLAGS}")
set(CFG_OPTS --host=${CHOST} --without-hardening --without-stackprotect --disable-etc-default-login --disable-lastlog --with-openssl --with-md5-passwords --with-ssl-engine)
set(CFG_CMD ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})
set(CFG_CMD env ${CFG_CMD})

set(BUILD_CMD ${KO_MAKE_RECURSIVE} sftp-server scp)

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
