cmake_minimum_required(VERSION 3.15)
project(nanosvg LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/memononen/nanosvg.git
    93ce879dc4c04a3ef1758428ec80083c38610b1f
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_COMMAND COMMAND
)
