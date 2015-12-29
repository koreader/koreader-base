PROJECT(tesseract)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

set(TESSERACT_VER "3.02.02")
include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    URL http://tesseract-ocr.googlecode.com/files/tesseract-ocr-${TESSERACT_VER}.tar.gz
    URL_MD5 26adc8154f0e815053816825dde246e6
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    PATCH_COMMAND sh -c "sed -i 's/AM_CONFIG_HEADER/AC_CONFIG_HEADERS/g' configure.ac"
    CONFIGURE_COMMAND ""
    # skip build and install, libk2pdfopt will build it
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)
