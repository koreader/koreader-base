cmake_minimum_required(VERSION 3.15)
project(dropbear LANGUAGES)

include(koreader_thirdparty_common)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH}
    ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-nopasswd-hack.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-pubkey-hack.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-pubkey-gen-hack.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-nochdir-hack.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-options-hack.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-upstream-fixes.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/reduce_build_verbosity.patch
)
# This is pretty much platform-specific... Hard-coded paths and all that...
foreach(PLATFORM CERVANTES KINDLE KOBO POCKETBOOK)
    if(${PLATFORM})
        string(TOLOWER ${PLATFORM} PLATFORM)
        list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-scp-command-hack-${PLATFORM}.patch)
        break()
    endif()
endforeach()

list(APPEND PATCH_CMD COMMAND autoreconf -v)

if(ANDROID)
    set(LIBS -static)
else()
    set(LIBS)
endif()

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    ${SOURCE_DIR}/configure --host=${CHOST}
    --disable-harden
    --disable-lastlog
    --enable-openpty
    --enable-shadow
    --enable-syslog
    --enable-zlib
    --with-zlib=${STAGING_DIR}
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} strip PROGRAMS=dropbear)

external_project(
    URL http://deb.debian.org/debian/pool/main/d/dropbear/dropbear_2018.76.orig.tar.bz2
    URL_MD5 c3912f7fcdcc57c99937e4a79480d2c2
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
