# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

append_install_commands(INSTALL_CMD src/htmlparser.lua DESTINATION common)
append_tree_install_commands(INSTALL_CMD src/htmlparser common/htmlparser)

external_project(
    DOWNLOAD GIT 5ce9a775a345cf458c0388d7288e246bb1b82bff
    https://github.com/msva/lua-htmlparser
    INSTALL_COMMAND ${INSTALL_CMD}
)
