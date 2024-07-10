# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND BUILD_CMD
    make
    CC=${CC}
    CPPFLAGS=${CPPFLAGS}
    CFLAGS=${CFLAGS}
    LDFLAGS=${LDFLAGS}
    LUADIR=${LUAJIT_INC}
)

append_binary_install_command(INSTALL_CMD libopenlipclua.so DESTINATION common)

external_project(
    DOWNLOAD GIT b3fda88056a94526f53197948a47a4cdc23f8d16
    https://github.com/notmarek/openlipclua.git
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
