# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

append_install_commands(
    INSTALL_CMD
    src/nanosvg.h src/nanosvgrast.h
    ${THIRDPARTY_DIR}/nanosvg/stb_image_write.h
    DESTINATION ${STAGING_DIR}/include
)

external_project(
    DOWNLOAD GIT 93ce879dc4c04a3ef1758428ec80083c38610b1f
    https://github.com/memononen/nanosvg.git
    INSTALL_COMMAND ${INSTALL_CMD}
)
