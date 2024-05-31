# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

append_install_commands(INSTALL_CMD src/lunajson.lua DESTINATION common)
append_tree_install_commands(INSTALL_CMD src/lunajson common/lunajson)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/grafi-tt/lunajson
    3d10600874527d71519b33ecbb314eb93ccd1df6
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    INSTALL_COMMAND ${INSTALL_CMD}
)
