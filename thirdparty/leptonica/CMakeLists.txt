PROJECT(leptonica)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

set(LEPTONICA_VER "1.72")
include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    URL http://leptonica.com/source/leptonica-${LEPTONICA_VER}.tar.gz
    URL_MD5 7581db29f8442197ce68e766c6047c4b
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    CONFIGURE_COMMAND ""
    # skip build and install, libk2pdfopt will build it
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)
