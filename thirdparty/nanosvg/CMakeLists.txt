project(nanosvg LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    "${SOURCE_DIR}/src/*.h"
    "${THIRDPARTY_DIR}/nanosvg/stb_image_write.h"
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/memononen/nanosvg.git
    9da543e8329fdd81b64eb48742d8ccb09377aed1
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND COMMAND
    INSTALL_COMMAND ${INSTALL_CMD}
)
