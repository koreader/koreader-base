project(sdl2)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")
include("DownloadProject")

enable_language(C)

ep_get_source_dir(SOURCE_DIR)

# remove workarounds for standalone applications and add a couple of actions
# to be used from the osx main menu.

set(PATCH_CMD "${KO_PATCH_SH} ${CMAKE_CURRENT_SOURCE_DIR}/cocoa.patch")

set(SDL2_VER "2.0.12")
set(SDL2_MD5 "783b6f2df8ff02b19bb5ce492b99c8ff")
download_project(
    PROJ ${PROJECT_NAME}
    URL https://www.libsdl.org/release/SDL2-${SDL2_VER}.tar.gz
    URL_MD5 ${SDL2_MD5}
    PATCH_COMMAND COMMAND ${PATCH_CMD}
)

add_subdirectory("${CMAKE_BINARY_DIR}/sdl2-src"
                 "${CMAKE_BINARY_DIR}/sdl2-build")
