cmake_minimum_required(VERSION 3.5.1)
project(sdl2 LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")
include("DownloadProject")

ep_get_source_dir(SOURCE_DIR)

# remove workarounds for standalone applications and add a couple of actions
# to be used from the osx main menu.

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/cocoa.patch)

set(SDL2_VER "2.28.1")
set(SDL2_MD5 "ccd2cd02b2ad4f71c2588747028953c3")
download_project(
    PROJ ${PROJECT_NAME}
    URL https://github.com/libsdl-org/SDL/releases/download/release-${SDL2_VER}/SDL2-${SDL2_VER}.tar.gz
    URL_MD5 ${SDL2_MD5}
    PATCH_COMMAND ${PATCH_CMD}
)

add_subdirectory("${CMAKE_BINARY_DIR}/sdl2-src"
                 "${CMAKE_BINARY_DIR}/sdl2-build")
