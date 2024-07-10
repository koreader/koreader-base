list(APPEND PATCH_FILES
    # Gentoo patchset
    curl-8.5.0-mpd-stream-http-adjust_pollset.patch
    # Need `-lrt` for `clock_gettime` support.
    clock_gettime_needs_rt.patch
)
# NOTE: Because InkView is the worst, we rename our own cURL build on PocketBook.... (#5861)
if(POCKETBOOK)
    list(APPEND PATCH_FILES pocketbook_lib_rename.patch)
endif()

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
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

if(POCKETBOOK)
    set(LIB_NAME curl_ko)
else()
    set(LIB_NAME curl)
endif()
append_shared_lib_install_commands(INSTALL_CMD ${LIB_NAME} VERSION 4)

# Even after installing a patched pkg-config entry, we still need to add a symlink
# with the canonical library name or the mess that is CMake's FindCURl module will
# fail to detect our renamed library…
if(POCKETBOOK)
    list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} -E create_symlink libcurl_ko${LIB_EXT} ${STAGING_DIR}/lib/libcurl${LIB_EXT})
endif()

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
