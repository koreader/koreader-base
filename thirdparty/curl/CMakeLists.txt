project(curl)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CPPFLAGS)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(CHOST)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# NOTE: Because InkView is the worst, we rename our own cURL build on PocketBook.... (#5861)
if(DEFINED ENV{POCKETBOOK})
    set(PATCH_CMD0 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/curl-7.78.0-pb-rename.patch")
endif()

set(PATCH_CMD1 sh -c "${ISED} '/LD_LIBRARY_PATH=/d' ${SOURCE_DIR}/configure.ac")
set(PATCH_CMD2 sh -c "${ISED} '/CURL_MAC_CFLAGS/d' ${SOURCE_DIR}/configure.ac")
set(PATCH_CMD3 sh -c "./buildconf")

set(CFG_ENV_VAR "CC=\"${CC}\" CPPFLAGS=\"${CPPFLAGS}\" CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\"")
# Take a deep breath...
# TODO: Flip to --with-zstd? We currently only use cURL for zsync2, so, obviously, not necessary right now...
set(CFG_OPTS "--prefix=\"${BINARY_DIR}\" --host=\"${CHOST}\" --enable-shared=yes --enable-static=no --without-gnutls --without-mbedtls --without-nss --without-polarssl --without-winssl --with-ca-fallback --with-ca-bundle=./data/ca-bundle.crt --with-ssl --with-ca-path=/etc/ssl/certs --with-default-ssl-backend=openssl --disable-alt-svc --enable-crypto-auth --enable-dict --disable-ech --enable-file --enable-ftp --enable-gopher --enable-hsts --enable-http --enable-imap --disable-ldap --disable-ldaps --disable-ntlm-wb --enable-pop3 --enable-rt --enable-rtsp --disable-smb --without-libssh2 --enable-smtp --enable-telnet -enable-tftp --enable-tls-srp --disable-ares --enable-cookies --enable-dateparse --enable-dnsshuffle --enable-doh --enable-hidden-symbols --enable-http-auth --disable-ipv6 --enable-largefile --enable-manual --enable-mime --enable-netrc --enable-progress-meter --enable-proxy --disable-sspi --enable-threaded-resolver --enable-pthreads --enable-versioned-symbols --without-amissl --without-bearssl --without-brotli --without-cyassl --without-fish-functions-dir --without-nghttp2 --without-hyper --without-libidn2 --without-gssapi --without-libgsasl --without-libpsl --without-nghttp3 --without-ngtcp2 --without-quiche --without-librtmp --without-rustls --without-schannel --without-secure-transport --without-spnego --without-winidn --without-wolfssl --with-zlib --without-zstd")
set(CFG_CMD "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")
set(CFG_CMD sh -c "${CFG_CMD}")
set(BUILD_CMD1 sh -c "${KO_MAKE_RECURSIVE} ca-bundle")
set(BUILD_CMD2 sh -c "${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}")
set(INSTALL_CMD1 sh -c "${KO_MAKE_RECURSIVE} install")
set(INSTALL_CMD2 ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/lib/ca-bundle.crt ${BINARY_DIR}/ca-bundle.crt)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/curl/curl.git
    tags/curl-7_79_1
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND COMMAND ${PATCH_CMD0} COMMAND ${PATCH_CMD1} COMMAND ${PATCH_CMD2} COMMAND ${PATCH_CMD3}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND COMMAND ${BUILD_CMD1} COMMAND ${BUILD_CMD2}
    INSTALL_COMMAND COMMAND ${INSTALL_CMD1} COMMAND ${INSTALL_CMD2}
)
