# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

append_install_commands(INSTALL_CMD srell.hpp DESTINATION ${STAGING_DIR}/include)

external_project(
    INSTALL_COMMAND ${INSTALL_CMD}
)
