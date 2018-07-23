PROJECT(openssl)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CONFIG_SCRIPT)
assert_var_defined(REALCC)
assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(SHARED_LDFLAGS)
assert_var_defined(LD)
assert_var_defined(RANLIB)

ep_get_source_dir(SOURCE_DIR)

if(${MINGW})
    assert_var_defined(CHOST)
    set(CFG_ENV_VAR "CROSS_COMPILE=\"${CHOST}-\"")
    set(CFG_OPTS "no-shared")
else()
    set(CFG_ENV_VAR "")
    set(CFG_OPTS "shared")
endif()

if($ENV{ANDROID})
    set(CFG_ENV_VAR "${CFG_ENV_VAR} CROSS_COMPILE=\"${CHOST}-\"")
    # NOTE: Our Gitlab Docker image for Android builds doesn't ship makedepend, patch in https://github.com/afborchert/gcc-makedepend instead
    set(DEPEND_ENV_VAR "MAKEDEPEND=\"${SOURCE_DIR}/util/gcc-makedepend.pl\"")
    set(DEPEND_ARGS "MAKEDEPPROG=\"${SOURCE_DIR}/util/gcc-makedepend.pl\"")
else()
    set(DEPEND_ENV_VAR "")
    set(DEPEND_ARGS "")
endif()

set(PATCH_CMD1 sh -c "patch -N -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/openssl-origin-rpath.patch || true")
set(PATCH_CMD2 sh -c "patch -N -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/openssl-android-makedepend.patch || true")
set(PATCH_CMD3 sh -c "chmod a+x \"${SOURCE_DIR}/util/gcc-makedepend.pl\" || true")

# NOTE: We should be passing $CFLAGS to OpenSSL's Configure script, except it
# balks on a number of different flags, which we'd need to filter.
# Of particular interest, --sysroot breaks it hard (and we use it on Android,
# and crappy old TCs).
set(CFG_OPTS "${CFG_OPTS} no-asm no-idea no-mdc2 no-rc5 no-ssl2 no-ssl3")
set(CFG_CMD sh -c "${CFG_ENV_VAR} CC=\"${REALCC}\" ${SOURCE_DIR}/${CONFIG_SCRIPT} ${CFG_OPTS}")

set(MAKE_CMD "$(MAKE) CC=\"${CC}\" SHARED_LDFLAGS=\"${SHARED_LDFLAGS}\" LD=\"${LD}\" RANLIB=\"${RANLIB}\"")
# NOTE: Make depend fails when using ccache, and may fail when // (on some OpenSSL versions, at least)
set(MAKE_CMD_REALCC "$(MAKE) -j1 CC=\"${REALCC}\" SHARED_LDFLAGS=\"${SHARED_LDFLAGS}\" LD=\"${LD}\" RANLIB=\"${RANLIB}\"")
set(BUILD_CMD1 sh -c "${DEPEND_ENV_VAR} ${MAKE_CMD_REALCC} depend ${DEPEND_ARGS}")
set(BUILD_CMD2 sh -c "${MAKE_CMD} build_crypto build_ssl")


ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/openssl/openssl.git
    OpenSSL_1_0_2o
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD1} COMMAND ${PATCH_CMD2} COMMAND ${PATCH_CMD3}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_IN_SOURCE 1
    BUILD_COMMAND COMMAND ${BUILD_CMD1} COMMAND ${BUILD_CMD2}
    # skip install
    INSTALL_COMMAND ""
)
