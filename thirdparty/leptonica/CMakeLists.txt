PROJECT(leptonica)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

set(LEPTONICA_VER "1.69")
include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    URL http://leptonica.com/source/leptonica-${LEPTONICA_VER}.tar.gz
    URL_MD5 d4085c302cbcab7f9af9d3d6f004ab22
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    # patch leptonica for a small typo, it's already fixed in 1.70
    PATCH_COMMAND sh -c "sed -ie 's|hfind|hFind|g' src/utils.c"
    CONFIGURE_COMMAND ""
    # skip build and install, libk2pdfopt will build it
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)
