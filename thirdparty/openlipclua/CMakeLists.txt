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
    b276ba499cae9a2a6a1f7ceb86f4f500d668d893
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
