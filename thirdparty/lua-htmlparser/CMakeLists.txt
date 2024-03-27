# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

append_install_commands(INSTALL_CMD BYPRODUCTS src/htmlparser.lua DESTINATION common/)
append_tree_install_commands(INSTALL_CMD BYPRODUCTS src/htmlparser common/htmlparser)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/msva/lua-htmlparser
    5ce9a775a345cf458c0388d7288e246bb1b82bff
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
