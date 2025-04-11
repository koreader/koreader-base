# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

append_install_commands(
    INSTALL_CMD
    src/nanosvg.h src/nanosvgrast.h
    ${THIRDPARTY_DIR}/nanosvg/stb_image_write.h
    DESTINATION ${STAGING_DIR}/include
)

external_project(
    DOWNLOAD GIT ea6a6aca009422bba0dbad4c80df6e6ba0c82183
    https://github.com/memononen/nanosvg.git
    INSTALL_COMMAND ${INSTALL_CMD}
)
