# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

append_install_commands(INSTALL_CMD
    consts_h.lua poll_h.lua select_h.lua
    socket_h.lua socket.lua time_h.lua
    wpaclient.lua wpa_ctrl.lua
    DESTINATION ${OUTPUT_DIR}/common/lj-wpaclient
)

external_project(
    DOWNLOAD GIT 0d5c8ee336b699dbb35850a7336d24e89e1aac24
    https://github.com/koreader/lj-wpaclient.git
    INSTALL_COMMAND ${INSTALL_CMD}
)
