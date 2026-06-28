# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

append_install_commands(INSTALL_CMD dkjson.lua DESTINATION common)

external_project(
    DOWNLOAD URL eededec0ec8befa97fc88947a668b5e6
    http://dkolf.de/dkjson-lua/dkjson-2.10.tar.gz
    INSTALL_COMMAND ${INSTALL_CMD}
)
