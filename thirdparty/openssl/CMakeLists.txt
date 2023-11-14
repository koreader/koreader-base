project(openssl LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

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
    set(CFG_ENV_VAR "CROSS_COMPILE=${CHOST}-" "CC=${CMAKE_C_COMPILER}")
endif()

if(ANDROID)
    assert_var_defined(ENV{NDKABI})
    set(CFG_OPTS -D__ANDROID_API__=$ENV{NDKABI} ${CFG_OPTS})
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
if(WANT_SIMD)
    set(ASM_OPT enable-asm)
else()
    set(ASM_OPT no-asm)
endif()

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/openssl-1.1.0j-parallel_install_fix.patch)

# NOTE: Disable https://github.com/openssl/openssl/pull/9595 as it's causing stalls long after the early boot on devices without the getrandom() syscall, which is pretty much all of them, because it's a Linux 3.17+ & glibc 2.25+ feature.
#       This is most easily reproduced with scp transfers that will block on the initial select on /dev/random. Since those devices are low-power, UP, and mostly idle, it can take a fairly noticeable amount of time for entropy to be generated...
set(CFLAGS "-DOPENSSL_RAND_SEED_DEVRANDOM_SHM_ID=-1 ${CFLAGS}")

# NOTE: We need to pass $CFLAGS to OpenSSL's Configure script,
# except it balks on a few exotic flags, so, filter those out...
string(REGEX REPLACE "--sysroot [.a-zA-Z0-9/_-]*" "" FILTERED_CFLAGS "${CFLAGS}")
if(ANDROID)
    string(REPLACE "-no-canonical-prefixes" "" FILTERED_CFLAGS "${FILTERED_CFLAGS}")
endif()

if(DARWIN)
    list(APPEND CONFIGURE_CMD Configure)
    if (DARWIN_AARCH64)
        list(APPEND CONFIGURE_CMD darwin64-arm64-cc)
    else()
        list(APPEND CONFIGURE_CMD darwin64-x86_64-cc)
    endif()
elseif(WIN32)
    list(APPEND CONFIGURE_CMD Configure mingw)
elseif(EMULATE_READER)
    list(APPEND CONFIGURE_CMD config)
else()
    list(APPEND CONFIGURE_CMD Configure)
endif()

set(CFG_OPTS ${CFG_OPTS} ${ASM_OPT} no-idea no-mdc2 no-rc5)
list(APPEND CFG_CMD COMMAND env ${CFG_ENV_VAR} ${SOURCE_DIR}/${CONFIGURE_CMD} ${CFG_OPTS})

if(ANDROID)
    set(MAKE_CMD ${KO_MAKE_RECURSIVE} "CFLAGS=${FILTERED_CFLAGS}" "SHARED_LDFLAGS=${LDFLAGS}" "LD=${LD}" "AR=${AR}" "RANLIB=${RANLIB}")
else()
    set(MAKE_CMD ${KO_MAKE_RECURSIVE} "CC=${CC}" "CFLAGS=${FILTERED_CFLAGS}" "SHARED_LDFLAGS=${LDFLAGS}" "LD=${LD}" "AR=${AR}" "RANLIB=${RANLIB}")
endif()
# NOTE: Make depend may fail when using ccache, and may fail when // (on some OpenSSL versions, at least)
list(APPEND CFG_CMD COMMAND ${MAKE_CMD} -j1 depend)
list(APPEND BUILD_CMD COMMAND ${MAKE_CMD} build_libs)

set(CRYPTO_LIB_SPEC ssl VERSION 1.1)
set_libname(CRYPTO_LIB ${CRYPTO_LIB_SPEC})
set(SSL_LIB_SPEC crypto VERSION 1.1)
set_libname(SSL_LIB ${SSL_LIB_SPEC})

# Install shared libs.
append_shared_lib_install_command(INSTALL_CMD ${CRYPTO_LIB} ${CRYPTO_LIB_SPEC})
append_shared_lib_install_command(INSTALL_CMD ${SSL_LIB} ${SSL_LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD SUBDIR openssl
    "${SOURCE_DIR}/include/openssl/*.h"
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/openssl/openssl.git
    OpenSSL_1_1_1u
    ${SOURCE_DIR}
    none
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
