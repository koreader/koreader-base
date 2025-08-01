# This is pretty much platform-specific... Hard-coded paths and all that...
if(CERVANTES)
    set(PLATFORM_KOREADER_DIR "/mnt/private/koreader")
elseif(KINDLE)
    set(PLATFORM_KOREADER_DIR "/mnt/us/koreader")
elseif(KOBO)
    set(PLATFORM_KOREADER_DIR "/mnt/onboard/.adds/koreader")
elseif(POCKETBOOK)
    set(PLATFORM_KOREADER_DIR "/mnt/ext1/applications/koreader")
else()
    set(PLATFORM_KOREADER_DIR)
endif()

# Increase the number for higher verbosity.
set(DEBUG_TRACE 1)
set(DROPBEAR_DEFPORT "2222")
set(DROPBEAR_SMALL_CODE TRUE)
set(DROPBEAR_X11FWD TRUE)
set(INETD_MODE FALSE)
# NOTE: Consider enabling this to debug our crazy scp/sftp hack...
set(LOG_COMMANDS FALSE)
# Paths.
set(DEFAULT_PATH "/sbin:/usr/sbin:/bin:/usr/bin")
set(DROPBEAR_PIDFILE "settings/SSH/dropbear.pid")
if(PLATFORM_KOREADER_DIR)
    set(DBSCP_PATH ${PLATFORM_KOREADER_DIR})
    set(DROPBEAR_PATH_SSH_PROGRAM "${PLATFORM_KOREADER_DIR}/dbclient")
    set(SFTPSERVER_PATH "${PLATFORM_KOREADER_DIR}/sftp-server")
endif()
# Keys.
set(DSS_PRIV_FILENAME "settings/SSH/dropbear_dss_host_key")
set(RSA_PRIV_FILENAME "settings/SSH/dropbear_rsa_host_key")
set(ECDSA_PRIV_FILENAME "settings/SSH/dropbear_ecdsa_host_key")
set(ED25519_PRIV_FILENAME "settings/SSH/dropbear_ed25519_host_key")

configure_file(localoptions.h.cmake ${CMAKE_CURRENT_BINARY_DIR}/localoptions.h ESCAPE_QUOTES)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/localoptions.h)

list(APPEND PATCH_FILES
    dbscp-path.patch
    nochdir-hack.patch
    nopasswd-hack.patch
    pubkey-hack.patch
    reduce_build_verbosity.patch
    fix__GNU_SOURCE_warnings.patch
)

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
list(APPEND CFG_CMD COMMAND ${CMAKE_COMMAND} -E create_symlink ${CMAKE_CURRENT_BINARY_DIR}/localoptions.h localoptions.h)

set(PROGRAMS dbclient dropbear scp)

list(APPEND BUILD_CMD make ${PROGRAMS})

append_binary_install_command(INSTALL_CMD ${PROGRAMS})

external_project(
    DOWNLOAD URL 327e7deca6ce7c18b1f259dbf40021bd
    https://github.com/mkj/dropbear/archive/refs/tags/DROPBEAR_2025.88.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/localoptions.h
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
