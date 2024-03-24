# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

append_install_commands(INSTALL_CMD BYPRODUCTS lua/json.lua DESTINATION common/)
append_tree_install_commands(INSTALL_CMD BYPRODUCTS lua/json common/json)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/harningt/luajson.git
    tags/1.3.4
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
