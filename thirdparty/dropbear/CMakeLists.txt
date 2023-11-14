project(dropbear LANGUAGES)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-nopasswd-hack.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-pubkey-hack.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-pubkey-gen-hack.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-nochdir-hack.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-kindle-options-hack.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-upstream-fixes.patch)

# This is pretty much platform-specific... Hard-coded paths and all that...
foreach(PLATFORM CERVANTES KINDLE KOBO POCKETBOOK)
    if(${PLATFORM})
        string(TOLOWER "${PLATFORM}" PLATFORM)
        list(APPEND PATCH_CMD COMMAND ${KO_PATCH} "${CMAKE_CURRENT_SOURCE_DIR}/dropbear-2018.76-scp-command-hack-${PLATFORM}.patch")
        break()
    endif()
endforeach()

list(APPEND PATCH_CMD COMMAND autoreconf -fi)

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    "CPPFLAGS=-I${STAGING_DIR}/zlib/include"
    "LIBS=-L${STAGING_DIR}/zlib/shared"
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --disable-harden
    --disable-lastlog
    --enable-openpty
    --enable-shadow
    --enable-syslog
    --enable-zlib
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} strip PROGRAMS=dropbear)

# Install executable.
append_install_command(INSTALL_CMD dropbear)

set(DROPBEAR_VER "2018.76")

thirdparty_project(
    URL http://deb.debian.org/debian/pool/main/d/dropbear/dropbear_${DROPBEAR_VER}.orig.tar.bz2
    URL_MD5 c3912f7fcdcc57c99937e4a79480d2c2
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
