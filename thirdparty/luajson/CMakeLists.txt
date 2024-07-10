# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

append_install_commands(INSTALL_CMD lua/json.lua DESTINATION common)
append_tree_install_commands(INSTALL_CMD lua/json common/json)

external_project(
    DOWNLOAD GIT 6ecaf9bea8b121a9ffca5a470a2080298557b55d
    https://github.com/harningt/luajson.git
    INSTALL_COMMAND ${INSTALL_CMD}
)
