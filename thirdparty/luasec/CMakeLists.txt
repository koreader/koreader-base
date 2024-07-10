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
    make
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

external_project(
    DOWNLOAD GIT v1.3.2
    https://github.com/brunoos/luasec
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
