# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/luajit.patch)

string(JOIN " " DLLFLAGS ${DYNLIB_LDFLAGS} ${LUAJIT_LIB})

list(APPEND BUILD_CMD
    ${KO_MAKE_RECURSIVE}
    CC=${CC}
    COPT=${CFLAGS}
    DLLFLAGS=${DLLFLAGS}
    LUADIR=${LUAJIT_INC}
    lpeg.so
)

append_binary_install_command(INSTALL_CMD lpeg.so DESTINATION common)
append_install_commands(INSTALL_CMD re.lua DESTINATION common)

external_project(
    URL http://distcache.FreeBSD.org/ports-distfiles/lpeg-1.1.0.tar.gz
    URL_MD5 842a538b403b5639510c9b6fffd2c75b
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
