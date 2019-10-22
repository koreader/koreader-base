project(openssh)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CPPFLAGS)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(CHOST)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# NOTE: OpenSSH >= 7.9p1 is starting to deprecated OpenSSL < 1.1.x... -_-".
set(PATCH_CMD1 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/openssh-7.9_p1-openssl-1.0.2-compat.patch")
set(PATCH_CMD2 sh -c "autoreconf -fi")

set(CFG_ENV_VAR "CC=\"${CC}\" CPPFLAGS=\"${CPPFLAGS} -I${SOURCE_DIR}\" CFLAGS=\"${CFLAGS}\" LIBS=\"${LIBS}\" LDFLAGS=\"${LDFLAGS}\"")
set(CFG_OPTS "--host=\"${CHOST}\" --without-hardening --without-stackprotect --disable-etc-default-login --disable-lastlog --with-openssl --with-md5-passwords --with-ssl-engine")
set(CFG_CMD "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")
set(CFG_CMD sh -c "${CFG_CMD}")

set(BUILD_CMD "${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} sftp-server scp")

# We build in-tree...
set(INSTALL_CMD1 ${CMAKE_COMMAND} -E make_directory ${BINARY_DIR})
set(INSTALL_CMD2 ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/sftp-server ${BINARY_DIR}/sftp-server)
set(INSTALL_CMD3 ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/scp ${BINARY_DIR}/scp)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/openssh/openssh-portable.git
    V_7_9_P1
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND COMMAND ${PATCH_CMD1} COMMAND ${PATCH_CMD2}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND COMMAND ${INSTALL_CMD1} COMMAND ${INSTALL_CMD2} COMMAND ${INSTALL_CMD3}
)
