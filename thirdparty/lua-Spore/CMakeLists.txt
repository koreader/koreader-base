# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

append_install_commands(INSTALL_CMD BYPRODUCTS src/Spore.lua DESTINATION common/)
append_tree_install_commands(INSTALL_CMD BYPRODUCTS src/Spore common/Spore)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://framagit.org/fperrad/lua-Spore
    tags/0.3.3
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
