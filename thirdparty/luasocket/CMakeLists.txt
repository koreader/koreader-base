# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

if(NOT ANDROID)
    # Make sure socket fds are CLOEXEC on *nix.
    list(APPEND PATCH_FILES luasocket-enforce-cloexec.patch)
endif()

# Rename modules:
# `mime.core` → `mime.mcore`
# `socket.core` → `socket.score`
list(APPEND PATCH_CMD COMMAND sh -c "\"\$@\" src/*" --
    ${ISED} " "
    -e "s|socket\\.core|socket.score|g"
    -e "s|socket_core|socket_score|g"
    -e "s|mime\\.core|mime.mcore|g"
    -e "s|mime_core|mime_mcore|g"
    -e "s|SOCKET_CDIR)/core|SOCKET_CDIR)/score|"
    -e "s|MIME_CDIR)/core|MIME_CDIR)/mcore|"
)

# Don't enforce CFLAGS.
list(APPEND PATCH_CMD COMMAND ${ISED} "s|-O2 -ggdb3 ||g" src/makefile)

if(APPLE)
    set(PLAT macosx)
elseif(WIN32)
    set(PLAT mingw)
else()
    set(PLAT linux)
endif()

string(JOIN " " MYLDFLAGS ${LDFLAGS} ${LUAJIT_LIB})

list(APPEND BUILD_CMD COMMAND
    make
    "CC=${CC} ${CFLAGS}"
    "LD=${CC} ${CFLAGS}"
    LUAINC=${LUAJIT_INC}
    MYLDFLAGS=${MYLDFLAGS}
    PLAT=${PLAT}
    SOCKET_SO=score.so MIME_SO=mcore.so
)

append_install_commands(
    INSTALL_CMD
    src/ltn12.lua src/mime.lua src/socket.lua
    DESTINATION common
)
append_install_commands(
    INSTALL_CMD
    src/ftp.lua src/headers.lua src/http.lua
    src/smtp.lua src/tp.lua src/url.lua
    DESTINATION common/socket
)
append_binary_install_command(INSTALL_CMD src/score.so DESTINATION common/socket)
append_binary_install_command(INSTALL_CMD src/mcore.so DESTINATION common/mime)

external_project(
    DOWNLOAD GIT e3ca4a767a68d127df548d82669aba3689bd84f4
    https://github.com/lunarmodules/luasocket
    PATCH_FILES ${PATCH_FILES}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
