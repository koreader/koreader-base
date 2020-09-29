project(openjpeg)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
#include("koreader_thirdparty_common")
#include("koreader_thirdparty_git")
include("DownloadProject")

enable_language(C)

download_project(
    PROJ ${PROJECT_NAME}
    GIT_REPOSITORY
    https://github.com/uclouvain/openjpeg
    GIT_TAG
    v2.3.1
)

set(BUILD_STATIC_LIBS OFF CACHE BOOL "" FORCE)
set(BUILD_CODEC OFF CACHE BOOL "" FORCE)
add_subdirectory("${CMAKE_BINARY_DIR}/openjpeg-src")
