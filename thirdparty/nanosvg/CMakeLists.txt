cmake_minimum_required(VERSION 3.5.1)
project(nanosvg LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
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
