cmake_minimum_required(VERSION 3.5.1)
project(luajson LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/harningt/luajson.git
    tags/1.3.4
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
)
