PROJECT(dropbear)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CPPFLAGS)
assert_var_defined(CFLAGS)
assert_var_defined(LIBS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)

set(PATCH_CMD1 "patch -N -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-nopasswd-hack.patch")
set(PATCH_CMD2 "patch -N -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-pubkey-hack.patch")
set(PATCH_CMD3 "patch -N -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-pubkey-gen-hack.patch")
set(PATCH_CMD4 "patch -N -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-nochdir-hack.patch")
set(PATCH_CMD5 "patch -N -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-options-hack.patch")

set(CFG_ENV_VAR "CC=\"${CC}\" CPPFLAGS=\"${CPPFLAGS}\ -I${SOURCE_DIR}\" CFLAGS=\"${CFLAGS}\" LIBS=\"${LIBS}\"  LDFLAGS=\"${LDFLAGS}\"")
set(CFG_OPTS "--host=\"${CHOST}\" --disable-lastlog --enable-zlib --enable-openpty --enable-shadow --enable-syslog --disable-harden")
set(CFG_CMD "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")
set(CFG_CMD sh -c ${CFG_CMD})

set(BUILD_CMD sh -c "$(MAKE) -j${PARALLEL_JOBS} strip MULTI=1")

include(ExternalProject)
set(DROPBEAR_VER "2018.76")
ExternalProject_Add(
    dropbear
    URL https://matt.ucc.asn.au/dropbear/releases/dropbear-${DROPBEAR_VER}.tar.bz2
    URL_MD5 c3912f7fcdcc57c99937e4a79480d2c2
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    PATCH_COMMAND COMMAND ${PATCH_CMD1} COMMAND ${PATCH_CMD2} COMMAND ${PATCH_CMD3} COMMAND ${PATCH_CMD4} COMMAND ${PATCH_CMD5}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ""
)
