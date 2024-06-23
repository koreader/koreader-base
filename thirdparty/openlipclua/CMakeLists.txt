# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND BUILD_CMD
    ${KO_MAKE_RECURSIVE}
    CC=${CC}
    CPPFLAGS=${CPPFLAGS}
    CFLAGS=${CFLAGS}
    LDFLAGS=${LDFLAGS}
    LUADIR=${LUAJIT_INC}
)

append_binary_install_command(INSTALL_CMD libopenlipclua.so DESTINATION common)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/notmarek/openlipclua.git
    93b6b6f4a24bc2e8d10fb41e3239b6d5736fca23
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
