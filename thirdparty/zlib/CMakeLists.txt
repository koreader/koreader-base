cmake_minimum_required(VERSION 3.5.1)
project(zlib LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

# Whelp, apparently the 1.2.12 release was a fun one, so apply the full Gentoo patchset...
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zlib-1.2.11-minizip-drop-crypt-header.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zlib-1.2.11-configure-fix-AR-RANLIB-NM-detection.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zlib-1.2.13-use-LDFLAGS-in-configure.patch)

if(DEFINED ENV{ANDROID})
    assert_var_defined(CHOST)

    set(LDFLAGS "${LDFLAGS} -shared -Wl,-soname,libz.so.1")
    # Only set CHOST for Android.
    # This can't be done generically because otherwise you have to specify soname as well.
    # See <https://github.com/koreader/koreader/issues/3523>.
    set(CFG_ENV_VAR ${CFG_ENV_VAR} "CHOST=${CHOST}")
endif()

# configure
set(CFG_ENV_VAR ${CFG_ENV_VAR} "CC=${CC}" "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}")
set(CFG_OPTS ${CFG_OPTS} --prefix=${INSTALL_DIR})
set(CFG_CMD env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})
# build
set(BUILD_CMD ${KO_MAKE_RECURSIVE} shared static)
# install
list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} install)
list(APPEND INSTALL_CMD COMMAND mkdir -p ${INSTALL_DIR}/include/contrib/minizip)
list(APPEND INSTALL_CMD COMMAND cp contrib/minizip/crypt.h ${INSTALL_DIR}/include/contrib/minizip/)

set(ZLIB_VER "1.3")
set(ZLIB_MD5 "b49e70aacafacfceb1107943497f5545")

external_project(
    URL https://github.com/madler/zlib/releases/download/v${ZLIB_VER}/zlib-${ZLIB_VER}.tar.xz
    URL_MD5 ${ZLIB_MD5}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
