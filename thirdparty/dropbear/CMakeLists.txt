cmake_minimum_required(VERSION 3.5.1)
project(dropbear LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

assert_var_defined(CC)
assert_var_defined(CPPFLAGS)
assert_var_defined(CFLAGS)
assert_var_defined(LIBS)
assert_var_defined(LDFLAGS)
assert_var_defined(CHOST)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-nopasswd-hack.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-pubkey-hack.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-pubkey-gen-hack.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-nochdir-hack.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-options-hack.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-upstream-fixes.patch)
# This is pretty much platform-specific... Hard-coded paths and all that...
if(DEFINED ENV{KOBO})
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-scp-command-hack-kobo.patch)
elseif(DEFINED ENV{KINDLE})
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-scp-command-hack-kindle.patch)
elseif(DEFINED ENV{CERVANTES})
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-scp-command-hack-cervantes.patch)
elseif(DEFINED ENV{POCKETBOOK})
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-scp-command-hack-pocketbook.patch)
endif()
list(APPEND PATCH_CMD COMMAND autoreconf -fi)

set(CFG_ENV_VAR "CC=${CC}" "CPPFLAGS=${CPPFLAGS} -I${SOURCE_DIR}" "CFLAGS=${CFLAGS}" "LIBS=${LIBS}" "LDFLAGS=${LDFLAGS}")
set(CFG_OPTS --host=${CHOST} --disable-lastlog --enable-zlib --enable-openpty --enable-shadow --enable-syslog --disable-harden)
set(CFG_CMD env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

set(BUILD_CMD ${KO_MAKE_RECURSIVE} strip PROGRAMS=dropbear)

set(DROPBEAR_VER "2018.76")

external_project(
    URL http://deb.debian.org/debian/pool/main/d/dropbear/dropbear_${DROPBEAR_VER}.orig.tar.bz2
    URL_MD5 c3912f7fcdcc57c99937e4a79480d2c2
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
