project(curl LANGUAGES)

# Don't recreate `ca-bundle.crt` every time.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/no_phony_business.patch)
list(APPEND PATCH_CMD COMMAND ${ISED} "/LD_LIBRARY_PATH=/d" ${SOURCE_DIR}/configure.ac)
list(APPEND PATCH_CMD COMMAND ${ISED} "/CURL_MAC_CFLAGS/d" ${SOURCE_DIR}/configure.ac)
list(APPEND PATCH_CMD COMMAND autoreconf -fi)

# Take a deep breath...
# TODO: Flip to --with-zstd? We currently only use cURL for zsync2, so, obviously, not necessary right now...
list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    "CPPFLAGS=-I${STAGING_DIR}/openssl/include -I${STAGING_DIR}/zlib/include"
    "LIBS=-L${STAGING_DIR}/openssl/shared -L${STAGING_DIR}/zlib/shared"
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --prefix=${BINARY_DIR} --libdir=${BINARY_DIR}/lib
    --enable-shared=no --enable-static=yes
    --disable-alt-svc
    --disable-ares
    --disable-ech
    --disable-ipv6
    --disable-ldap
    --disable-ldaps
    --disable-ntlm-wb
    --disable-smb
    --disable-sspi
    --enable-cookies
    --enable-crypto-auth
    --enable-dateparse
    --enable-dict
    --enable-dnsshuffle
    --enable-doh
    --enable-file
    --enable-ftp
    --enable-gopher
    --enable-hsts
    --enable-http
    --enable-http-auth
    --enable-imap
    --enable-largefile
    --enable-manual
    --enable-mime
    --enable-netrc
    --enable-pop3
    --enable-progress-meter
    --enable-proxy
    --enable-pthreads
    --enable-rt
    --enable-rtsp
    --enable-smtp
    --enable-symbol-hiding
    --enable-telnet -enable-tftp
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
    --without-cyassl
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
    --without-nghttp2
    --without-nghttp3
    --without-ngtcp2
    --without-nss
    --without-polarssl
    --without-quiche
    --without-rustls
    --without-schannel
    --without-secure-transport
    --without-spnego
    --without-winidn
    --without-winssl
    --without-wolfssl
    --without-zstd
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} lib/ca-bundle.crt)
list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C lib)

# Install certificates bundle.
append_install_command(INSTALL_CMD "lib/ca-bundle.crt" DESTINATION data/)

# Install static lib.
append_static_lib_install_command(INSTALL_CMD lib/.libs/libcurl.a curl)

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    SUBDIR curl
    "${SOURCE_DIR}/include/curl/*.h"
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/curl/curl.git
    tags/curl-7_80_0
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
