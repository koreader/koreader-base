PROJECT(tesseract)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

ep_get_source_dir(SOURCE_DIR)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/tesseract-ocr/tesseract.git
    add1ed1067531d6cccafd279d5a03f7462c0bb50
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND sh -c "sed -i 's/AM_CONFIG_HEADER/AC_CONFIG_HEADERS/g' configure.ac"
    CONFIGURE_COMMAND ""
    # skip build and install, libk2pdfopt will build it
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)
