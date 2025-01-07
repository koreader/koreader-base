# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

append_install_commands(INSTALL_CMD dkjson.lua DESTINATION common)

external_project(
    DOWNLOAD URL d7754634dcbe6e95f3b6b55fd4ca5ceb
    http://dkolf.de/dkjson-lua/dkjson-2.8.tar.gz
    INSTALL_COMMAND ${INSTALL_CMD}
)
