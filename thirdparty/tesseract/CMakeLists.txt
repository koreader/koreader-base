project(tesseract)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

if ("$ENV{ANDROID}" STREQUAL "1")
    set(CXXFLAGS "${CXXFLAGS} -DANDROID")
endif()

set(CFG_ENV_VAR "PKG_CONFIG=/bin/false CC=\"${CC}\" CXX=\"${CXX}\" CFLAGS=\"${CFLAGS}\" CXXFLAGS=\"${CXXFLAGS}\" LEPTONICA_CFLAGS=\" \" LEPTONICA_LIBS=\" \" LDFLAGS=\"${LDFLAGS}\" LIBS=\"${LIBS}\"")
set(CFG_OPTS "-q --prefix=${BINARY_DIR} --disable-static --enable-shared --disable-openmp --enable-visibility --host=\"${CHOST}\"")
set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

# Add errno for android until tesseract fixes it
set(PATCH_CMD sh -c "${ISED} 's/#include <unistd\.h>/#include <unistd.h>\\n#include <errno.h>/' ${SOURCE_DIR}/src/api/baseapi.cpp")
set(PATCH2_CMD "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/tesseract-k2pdfopt.patch")
set(PATCH3_CMD sh -c "${ISED} '/bin_PROGRAMS = tesseract/d' ${SOURCE_DIR}/src/api/Makefile.am")


ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/tesseract-ocr/tesseract.git
    4.1
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD} COMMAND ${PATCH2_CMD} COMMAND ${PATCH3_CMD} COMMAND sh -c "${ISED} \"s|\\$srcdir\\/configure \\$\\*||g\" autogen.sh" COMMAND ./autogen.sh
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j1 # TBA: This is heavy weight C++, -j1 necessary so as to not nuke CircleCI instances
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} install
)
