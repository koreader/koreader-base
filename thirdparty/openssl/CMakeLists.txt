list(APPEND PATCH_FILES
    reduce_build_verbosity.patch
    macos_rpath.patch
)
if(MONOLIBTIC)
    list(APPEND PATCH_FILES fix_libcrypto_pkg-config_entry.patch)
endif()

list(APPEND CFG_ENV_VAR
    CC=${HOSTCC}
    CXX=${HOSTCXX}
    # NOTE: Disable https://github.com/openssl/openssl/pull/9595 as it's causing
    # stalls long after the early boot on devices without the getrandom() syscall,
    # which is pretty much all of them, because it's a Linux 3.17+ & glibc 2.25+
    # feature.  This is most easily reproduced with scp transfers that will block
    # on the initial select on /dev/random.  Since those devices are low-power, UP,
    # and mostly idle, it can take a fairly noticeable amount of time for entropy
    # to be generated...
    CPPFLAGS=-DOPENSSL_RAND_SEED_DEVRANDOM_SHM_ID=-1
    CFLAGS=${CFLAGS}
    CXXFLAGS=${CXXFLAGS}
    LDFLAGS=${LDFLAGS}
)
# If we have a CHOST set, use it.
if(CHOST)
    list(APPEND CFG_ENV_VAR CROSS_COMPILE=${CHOST}-)
endif()

if(MONOLIBTIC)
    set(CFG_OPTS no-shared)
else()
    set(CFG_OPTS shared)
endif()

list(APPEND CFG_OPTS
    no-comp
    no-default-thread-pool
    no-hw
    no-legacy
    no-quic
    no-thread-pool
    no-ui-console
    no-uplink
    no-whirlpool
)

if(ANDROID)
    assert_var_defined(ENV{NDKABI})
    set(CFG_OPTS -D__ANDROID_API__=$ENV{NDKABI} ${CFG_OPTS})
    # If we're on ARM, make it so
    if(CHOST MATCHES "^armv7a-.*")
        set(CFG_OPTS android-arm ${CFG_OPTS})
    elseif(CHOST MATCHES "^aarch64-.*")
        set(CFG_OPTS android-arm64 ${CFG_OPTS})
    elseif(CHOST MATCHES "^x86_64-.*")
        set(CFG_OPTS android-x86_64 ${CFG_OPTS})
    else()
        set(CFG_OPTS android-x86 ${CFG_OPTS})
    endif()
else()
    # If we're on ARM, make it so
    if(CHOST MATCHES "^arm-.*")
        # Yes, OpenSSL's preset names make no sense.
        set(CFG_OPTS linux-armv4 -DL_ENDIAN ${CFG_OPTS})
    elseif(CHOST MATCHES "^aarch64-.*")
        set(CFG_OPTS linux-aarch64 -DL_ENDIAN ${CFG_OPTS})
    endif()
endif()

# Do we support SIMD?
if(WANT_SIMD)
    set(ASM_OPT enable-asm)
else()
    set(ASM_OPT no-asm)
endif()

if(APPLE)
    list(APPEND CONFIGURE_CMD ${SOURCE_DIR}/Configure)
    if(DARWIN_AARCH64)
        list(APPEND CONFIGURE_CMD darwin64-arm64-cc)
    else()
        list(APPEND CONFIGURE_CMD darwin64-x86_64-cc)
    endif()
elseif(WIN32)
    list(APPEND CONFIGURE_CMD ${SOURCE_DIR}/Configure mingw)
elseif(EMULATE_READER)
    list(APPEND CONFIGURE_CMD ${SOURCE_DIR}/config)
else()
    list(APPEND CONFIGURE_CMD ${SOURCE_DIR}/Configure)
endif()

set(CFG_OPTS ${CFG_OPTS} ${ASM_OPT} no-async no-idea no-mdc2 no-rc5 no-tests)
list(APPEND CFG_CMD COMMAND
    env ${CFG_ENV_VAR}
    ${CONFIGURE_CMD}
    --prefix=${STAGING_DIR}
    --libdir=lib
    ${CFG_OPTS}
)

set(MAKE_CMD
    make
    AR=${AR}
    CC=${CC}
    CXX=${CXX}
    LD=${LD}
    MAKEDEPEND=${CC}
    RANLIB=${RANLIB}
    # Reproducible builds.
    SOURCE_DATE_EPOCH=1694383200
)

list(APPEND BUILD_CMD COMMAND ${MAKE_CMD} build_libs)

list(APPEND INSTALL_CMD COMMAND ${MAKE_CMD} install_dev)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD crypto VERSION 3)
    append_shared_lib_install_commands(INSTALL_CMD ssl VERSION 3)
endif()

external_project(
    DOWNLOAD URL 34733f7be2d60ecd8bd9ddb796e182af
    https://github.com/openssl/openssl/releases/download/openssl-3.4.0/openssl-3.4.0.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
