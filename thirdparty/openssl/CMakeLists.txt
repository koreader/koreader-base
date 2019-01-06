PROJECT(openssl)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CONFIG_SCRIPT)
assert_var_defined(CHOST)
assert_var_defined(REALCC)
assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(SHARED_LDFLAGS)
assert_var_defined(LD)
assert_var_defined(AR)
assert_var_defined(RANLIB)

ep_get_source_dir(SOURCE_DIR)

if(${MINGW})
    set(CFG_OPTS "no-shared")
else()
    set(CFG_OPTS "shared")
endif()

# If we have a CHOST set, use it
if (NOT "${CHOST}" STREQUAL "")
    set(CFG_ENV_VAR "CROSS_COMPILE=\"${CHOST}-\"")
endif()

if($ENV{ANDROID})
    # If we're on ARM, make it so
    if (${CHOST} MATCHES "^arm-.*")
        set(CFG_OPTS "android-armv7 -DL_ENDIAN ${CFG_OPTS}")
    else()
        set(CFG_OPTS "android-x86 ${CFG_OPTS}")
    endif()
else()
    # If we're on ARM, make it so
    if (${CHOST} MATCHES "^arm-.*")
        # Yes, OpenSSL's preset names make no sense.
        set(CFG_OPTS "linux-armv4 -DL_ENDIAN ${CFG_OPTS}")
    endif()
endif()

# Do we support SIMD?
if($ENV{WANT_SIMD})
    set(ASM_OPT "enable-asm")
else()
    set(ASM_OPT "no-asm")
endif()

set(PATCH_CMD1 sh -c "patch -N -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/openssl-origin-rpath.patch || true")

# NOTE: We need to pass $CFLAGS to OpenSSL's Configure script,
# except it balks on a few exotic flags, so, filter those out...
string(REGEX REPLACE "--sysroot [a-zA-Z0-9/_-]*" "" FILTERED_CFLAGS "${CFLAGS}")

set(CFG_OPTS "${CFG_OPTS} ${FILTERED_CFLAGS} ${ASM_OPT} no-idea no-mdc2 no-rc5 no-ssl2 no-ssl3")
set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/${CONFIG_SCRIPT} ${CFG_OPTS}")

set(MAKE_CMD "$(MAKE) CC=\"${CC}\" SHARED_LDFLAGS=\"${SHARED_LDFLAGS}\" LD=\"${LD}\" AR=\"${AR} r\" RANLIB=\"${RANLIB}\"")
# NOTE: Make depend fails when using ccache, and may fail when // (on some OpenSSL versions, at least)
set(BUILD_CMD1 sh -c "$(MAKE) -j1 depend")
set(BUILD_CMD2 sh -c "${MAKE_CMD} build_crypto build_ssl")

# NOTE: Wait for a really compatible luasec release before moving to 1.1.x
ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/openssl/openssl.git
    OpenSSL_1_0_2q
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
