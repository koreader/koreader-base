project(luasocket LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

# Rename modules: `mime.core` → `mime.mcore` & `socket.core` → `socket.score`.
list(APPEND PATCH_CMD COMMAND sh -c "\"\$@\" *.rockspec src/*" --
    ${ISED} " "
    -e "s|socket\\.core|socket.score|g"
    -e "s|socket_core|socket_score|g"
    -e "s|mime\\.core|mime.mcore|g"
    -e "s|mime_core|mime_mcore|g"
    -e "s|SOCKET_CDIR)/core|SOCKET_CDIR)/score|"
    -e "s|MIME_CDIR)/core|MIME_CDIR)/mcore|"
)

# Raw ld does not like `-Wl,…` flags.
set(LD "${CC}")

append_luarocks_install_command(BUILD_CMD luasocket-scm-3.rockspec)
list(APPEND BUILD_CMD
    "LUAPATH=${BINARY_DIR}/common"
    "OPENSSL_INCDIR=${STAGING_DIR}/openssl/include"
    "OPENSSL_LIBDIR=${STAGING_DIR}/openssl/shared"
)

append_tree_install_command(INSTALL_CMD "${INSTALL_DIR}/rocks" rocks)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/lunarmodules/luasocket
    8c2ff7217e2a205eb107a6f48b04ff1b2b3090a1
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
