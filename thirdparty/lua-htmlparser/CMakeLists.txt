project(lua-htmlparser LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

append_luarocks_install_command(BUILD_CMD rockspecs/htmlparser-scm-0.rockspec)

append_tree_install_command(INSTALL_CMD "${INSTALL_DIR}/rocks" rocks)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/msva/lua-htmlparser
    5ce9a775a345cf458c0388d7288e246bb1b82bff
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
