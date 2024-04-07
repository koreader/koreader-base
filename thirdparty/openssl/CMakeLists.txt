cmake_minimum_required(VERSION 3.5.1)
project(openssl LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CONFIG_SCRIPT)
assert_var_defined(CHOST)
assert_var_defined(REALCC)
assert_var_defined(CC)
assert_var_defined(CPPFLAGS)
assert_var_defined(CFLAGS)
assert_var_defined(SHARED_LDFLAGS)
assert_var_defined(LD)
assert_var_defined(AR)
assert_var_defined(RANLIB)

ep_get_source_dir(SOURCE_DIR)

# FIXME: Orphaned, MINGW is never set anywhere
if(${MINGW})
    set(CFG_OPTS no-shared)
else()
    set(CFG_OPTS shared)
endif()

# If we have a CHOST set, use it
if (NOT "${CHOST}" STREQUAL "")
    # NOTE: We bypass ccache for the Configure script, in the hope that it'll help the whole makedepend detection.
    #       At least OpenSSL 1.1.x now drops it instead of trying to call a nonexistent binary, so it's less annoying than before.
    set(CFG_ENV_VAR "CROSS_COMPILE=${CHOST}-" "CC=${REALCC}")
endif()

if(DEFINED ENV{ANDROID})
    assert_var_defined(NDKABI)
    set(CFG_OPTS -D__ANDROID_API__=${NDKABI} ${CFG_OPTS})
    # If we're on ARM, make it so
    if (${CHOST} MATCHES "^armv7a-.*")
        set(CFG_OPTS android-arm ${CFG_OPTS})
    elseif (${CHOST} MATCHES "^aarch64-.*")
        set(CFG_OPTS android-arm64 ${CFG_OPTS})
    elseif (${CHOST} MATCHES "^x86_64-.*")
        set(CFG_OPTS android-x86_64 ${CFG_OPTS})
    else()
        set(CFG_OPTS android-x86 ${CFG_OPTS})
    endif()
else()
    # If we're on ARM, make it so
    if (${CHOST} MATCHES "^arm-.*")
        # Yes, OpenSSL's preset names make no sense.
        set(CFG_OPTS linux-armv4 -DL_ENDIAN ${CFG_OPTS})
    elseif (${CHOST} MATCHES "^aarch64-.*")
        set(CFG_OPTS linux-aarch64 -DL_ENDIAN ${CFG_OPTS})
    endif()
endif()

# Do we support SIMD?
if(DEFINED ENV{WANT_SIMD})
    set(ASM_OPT enable-asm)
else()
    set(ASM_OPT no-asm)
endif()

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/openssl-1.1.0j-parallel_install_fix.patch)

# NOTE: Disable https://github.com/openssl/openssl/pull/9595 as it's causing stalls long after the early boot on devices without the getrandom() syscall, which is pretty much all of them, because it's a Linux 3.17+ & glibc 2.25+ feature.
#       This is most easily reproduced with scp transfers that will block on the initial select on /dev/random. Since those devices are low-power, UP, and mostly idle, it can take a fairly noticeable amount of time for entropy to be generated...
set(CFLAGS "${CPPFLAGS} -DOPENSSL_RAND_SEED_DEVRANDOM_SHM_ID=-1 ${CFLAGS}")

# NOTE: We need to pass $CFLAGS to OpenSSL's Configure script,
# except it balks on a few exotic flags, so, filter those out...
string(REGEX REPLACE "--sysroot [.a-zA-Z0-9/_-]*" "" FILTERED_CFLAGS "${CFLAGS}")
if(DEFINED ENV{ANDROID})
    string(REPLACE "-no-canonical-prefixes" "" FILTERED_CFLAGS "${FILTERED_CFLAGS}")
endif()

# May have an arg, split it
set(CONFIGURE_CMD ${CONFIG_SCRIPT})
separate_arguments(CONFIGURE_CMD)

set(CFG_OPTS ${CFG_OPTS} ${ASM_OPT} no-idea no-mdc2 no-rc5)
set(CFG_CMD env ${CFG_ENV_VAR} ${SOURCE_DIR}/${CONFIGURE_CMD} ${CFG_OPTS})

if(DEFINED ENV{ANDROID})
    set(MAKE_CMD ${KO_MAKE_RECURSIVE} "CFLAGS=${FILTERED_CFLAGS}" "SHARED_LDFLAGS=${SHARED_LDFLAGS}" "LD=${LD}" "AR=${AR}" "RANLIB=${RANLIB}")
else()
    set(MAKE_CMD ${KO_MAKE_RECURSIVE} "CC=${CC}" "CFLAGS=${FILTERED_CFLAGS}" "SHARED_LDFLAGS=${SHARED_LDFLAGS}" "LD=${LD}" "AR=${AR}" "RANLIB=${RANLIB}")
endif()
# NOTE: Make depend may fail when using ccache, and may fail when // (on some OpenSSL versions, at least)
list(APPEND BUILD_CMD COMMAND ${MAKE_CMD} -j1 depend)
list(APPEND BUILD_CMD COMMAND ${MAKE_CMD} build_libs)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/openssl/openssl.git
    OpenSSL_1_1_1w
    ${SOURCE_DIR}
    none
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_IN_SOURCE 1
    BUILD_COMMAND COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
