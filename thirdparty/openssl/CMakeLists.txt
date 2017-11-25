PROJECT(openssl)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CONFIG_SCRIPT)
assert_var_defined(CC)
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
endif()

set(CFG_OPTS "${CFG_OPTS} no-asm no-idea no-mdc2 no-rc5 no-ssl2 no-ssl3")
set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/${CONFIG_SCRIPT} ${CFG_OPTS}")

set(BUILD_CMD "$(MAKE) CC=\"${CC}\" SHARED_LDFLAGS=\"${SHARED_LDFLAGS}\" LD=\"${LD}\" RANLIB=\"${RANLIB}\"")
set(BUILD_CMD sh -c "${BUILD_CMD} --silent depend build_crypto build_ssl >/dev/null 2>&1")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/openssl/openssl.git
    OpenSSL_1_0_1u
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_IN_SOURCE 1
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
