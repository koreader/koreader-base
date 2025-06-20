list(APPEND PATCH_FILES
    # Need `-lrt` for `clock_gettime` support.
    clock_gettime_needs_rt.patch
    # Use `-pthread` flag, not `-lpthread`
    # to avoid conflicts with OpenSSL.
    use_-pthread.patch
)
if(LEGACY OR POCKETBOOK)
    # Avoid pulling-in `eventfd@GLIBC_2.7` or `pipe2@GLIBC_2.9`.
    list(APPEND PATCH_FILES no_glibc_2.6_or_above_symbols.patch)
endif()

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Build a static library, since there's only one user (zsync2).
    -DBUILD_SHARED_LIBS=FALSE
    # Project options.
    # TODO: Enable ZSTD support? We currently only use cURL
    # for zsync2, so, obviously, not necessary right now…
    -DBUILD_CURL_EXE=FALSE
    -DBUILD_LIBCURL_DOCS=FALSE
    -DBUILD_TESTING=FALSE
    -DCURL_CA_BUNDLE=./data/ca-bundle.crt
    -DCURL_CA_FALLBACK=TRUE
    -DCURL_CA_PATH=/etc/ssl/certs
    -DCURL_DISABLE_ALTSVC=TRUE
    -DCURL_DISABLE_AWS=TRUE
    -DCURL_DISABLE_COOKIES=TRUE
    -DCURL_DISABLE_DICT=TRUE
    -DCURL_DISABLE_DOH=TRUE
    -DCURL_DISABLE_FILE=TRUE
    -DCURL_DISABLE_FORM_API=TRUE
    -DCURL_DISABLE_FTP=TRUE
    -DCURL_DISABLE_GOPHER=TRUE
    -DCURL_DISABLE_HSTS=TRUE
    -DCURL_DISABLE_IMAP=TRUE
    -DCURL_DISABLE_IPFS=TRUE
    -DCURL_DISABLE_LDAP=TRUE
    -DCURL_DISABLE_LDAPS=TRUE
    -DCURL_DISABLE_MIME=TRUE
    -DCURL_DISABLE_MQTT=TRUE
    -DCURL_DISABLE_NETRC=TRUE
    -DCURL_DISABLE_NTLM=TRUE
    -DCURL_DISABLE_POP3=TRUE
    -DCURL_DISABLE_PROGRESS_METER=TRUE
    -DCURL_DISABLE_RTSP=TRUE
    -DCURL_DISABLE_SHUFFLE_DNS=TRUE
    -DCURL_DISABLE_SMB=TRUE
    -DCURL_DISABLE_SMTP=TRUE
    -DCURL_DISABLE_TELNET=TRUE
    -DCURL_DISABLE_TFTP=TRUE
    -DCURL_DISABLE_VERBOSE_STRINGS=$<NOT:$<STREQUAL:${CMAKE_BUILD_TYPE},Debug>>
    -DCURL_DISABLE_WEBSOCKETS=TRUE
    -DCURL_USE_LIBPSL=FALSE
    -DCURL_USE_LIBSSH2=FALSE
    -DENABLE_CURL_MANUAL=FALSE
    -DUSE_LIBIDN2=FALSE
    -DUSE_NGHTTP2=FALSE
    # Brotli.
    -DCURL_BROTLI=FALSE
    # OpenSSL.
    -DCURL_DEFAULT_SSL_BACKEND=openssl
    -DCURL_USE_OPENSSL=TRUE
    # ZLIB.
    -DCURL_ZLIB=TRUE
    # ZSTD.
    -DCURL_ZSTD=FALSE
)

list(APPEND BUILD_CMD COMMAND ninja lib/all)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_install_commands(INSTALL_CMD ${DOWNLOAD_DIR}/ca-bundle.crt DESTINATION data)

external_project(
    DOWNLOAD URL cba9ea54bccefed639a529b1b5b17405
    https://github.com/curl/curl/releases/download/curl-8_14_1/curl-8.14.1.tar.xz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)

# Don't use the default build system rule to create the certificates
# bundle: connections to `hg.mozilla.org` from CIs seem to be flaky,
# resulting in regular failures.
external_project_step(
    download-ca-bundle BEFORE download
    COMMENT "Fetching certificates bundles for '${PROJECT_NAME}'"
    COMMAND ${CMAKE_CURRENT_LIST_DIR}/fetch-ca-bundle.sh ${DOWNLOAD_DIR}/ca-bundle.crt
)
