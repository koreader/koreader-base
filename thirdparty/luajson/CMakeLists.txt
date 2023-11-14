project(luajson LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

set(LUAJSON_VER "1.3.4-1")
set(LUAJSON_ROCKSPEC rockspecs/luajson-${LUAJSON_VER}.rockspec)

append_luarocks_install_command(BUILD_CMD ${LUAJSON_ROCKSPEC})

append_tree_install_command(INSTALL_CMD "${INSTALL_DIR}/rocks" rocks)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/harningt/luajson.git
    tags/1.3.4
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
