# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

append_install_commands(INSTALL_CMD src/lunajson.lua DESTINATION common)
append_tree_install_commands(INSTALL_CMD src/lunajson common/lunajson)

external_project(
    URL https://github.com/grafi-tt/lunajson/archive/refs/tags/1.2.3.tar.gz
    URL_MD5 50236a29ac4222ce6a83dc4de757666a
    INSTALL_COMMAND ${INSTALL_CMD}
)
