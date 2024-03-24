list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/reduce_build_verbosity.patch)

# FIXME: Orphaned, MINGW is never set anywhere
if(${MINGW})
    set(CFG_OPTS no-shared)
else()
    set(CFG_OPTS shared)
endif()

list(APPEND CFG_ENV_VAR
    "CC=${HOSTCC}"
    "CXX=${HOSTCXX}"
    # NOTE: Disable https://github.com/openssl/openssl/pull/9595 as it's causing
    # stalls long after the early boot on devices without the getrandom() syscall,
    # which is pretty much all of them, because it's a Linux 3.17+ & glibc 2.25+
    # feature.  This is most easily reproduced with scp transfers that will block
    # on the initial select on /dev/random.  Since those devices are low-power, UP,
    # and mostly idle, it can take a fairly noticeable amount of time for entropy
    # to be generated...
    "CPPFLAGS=-DOPENSSL_RAND_SEED_DEVRANDOM_SHM_ID=-1"
    "CFLAGS=${CFLAGS}"
    "CXXFLAGS=${CXXFLAGS}"
    "LDFLAGS=${LDFLAGS}"
)
# If we have a CHOST set, use it
if (NOT "${CHOST}" STREQUAL "")
    list(APPEND CFG_ENV_VAR "CROSS_COMPILE=${CHOST}-")
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

if(DARWIN)
    list(APPEND CONFIGURE_CMD "${SOURCE_DIR}/Configure")
    if (DARWIN_AARCH64)
        list(APPEND CONFIGURE_CMD darwin64-arm64-cc)
    else()
        list(APPEND CONFIGURE_CMD darwin64-x86_64-cc)
    endif()
elseif(WIN32)
    list(APPEND CONFIGURE_CMD "${SOURCE_DIR}/Configure" mingw)
elseif(EMULATE_READER)
    list(APPEND CONFIGURE_CMD "${SOURCE_DIR}/config")
else()
    list(APPEND CONFIGURE_CMD "${SOURCE_DIR}/Configure")
endif()

set(CFG_OPTS ${CFG_OPTS} ${ASM_OPT} no-idea no-mdc2 no-rc5)
list(APPEND CFG_CMD COMMAND
    env ${CFG_ENV_VAR}
    ${CONFIGURE_CMD}
    ${CFG_OPTS}
)

list(APPEND BUILD_CMD COMMAND
    ${KO_MAKE_RECURSIVE}
    "AR=${AR}"
    "CC=${CC}"
    "CXX=${CXX}"
    "LD=${LD}"
    "MAKEDEPEND=${CC}"
    "RANLIB=${RANLIB}"
    # Reproducible builds.
    "SOURCE_DATE_EPOCH=1694383200 UTC"
    build_libs
)

set(CRYPTO_LIB_SPEC ssl VERSION 1.1)
set_libname(CRYPTO_LIB ${CRYPTO_LIB_SPEC})
set(SSL_LIB_SPEC crypto VERSION 1.1)
set_libname(SSL_LIB ${SSL_LIB_SPEC})

# Install shared libs.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${CRYPTO_LIB} ${CRYPTO_LIB_SPEC})
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${SSL_LIB} ${SSL_LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    SUBDIR openssl
    include/openssl/opensslconf.h
    FROM "${SOURCE_DIR}/include/openssl"
    aes.h asn1err.h asn1.h asn1_mac.h asn1t.h asyncerr.h async.h bioerr.h bio.h
    blowfish.h bnerr.h bn.h buffererr.h buffer.h camellia.h cast.h cmac.h
    cmserr.h cms.h comperr.h comp.h conf_api.h conferr.h conf.h cryptoerr.h
    crypto.h cterr.h ct.h des.h dherr.h dh.h dsaerr.h dsa.h dtls1.h ebcdic.h
    ecdh.h ecdsa.h ecerr.h ec.h engineerr.h engine.h e_os2.h err.h evperr.h
    evp.h hmac.h idea.h kdferr.h kdf.h lhash.h md2.h md4.h md5.h mdc2.h modes.h
    objectserr.h objects.h obj_mac.h ocsperr.h ocsp.h opensslv.h
    ossl_typ.h pem2.h pemerr.h pem.h pkcs12err.h pkcs12.h pkcs7err.h pkcs7.h
    rand_drbg.h randerr.h rand.h rc2.h rc4.h rc5.h ripemd.h rsaerr.h rsa.h
    safestack.h seed.h sha.h srp.h srtp.h ssl2.h ssl3.h sslerr.h ssl.h stack.h
    storeerr.h store.h symhacks.h tls1.h tserr.h ts.h txt_db.h uierr.h ui.h
    whrlpool.h x509err.h x509.h x509v3err.h x509v3.h x509_vfy.h
)

thirdparty_project(
    URL https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-1.1.1w.tar.gz
    https://www.openssl.org/source/old/1.1.1/openssl-1.1.1w.tar.gz
    URL_MD5 3f76825f195e52d4b10c70040681a275
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
