project(luasec LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

# Raw ld does not like `-Wl,…` flags.
set(LD "${CC}")

append_luarocks_install_command(BUILD_CMD luasec-1.3.1-1.rockspec)
list(APPEND BUILD_CMD
    "INC_PATH=" "LIB_PATH="
    "OPENSSL_INCDIR=${STAGING_DIR}/openssl/include"
    "OPENSSL_LIBDIR=${STAGING_DIR}/openssl/shared"
)

append_tree_install_command(INSTALL_CMD "${INSTALL_DIR}/rocks" rocks)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/brunoos/luasec
    tags/v1.3.1
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
