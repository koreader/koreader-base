# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND PATCH_FILES detect-more-json-content-types.patch)

append_install_commands(INSTALL_CMD src/Spore.lua DESTINATION common)
append_tree_install_commands(INSTALL_CMD src/Spore common/Spore)

external_project(
    DOWNLOAD GIT 0.4.2
    https://framagit.org/fperrad/lua-Spore
    PATCH_FILES ${PATCH_FILES}
    INSTALL_COMMAND ${INSTALL_CMD}
)
