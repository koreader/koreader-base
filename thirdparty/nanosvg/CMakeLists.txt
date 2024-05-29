# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

append_install_commands(
    INSTALL_CMD
    src/nanosvg.h src/nanosvgrast.h
    ${THIRDPARTY_DIR}/nanosvg/stb_image_write.h
    DESTINATION ${STAGING_DIR}/include
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/memononen/nanosvg.git
    93ce879dc4c04a3ef1758428ec80083c38610b1f
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    INSTALL_COMMAND ${INSTALL_CMD}
)
