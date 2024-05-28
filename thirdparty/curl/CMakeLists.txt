cmake_minimum_required(VERSION 3.15)
project(curl LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

assert_var_defined(OPENSSL_DIR)
assert_var_defined(ZLIB_DIR)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH}
    # Gentoo patchset
    ${CMAKE_CURRENT_SOURCE_DIR}/curl-8.5.0-mpd-stream-http-adjust_pollset.patch
    # Need `-lrt` for `clock_gettime` support.
    ${CMAKE_CURRENT_SOURCE_DIR}/clock_gettime_needs_rt.patch
)
# NOTE: Because InkView is the worst, we rename our own cURL build on PocketBook.... (#5861)
if(POCKETBOOK)
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/pocketbook_lib_rename.patch)
endif()

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
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
    -DOpenSSL_ROOT=${OPENSSL_DIR}
    # ZLIB.
    -DCURL_ZLIB=TRUE
    -DZLIB_ROOT=${ZLIB_DIR}
)

# Don't use the default build system rule to create the certificates
# bundle: connections to `hg.mozilla.org` from CIs seem to be flaky,
# resulting in regular failures.
set(CA_BUNDLE_CMD ${CMAKE_CURRENT_LIST_DIR}/fetch-ca-bundle.sh ${DOWNLOAD_DIR}/ca-bundle.crt)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM} lib/all)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)
list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} -E copy ${DOWNLOAD_DIR}/ca-bundle.crt ${INSTALL_DIR}/ca-bundle.crt)
# Even after installing a patched pkg-config entry, we still need to add a symlink
# with the canonical library name or the mess that is CMake's FindCURl module will
# fail to detect our renamed library…
if(POCKETBOOK)
    list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} -E create_symlink libcurl_ko${LIB_EXT} ${INSTALL_DIR}/lib/libcurl${LIB_EXT})
endif()

external_project(
    URL https://github.com/curl/curl/releases/download/curl-8_5_0/curl-8.5.0.tar.xz
    URL_MD5 3e9e5c2db494e7dbd4e7024b149021c9
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)

ExternalProject_Add_Step(
    curl ca-bundle-download
    COMMAND ${CA_BUNDLE_CMD}
    COMMENT "Performing ca-bundle-download step for 'curl'"
    DEPENDERS download
)
