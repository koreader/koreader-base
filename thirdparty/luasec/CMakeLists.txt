# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

string(APPEND CFLAGS " -DWITH_LUASOCKET -I. -I${LUAJIT_INC} -I${STAGING_DIR}/include")

string(JOIN " " LIBS
    luasocket/libluasocket.a
    ${STAGING_DIR}/lib/libcrypto${LIB_EXT}
    ${STAGING_DIR}/lib/libssl${LIB_EXT}
    ${LUAJIT_LIB}
)

set(MAKE_CMD
    ${KO_MAKE_RECURSIVE}
    AR=${AR} RANLIB=${RANLIB}
    CC=${CC} CFLAGS=${CFLAGS}
    LDFLAGS=${DYNLIB_LDFLAGS}
    LIBS=${LIBS} EXTRA=${LIBS}
)

list(APPEND BUILD_CMD COMMAND ${MAKE_CMD} -C src/luasocket)
list(APPEND BUILD_CMD COMMAND ${MAKE_CMD} -C src ssl.so)

append_binary_install_command(INSTALL_CMD src/ssl.so DESTINATION common)
append_install_commands(INSTALL_CMD src/ssl.lua DESTINATION common)
append_install_commands(INSTALL_CMD src/https.lua DESTINATION common/ssl)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/brunoos/luasec
    tags/v1.3.2
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
