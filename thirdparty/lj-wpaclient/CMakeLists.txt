# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

append_install_commands(INSTALL_CMD
    consts_h.lua poll_h.lua select_h.lua
    socket_h.lua socket.lua time_h.lua
    wpaclient.lua wpa_ctrl.lua
    DESTINATION ${OUTPUT_DIR}/common/lj-wpaclient
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/lj-wpaclient.git
    2f93beb3071e6ebb57c783bd5b92f83aa5ebb757
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    INSTALL_COMMAND ${INSTALL_CMD}
)
