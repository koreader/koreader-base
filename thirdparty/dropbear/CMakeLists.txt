PROJECT(dropbear)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
enable_language(C)

assert_var_defined(LIBS)
assert_var_defined(LDFLAGS)
assert_var_defined(CPPFLAGS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_ENV_VAR "CC=\"${CC}\" CFLAGS=\"${CFLAGS} -I${SOURCE_DIR}\" LIBS=\"${LIBS}\"  CPPFLAGS=\"${CPPFLAGS}\" LDFLAGS=\"${LDFLAGS}\" ")
set(CFG_OPTS "-q --host=\"${CHOST}\" --disable-lastlog")
set(CFG_CMD "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")
set(CFG_CMD sh -c ${CFG_CMD})

include(ExternalProject)
set(DROPBEAR_VER "2018.76")
ExternalProject_Add(
    dropbear
    URL https://matt.ucc.asn.au/dropbear/releases/dropbear-${DROPBEAR_VER}.tar.bz2
    URL_MD5 c3912f7fcdcc57c99937e4a79480d2c2
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    PATCH_COMMAND COMMAND patch -N -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-nopasswd-hack.patch COMMAND patch -N -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-pubkey-hack.patch COMMAND patch -N -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-pubkey-gen-hack.patch COMMAND patch -N -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-pubkey2-gen-hack.patch
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS} strip MULTI=1 --silent
    INSTALL_COMMAND ""
)
