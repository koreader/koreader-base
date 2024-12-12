list(APPEND PATCH_FILES
    # Gentoo patchset
    curl-8.5.0-mpd-stream-http-adjust_pollset.patch
    # Need `-lrt` for `clock_gettime` support.
    clock_gettime_needs_rt.patch
    # Use `-pthread` flag, not `-lpthread`
    # to avoid conflicts with OpenSSL.
    use_-pthread.patch
)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Build a static library, since there's only one user (zsync2).
    -DBUILD_SHARED_LIBS=FALSE
    # Project options.
    # TODO: Enable ZSTD support? We currently only use cURL
    # for zsync2, so, obviously, not necessary right now…
    -DBUILD_CURL_EXE=FALSE
    -DBUILD_TESTING=FALSE
    -DCURL_CA_BUNDLE=./data/ca-bundle.crt
    -DCURL_CA_FALLBACK=TRUE
    -DCURL_CA_PATH=/etc/ssl/certs
    -DCURL_DISABLE_GOPHER=TRUE
    -DCURL_DISABLE_LDAP=TRUE
    -DCURL_DISABLE_LDAPS=TRUE
    -DCURL_DISABLE_NTLM=TRUE
    -DCURL_DISABLE_SMB=TRUE
    -DCURL_USE_LIBPSL=FALSE
    -DCURL_USE_LIBSSH2=FALSE
    -DENABLE_MANUAL=FALSE
    -DUSE_LIBIDN2=FALSE
    # OpenSSL.
    -DCURL_DEFAULT_SSL_BACKEND=openssl
    -DCURL_USE_OPENSSL=TRUE
    # ZLIB.
    -DCURL_ZLIB=TRUE
)

list(APPEND BUILD_CMD COMMAND ninja lib/all)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_install_commands(INSTALL_CMD ${DOWNLOAD_DIR}/ca-bundle.crt DESTINATION data)

external_project(
    DOWNLOAD URL 3e9e5c2db494e7dbd4e7024b149021c9
    https://github.com/curl/curl/releases/download/curl-8_5_0/curl-8.5.0.tar.xz
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
