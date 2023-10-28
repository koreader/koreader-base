cmake_minimum_required(VERSION 3.5.1)
project(curl)

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
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/curl-7.78.0-pb-rename.patch)
endif()

list(APPEND PATCH_CMD COMMAND ${ISED} "/LD_LIBRARY_PATH=/d" ${SOURCE_DIR}/configure.ac)
list(APPEND PATCH_CMD COMMAND ${ISED} "/CURL_MAC_CFLAGS/d" ${SOURCE_DIR}/configure.ac)
list(APPEND PATCH_CMD COMMAND ./buildconf)

set(CFG_ENV_VAR "CC=${CC}" "CPPFLAGS=${CPPFLAGS}" "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}")
# Take a deep breath...
# TODO: Flip to --with-zstd? We currently only use cURL for zsync2, so, obviously, not necessary right now...
set(CFG_OPTS --prefix=${BINARY_DIR} --libdir=${BINARY_DIR}/lib --host=${CHOST} --enable-shared=yes --enable-static=no --without-gnutls --without-mbedtls --without-nss --without-polarssl --without-winssl --with-ca-fallback --with-ca-bundle=./data/ca-bundle.crt --with-ssl --with-ca-path=/etc/ssl/certs --with-default-ssl-backend=openssl --disable-alt-svc --enable-crypto-auth --enable-dict --disable-ech --enable-file --enable-ftp --enable-gopher --enable-hsts --enable-http --enable-imap --disable-ldap --disable-ldaps --disable-ntlm-wb --enable-pop3 --enable-rt --enable-rtsp --disable-smb --without-libssh2 --enable-smtp --enable-telnet -enable-tftp --enable-tls-srp --disable-ares --enable-cookies --enable-dateparse --enable-dnsshuffle --enable-doh --enable-symbol-hiding --enable-http-auth --disable-ipv6 --enable-largefile --enable-manual --enable-mime --enable-netrc --enable-progress-meter --enable-proxy --disable-sspi --enable-threaded-resolver --enable-pthreads --enable-versioned-symbols --without-amissl --without-bearssl --without-brotli --without-cyassl --without-fish-functions-dir --without-nghttp2 --without-hyper --without-libidn2 --without-gssapi --without-libgsasl --without-libpsl --without-nghttp3 --without-ngtcp2 --without-quiche --without-librtmp --without-rustls --without-schannel --without-secure-transport --without-spnego --without-winidn --without-wolfssl --with-zlib --without-zstd)
list(APPEND CFG_CMD COMMAND env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} ca-bundle)
list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} install)
list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/lib/ca-bundle.crt ${BINARY_DIR}/ca-bundle.crt)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/curl/curl.git
    tags/curl-7_80_0
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND COMMAND ${BUILD_CMD}
    INSTALL_COMMAND COMMAND ${INSTALL_CMD}
)
