cmake_minimum_required(VERSION 3.5.1)
project(curl LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CPPFLAGS)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(CHOST)

# Gentoo patchset
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/curl-respect-cflags-3.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/curl-8.5.0-ipv6-configure-c99.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/curl-8.5.0-mpd-stream-http-adjust_pollset.patch)
# NOTE: Because InkView is the worst, we rename our own cURL build on PocketBook.... (#5861)
if(DEFINED ENV{POCKETBOOK})
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/curl-8.5.0-pb-rename.patch)
endif()

list(APPEND PATCH_CMD COMMAND ${ISED} "/LD_LIBRARY_PATH=/d" ${SOURCE_DIR}/configure.ac)
list(APPEND PATCH_CMD COMMAND ${ISED} "/CURL_MAC_CFLAGS/d" ${SOURCE_DIR}/configure.ac)
list(APPEND PATCH_CMD COMMAND autoreconf -fi)

set(CFG_ENV_VAR "CC=${CC}" "CPPFLAGS=${CPPFLAGS}" "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}")

# Take a deep breath...
list(APPEND CFG_OPTS --prefix=${INSTALL_DIR} --host=${CHOST} --enable-shared=yes --enable-static=no)
list(APPEND CFG_OPTS --with-ca-fallback --with-ca-bundle=./data/ca-bundle.crt)
list(APPEND CFG_OPTS --without-gnutls --without-mbedtls --without-rustls)
list(APPEND CFG_OPTS --with-ssl --with-ca-path=/etc/ssl/certs)
list(APPEND CFG_OPTS --with-default-ssl-backend=openssl)
list(APPEND CFG_OPTS --enable-alt-svc)
list(APPEND CFG_OPTS --enable-basic-auth)
list(APPEND CFG_OPTS --enable-bearer-auth)
list(APPEND CFG_OPTS --enable-digest-auth)
list(APPEND CFG_OPTS --enable-kerberos-auth)
list(APPEND CFG_OPTS --enable-negotiate-auth)
list(APPEND CFG_OPTS --enable-aws)
list(APPEND CFG_OPTS --enable-dict)
list(APPEND CFG_OPTS --disable-ech)
list(APPEND CFG_OPTS --enable-file)
list(APPEND CFG_OPTS --enable-ftp)
list(APPEND CFG_OPTS --disable-gopher)
list(APPEND CFG_OPTS --enable-hsts)
list(APPEND CFG_OPTS --enable-http)
list(APPEND CFG_OPTS --enable-imap)
list(APPEND CFG_OPTS --disable-ldap)
list(APPEND CFG_OPTS --disable-ldaps)
list(APPEND CFG_OPTS --disable-ntlm)
list(APPEND CFG_OPTS --disable-ntlm-wb)
list(APPEND CFG_OPTS --enable-pop3)
list(APPEND CFG_OPTS --enable-rt)
list(APPEND CFG_OPTS --enable-rtsp)
list(APPEND CFG_OPTS --disable-smb)
list(APPEND CFG_OPTS --without-libssh2)
list(APPEND CFG_OPTS --enable-smtp)
list(APPEND CFG_OPTS --enable-telnet)
list(APPEND CFG_OPTS --enable-tftp)
list(APPEND CFG_OPTS --enable-tls-srp)
list(APPEND CFG_OPTS --disable-ares)
list(APPEND CFG_OPTS --enable-cookies)
list(APPEND CFG_OPTS --enable-dateparse)
list(APPEND CFG_OPTS --enable-dnsshuffle)
list(APPEND CFG_OPTS --enable-doh)
list(APPEND CFG_OPTS --enable-symbol-hiding)
list(APPEND CFG_OPTS --enable-http-auth)
list(APPEND CFG_OPTS --enable-ipv6)
list(APPEND CFG_OPTS --enable-largefile)
list(APPEND CFG_OPTS --enable-manual)
list(APPEND CFG_OPTS --enable-mime)
list(APPEND CFG_OPTS --enable-netrc)
list(APPEND CFG_OPTS --enable-progress-meter)
list(APPEND CFG_OPTS --enable-proxy)
list(APPEND CFG_OPTS --enable-socketpair)
list(APPEND CFG_OPTS --disable-sspi)
list(APPEND CFG_OPTS --enable-pthreads)
list(APPEND CFG_OPTS --enable-threaded-resolver)
list(APPEND CFG_OPTS --enable-versioned-symbols)
list(APPEND CFG_OPTS --without-amissl)
list(APPEND CFG_OPTS --without-bearssl)
list(APPEND CFG_OPTS --without-brotli)
list(APPEND CFG_OPTS --without-fish-functions-dir)
list(APPEND CFG_OPTS --without-nghttp2)
list(APPEND CFG_OPTS --without-hyper)
list(APPEND CFG_OPTS --without-libidn2)
list(APPEND CFG_OPTS --without-gssapi)
list(APPEND CFG_OPTS --without-libgsasl)
list(APPEND CFG_OPTS --without-libpsl)
list(APPEND CFG_OPTS --without-msh3)
list(APPEND CFG_OPTS --without-nghttp3)
list(APPEND CFG_OPTS --without-ngtcp2)
list(APPEND CFG_OPTS --without-quiche)
list(APPEND CFG_OPTS --without-librtmp)
list(APPEND CFG_OPTS --without-schannel)
list(APPEND CFG_OPTS --without-secure-transport)
list(APPEND CFG_OPTS --without-test-caddy)
list(APPEND CFG_OPTS --without-test-httpd)
list(APPEND CFG_OPTS --without-test-nghttpx)
list(APPEND CFG_OPTS --without-websockets)
list(APPEND CFG_OPTS --without-winidn)
list(APPEND CFG_OPTS --without-wolfssl)
list(APPEND CFG_OPTS --with-zlib)
# TODO: Flip to --with-zstd? We currently only use cURL for zsync2, so, obviously, not necessary right now...
list(APPEND CFG_OPTS --without-zstd)
list(APPEND CFG_OPTS --without-zsh-functions-dir)

list(APPEND CFG_CMD COMMAND env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

# Don't use the default build system rule to create the certificates
# bundle: connections to `hg.mozilla.org` from CIs seem to be flaky,
# resulting in regular failures.
set(CA_BUNDLE_CMD ${CMAKE_CURRENT_LIST_DIR}/fetch-ca-bundle.sh ${DOWNLOAD_DIR}/ca-bundle.crt)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} install)
list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} -E copy ${DOWNLOAD_DIR}/ca-bundle.crt ${INSTALL_DIR}/ca-bundle.crt)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/curl/curl.git
    tags/curl-8_5_0
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME} COMMAND ${CA_BUNDLE_CMD}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
