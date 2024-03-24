# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

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

if(DARWIN)
    set(PLAT "macosx")
elseif(WIN32)
    set(PLAT "mingw")
else()
    set(PLAT "linux")
endif()

set(MYLDFLAGS "${LDFLAGS}")
if(USE_LUAJIT_LIB)
    string(APPEND MYLDFLAGS " ${STAGING_DIR}/lib/libluajit${LIB_EXT}")
endif()

list(APPEND BUILD_CMD
    ${KO_MAKE_RECURSIVE}
    "CC=${CC} ${CFLAGS}"
    "LD=${CC} ${CFLAGS}"
    "LUAINC=${STAGING_DIR}/include"
    "MYLDFLAGS=${MYLDFLAGS}"
    "PLAT=${PLAT}"
)

append_install_commands(
    INSTALL_CMD BYPRODUCTS
    src/ltn12.lua src/mime.lua src/socket.lua
    DESTINATION common/
)
append_install_commands(
    INSTALL_CMD BYPRODUCTS
    src/ftp.lua src/headers.lua src/http.lua
    src/smtp.lua src/tp.lua src/url.lua
    DESTINATION common/socket/
)
append_binary_install_command(
    INSTALL_CMD BYPRODUCTS
    src/socket-3.1.0.so common/socket/score.so
)
append_binary_install_command(
    INSTALL_CMD BYPRODUCTS
    src/mime-1.0.3.so common/mime/mcore.so
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/lunarmodules/luasocket
    fa69770e52ba869feb8339d49e7c3c536953fbde
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
