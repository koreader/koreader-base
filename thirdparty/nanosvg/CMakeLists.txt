# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    FROM "${SOURCE_DIR}/src"
    nanosvg.h nanosvgrast.h
    "${THIRDPARTY_DIR}/nanosvg/stb_image_write.h"
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/memononen/nanosvg.git
    93ce879dc4c04a3ef1758428ec80083c38610b1f
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
