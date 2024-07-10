# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

append_install_commands(INSTALL_CMD src/Spore.lua DESTINATION common)
append_tree_install_commands(INSTALL_CMD src/Spore common/Spore)

external_project(
    DOWNLOAD GIT 0.3.3
    https://framagit.org/fperrad/lua-Spore
    INSTALL_COMMAND ${INSTALL_CMD}
)
