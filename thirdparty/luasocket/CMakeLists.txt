# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

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

# Make sure socket fds are CLOEXEC on *nix
if(NOT ANDROID)
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH}
        ${CMAKE_CURRENT_SOURCE_DIR}/luasocket-enforce-cloexec.patch
    )
endif()

if(DARWIN)
    set(PLAT macosx)
elseif(WIN32)
    set(PLAT mingw)
else()
    set(PLAT linux)
endif()

string(JOIN " " MYLDFLAGS ${LDFLAGS} ${LUAJIT_LIB})

list(APPEND BUILD_CMD COMMAND
    ${KO_MAKE_RECURSIVE}
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

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/lunarmodules/luasocket
    e3ca4a767a68d127df548d82669aba3689bd84f4
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
