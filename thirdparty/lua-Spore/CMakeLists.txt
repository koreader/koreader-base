project(lua-Spore LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

set(LUA_SPORE_VER "0.3.1-1")
set(LUA_SPORE_ROCKSPEC rockspec/lua-spore-${LUA_SPORE_VER}.rockspec)

list(APPEND PATCH_CMD COMMAND mkdir -p doc)
list(APPEND PATCH_CMD COMMAND ${ISED} "s| 'luasocket|--&|g" ${LUA_SPORE_ROCKSPEC})

append_luarocks_install_command(BUILD_CMD ${LUA_SPORE_ROCKSPEC})

append_tree_install_command(INSTALL_CMD "${INSTALL_DIR}/rocks" rocks)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://framagit.org/fperrad/lua-Spore
    tags/0.3.3
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
