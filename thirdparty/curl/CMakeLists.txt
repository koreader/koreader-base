# Gentoo patchset
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/curl-8.5.0-mpd-stream-http-adjust_pollset.patch)
# NOTE: Because InkView is the worst, we rename our own cURL build on PocketBook.... (#5861)
if(POCKETBOOK)
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/pocketbook_lib_rename.patch)
endif()
# Need `-lrt` for `clock_gettime` support.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/clock_gettime_needs_rt.patch)
# Add a target for building the certificates bundle.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/ca_bundle.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}")

# Features.
# TODO: Enable ZSTD support? We currently only use cURL for zsync2, so, obviously, not necessary right now…
list(APPEND CMAKE_ARGS "-DBUILD_CURL_EXE=FALSE")
list(APPEND CMAKE_ARGS "-DBUILD_TESTING=FALSE")
list(APPEND CMAKE_ARGS "-DCURL_CA_BUNDLE=./data/ca-bundle.crt")
list(APPEND CMAKE_ARGS "-DCURL_CA_FALLBACK=TRUE")
list(APPEND CMAKE_ARGS "-DCURL_CA_PATH=/etc/ssl/certs")
list(APPEND CMAKE_ARGS "-DCURL_DISABLE_GOPHER=TRUE")
list(APPEND CMAKE_ARGS "-DCURL_DISABLE_LDAP=TRUE")
list(APPEND CMAKE_ARGS "-DCURL_DISABLE_LDAPS=TRUE")
list(APPEND CMAKE_ARGS "-DCURL_DISABLE_NTLM=TRUE")
list(APPEND CMAKE_ARGS "-DCURL_DISABLE_SMB=TRUE")
list(APPEND CMAKE_ARGS "-DCURL_USE_LIBPSL=FALSE")
list(APPEND CMAKE_ARGS "-DCURL_USE_LIBSSH2=FALSE")
list(APPEND CMAKE_ARGS "-DENABLE_MANUAL=FALSE")
list(APPEND CMAKE_ARGS "-DUSE_LIBIDN2=FALSE")

# OpenSSL.
list(APPEND CMAKE_ARGS "-DCURL_DEFAULT_SSL_BACKEND=openssl")
list(APPEND CMAKE_ARGS "-DCURL_USE_OPENSSL=TRUE")

# ZLIB.
list(APPEND CMAKE_ARGS "-DCURL_ZLIB=TRUE")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM} ca-bundle lib/all)

# Install certificates bundle.
append_install_commands(INSTALL_CMD BYPRODUCTS ca-bundle.crt DESTINATION data/)

if(POCKETBOOK)
    set(LIB_SPEC curl_ko VERSION 4)
else()
    set(LIB_SPEC curl VERSION 4)
endif()
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS lib/${LIB} ${LIB_SPEC})

# Even with after installing a patched pkg-config entry, we still need to add a symlink
# with the canonical library name or the mess that is CMake's FindCURl module will fail
# at detecting our renamed library…
if(POCKETBOOK)
    list(APPEND INSTALL_CMD COMMAND ln -snf ${LIB} "${STAGING_DIR}/lib/libcurl${LIB_EXT}")
endif()

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    SUBDIR curl
    FROM "${SOURCE_DIR}/include/curl"
    curl.h curlver.h easy.h header.h mprintf.h multi.h options.h
    stdcheaders.h system.h typecheck-gcc.h urlapi.h websockets.h
)

# Install pkg-config entry (needed for curl components detection by CMake's FindCURl).
append_install_commands(INSTALL_CMD BYPRODUCTS libcurl.pc DESTINATION "${STAGING_DIR}/lib/pkgconfig/")

thirdparty_project(
    URL https://github.com/curl/curl/releases/download/curl-8_5_0/curl-8.5.0.tar.xz
    URL_MD5 3e9e5c2db494e7dbd4e7024b149021c9
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
