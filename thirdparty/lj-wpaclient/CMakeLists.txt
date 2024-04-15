cmake_minimum_required(VERSION 3.5.1)
project(lj-wpaclient LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/lj-wpaclient.git
    2f93beb3071e6ebb57c783bd5b92f83aa5ebb757
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_COMMAND COMMAND
)
