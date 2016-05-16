PROJECT(leptonica)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

ep_get_source_dir(SOURCE_DIR)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/DanBloomberg/leptonica.git
    v1.72
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    # Make sure we use the old fmemopen symbol on Linux when building against glibc >= 2.22 (c.f. base#421)
    # NOTE: The patch will be much simpler w/ the upcoming leptonica version, there's a 1.74 version of the patch already in our tree for when that time comes ;)
    # NOTE: Because everything is awesome, this can only be applied safely when building against glibc >= 2.22 ...
    if(${GLIBC_GTE_2_22})
        PATCH_COMMAND patch -N -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/leptonica-1.72-fmemopen-compat-symbol.patch
    endif(${GLIBC_GTE_2_22})
    CONFIGURE_COMMAND ""
    # skip build and install, libk2pdfopt will build it
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)
