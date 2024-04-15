cmake_minimum_required(VERSION 3.5.1)
project(curl LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(OPENSSL_DIR)
assert_var_defined(ZLIB_DIR)

# Gentoo patchset
list(APPEND PATCH_CMD COMMAND ${KO_PATCH}
    ${CMAKE_CURRENT_SOURCE_DIR}/curl-respect-cflags-3.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/curl-8.5.0-ipv6-configure-c99.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/curl-8.5.0-mpd-stream-http-adjust_pollset.patch
)
# NOTE: Because InkView is the worst, we rename our own cURL build on PocketBook.... (#5861)
if(POCKETBOOK)
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/curl-8.5.0-pb-rename.patch)
endif()

list(APPEND PATCH_CMD COMMAND ${ISED} "/LD_LIBRARY_PATH=/d" ${SOURCE_DIR}/configure.ac)
list(APPEND PATCH_CMD COMMAND ${ISED} "/CURL_MAC_CFLAGS/d" ${SOURCE_DIR}/configure.ac)
list(APPEND PATCH_CMD COMMAND autoreconf -v)

# Take a deep breath...
# TODO: Flip to --with-zstd? We currently only use cURL for zsync2, so, obviously, not necessary right now...
list(APPEND CFG_CMD COMMAND env
    CC=${CC}
    "CPPFLAGS=-I${ZLIB_DIR}/include -I${OPENSSL_DIR}/include"
    CFLAGS=${CFLAGS}
    "LDFLAGS=${LDFLAGS} -L${ZLIB_DIR}/lib -L${OPENSSL_DIR}"
    "LIBS=-lssl -lcrypto -lz -lrt"
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --enable-shared=yes --enable-static=no
    --disable-ares
    --disable-ech
    --disable-gopher
    --disable-ldap
    --disable-ldaps
    --disable-ntlm
    --disable-ntlm-wb
    --disable-smb
    --disable-sspi
    --enable-alt-svc
    --enable-aws
    --enable-basic-auth
    --enable-bearer-auth
    --enable-cookies
    --enable-dateparse
    --enable-dict
    --enable-digest-auth
    --enable-dnsshuffle
    --enable-doh
    --enable-file
    --enable-ftp
    --enable-hsts
    --enable-http
    --enable-http-auth
    --enable-imap
    --enable-ipv6
    --enable-kerberos-auth
    --enable-largefile
    --enable-manual
    --enable-mime
    --enable-negotiate-auth
    --enable-netrc
    --enable-pop3
    --enable-progress-meter
    --enable-proxy
    --enable-pthreads
    --enable-rt
    --enable-rtsp
    --enable-smtp
    --enable-socketpair
    --enable-symbol-hiding
    --enable-telnet
    --enable-tftp
    --enable-threaded-resolver
    --enable-tls-srp
    --enable-versioned-symbols
    --with-ca-bundle=./data/ca-bundle.crt
    --with-ca-fallback
    --with-ca-path=/etc/ssl/certs
    --with-default-ssl-backend=openssl
    --with-ssl
    --with-zlib
    --without-amissl
    --without-bearssl
    --without-brotli
    --without-fish-functions-dir
    --without-gnutls
    --without-gssapi
    --without-hyper
    --without-libgsasl
    --without-libidn2
    --without-libpsl
    --without-librtmp
    --without-libssh2
    --without-mbedtls
    --without-msh3
    --without-nghttp2
    --without-nghttp3
    --without-ngtcp2
    --without-quiche
    --without-rustls
    --without-schannel
    --without-secure-transport
    --without-test-caddy
    --without-test-httpd
    --without-test-nghttpx
    --without-websockets
    --without-winidn
    --without-wolfssl
    --without-zsh-functions-dir
    --without-zstd
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} ca-bundle)
list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C lib)

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} install)
list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} -E rename ${BINARY_DIR}/lib/ca-bundle.crt ${INSTALL_DIR}/ca-bundle.crt)

external_project(
    URL https://github.com/curl/curl/releases/download/curl-8_5_0/curl-8.5.0.tar.xz
    URL_MD5 3e9e5c2db494e7dbd4e7024b149021c9
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
