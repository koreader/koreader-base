project(lj-wpaclient LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

set(INSTALL_DIR "${OUTPUT_DIR}/common/lj-wpaclient/")
list(APPEND INSTALL_CMD COMMAND mkdir -p "${INSTALL_DIR}")
append_install_command(INSTALL_CMD DESTINATION "${INSTALL_DIR}"
    consts_h.lua poll_h.lua select_h.lua
    socket_h.lua socket.lua time_h.lua
    wpaclient.lua wpa_ctrl.lua
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/lj-wpaclient.git
    2f93beb3071e6ebb57c783bd5b92f83aa5ebb757
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND COMMAND
    INSTALL_COMMAND ${INSTALL_CMD}
)
