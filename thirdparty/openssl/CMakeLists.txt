project(openssl)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

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

if(${MINGW})
    set(CFG_OPTS "no-shared")
else()
    set(CFG_OPTS "shared")
endif()

# If we have a CHOST set, use it
if (NOT "${CHOST}" STREQUAL "")
    # NOTE: We bypass ccache for the Configure script, in the hope that it'll help the whole makedepend detection.
    #       At least OpenSSL 1.1.x now drops it instead of trying to call a nonexistent binary, so it's less annoying than before.
    if($ENV{ANDROID})
        set(CFG_ENV_VAR "CC=\"gcc\"")
    else()
        set(CFG_ENV_VAR "CROSS_COMPILE=\"${CHOST}-\" CC=\"${REALCC}\"")
    endif()
endif()

if($ENV{ANDROID})
    # If we're on ARM, make it so
    if (${CHOST} MATCHES "^arm-.*")
        set(CFG_OPTS "android-arm ${CFG_OPTS}")
    elseif (${CHOST} MATCHES "^aarch64-.*")
        set(CFG_OPTS "android-arm64 ${CFG_OPTS}")
    else()
        set(CFG_OPTS "android-x86 ${CFG_OPTS}")
    endif()
else()
    # If we're on ARM, make it so
    if (${CHOST} MATCHES "^arm-.*")
        # Yes, OpenSSL's preset names make no sense.
        set(CFG_OPTS "linux-armv4 -DL_ENDIAN ${CFG_OPTS}")
    elseif (${CHOST} MATCHES "^aarch64-.*")
        set(CFG_OPTS "linux-aarch64 -DL_ENDIAN ${CFG_OPTS}")
    endif()
endif()

# Do we support SIMD?
if($ENV{WANT_SIMD})
    set(ASM_OPT "enable-asm")
else()
    set(ASM_OPT "no-asm")
endif()

set(PATCH_CMD1 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/openssl-1.1.0j-parallel_install_fix.patch")
set(PATCH_CMD2 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/openssl-origin-rpath.patch")
# GCC 4.9's <stdatomic.h> is broken (c.f., https://github.com/pytorch/pytorch/issues/3050)
if(DEFINED ENV{SONY_PRSTUX} OR DEFINED ENV{ANDROID})
    set(PATCH_CMD3 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/openssl-gcc-4.9-stdatomic.patch")
endif()

# NOTE: Disable https://github.com/openssl/openssl/pull/9595 as it's causing stalls long after the early boot on devices without the getrandom() syscall, which is pretty much all of them, because it's a Linux 3.17+ & glibc 2.25+ feature.
#       This is most easily reproduced with scp transfers that will block on the initial select on /dev/random. Since those devices are low-power, UP, and mostly idle, it can take a fairly noticeable amount of time for entropy to be generated...
set(CFLAGS "${CPPFLAGS} -DOPENSSL_RAND_SEED_DEVRANDOM_SHM_ID=-1 ${CFLAGS}")

# NOTE: We need to pass $CFLAGS to OpenSSL's Configure script,
# except it balks on a few exotic flags, so, filter those out...
string(REGEX REPLACE "--sysroot [.a-zA-Z0-9/_-]*" "" FILTERED_CFLAGS "${CFLAGS}")
if($ENV{ANDROID})
    string(REPLACE "-no-canonical-prefixes" "" FILTERED_CFLAGS "${FILTERED_CFLAGS}")
endif()

set(CFG_OPTS "${CFG_OPTS} ${FILTERED_CFLAGS} ${ASM_OPT} no-idea no-mdc2 no-rc5")
set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/${CONFIG_SCRIPT} ${CFG_OPTS}")

if($ENV{ANDROID})
    set(MAKE_CMD "${KO_MAKE_RECURSIVE} SHARED_LDFLAGS=\"${SHARED_LDFLAGS}\" LD=\"${LD}\" AR=\"${AR}\" RANLIB=\"${RANLIB}\"")
else()
    set(MAKE_CMD "${KO_MAKE_RECURSIVE} CC=\"${CC}\" SHARED_LDFLAGS=\"${SHARED_LDFLAGS}\" LD=\"${LD}\" AR=\"${AR}\" RANLIB=\"${RANLIB}\"")
endif()
# NOTE: Make depend may fail when using ccache, and may fail when // (on some OpenSSL versions, at least)
set(BUILD_CMD1 sh -c "${MAKE_CMD} -j1 depend")
set(BUILD_CMD2 sh -c "${MAKE_CMD} -j${PARALLEL_JOBS} build_libs")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/openssl/openssl.git
    OpenSSL_1_1_1q
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
