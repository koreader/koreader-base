# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

append_install_commands(INSTALL_CMD
    consts_h.lua poll_h.lua select_h.lua
    socket_h.lua socket.lua time_h.lua
    wpaclient.lua wpa_ctrl.lua
    DESTINATION ${OUTPUT_DIR}/common/lj-wpaclient
)

external_project(
    DOWNLOAD GIT 34eb0d3b3c4e2f1cc847f79de4f553d397423a8e
    https://github.com/koreader/lj-wpaclient.git
    INSTALL_COMMAND ${INSTALL_CMD}
)
