project(dropbear)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CPPFLAGS)
assert_var_defined(CFLAGS)
assert_var_defined(LIBS)
assert_var_defined(LDFLAGS)
assert_var_defined(CHOST)

ep_get_source_dir(SOURCE_DIR)

set(PATCH_CMD1 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-nopasswd-hack.patch")
set(PATCH_CMD2 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-pubkey-hack.patch")
set(PATCH_CMD3 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-pubkey-gen-hack.patch")
set(PATCH_CMD4 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-nochdir-hack.patch")
set(PATCH_CMD5 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-options-hack.patch")
set(PATCH_CMD6 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-upstream-fixes.patch")
# This is pretty much platform-specific... Hard-coded paths and all that...
if(DEFINED ENV{KOBO})
    set(PATCH_CMD7 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-scp-command-hack-kobo.patch")
elseif(DEFINED ENV{KINDLE})
    set(PATCH_CMD7 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-scp-command-hack-kindle.patch")
elseif(DEFINED ENV{CERVANTES})
    set(PATCH_CMD7 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-scp-command-hack-cervantes.patch")
elseif(DEFINED ENV{POCKETBOOK})
    set(PATCH_CMD7 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-scp-command-hack-pocketbook.patch")
endif()
set(PATCH_CMD8 sh -c "autoreconf -fi")

set(CFG_ENV_VAR "CC=${CC}" "CPPFLAGS=${CPPFLAGS} -I${SOURCE_DIR}" "CFLAGS=${CFLAGS}" "LIBS=${LIBS}" "LDFLAGS=${LDFLAGS}")
set(CFG_OPTS --host=${CHOST} --disable-lastlog --enable-zlib --enable-openpty --enable-shadow --enable-syslog --disable-harden)
set(CFG_CMD env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

set(BUILD_CMD ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} strip PROGRAMS=dropbear)

include(ExternalProject)
set(DROPBEAR_VER "2018.76")
ExternalProject_Add(
    ${PROJECT_NAME}
    URL http://deb.debian.org/debian/pool/main/d/dropbear/dropbear_${DROPBEAR_VER}.orig.tar.bz2
    URL_MD5 c3912f7fcdcc57c99937e4a79480d2c2
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    PATCH_COMMAND COMMAND ${PATCH_CMD1} COMMAND ${PATCH_CMD2} COMMAND
    ${PATCH_CMD3} COMMAND ${PATCH_CMD4} COMMAND ${PATCH_CMD5} COMMAND ${PATCH_CMD6} COMMAND ${PATCH_CMD7} COMMAND ${PATCH_CMD8}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ""
)
