cmake_minimum_required(VERSION 3.15)
project(libk2pdfopt LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND PATCH_CMD COMMAND ${KO_PATCH}
    ${CMAKE_CURRENT_SOURCE_DIR}/slightly-less-fuglyness.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/reproducible-builds.patch
)
list(APPEND PATCH_CMD COMMAND mv tesseract_mod/tesscapi.cpp tesscapi.cpp)
list(APPEND PATCH_CMD COMMAND mv include_mod/tesseract.h tesseract.h)
list(APPEND PATCH_CMD COMMAND sh -c "printf '#pragma once\\n#include <allheaders.h>' >leptonica.h")

if (DARWIN)
    #fix build error due to implicit declarations of function being invalid in C99 under macOS/XCode 12
    set(CFLAGS "${CFLAGS} -Wno-error=implicit-function-declaration")
endif()

set(CPPFLAGS "-I${STAGING_DIR}/include/leptonica -I${STAGING_DIR}/include/tesseract -I.")
set(CFLAGS "${CFLAGS} ${CPPFLAGS}")
set(CXXFLAGS "${CXXFLAGS} ${CPPFLAGS}")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})
append_autotools_vars(BUILD_CMD)
list(APPEND BUILD_CMD
    ANDROID=${ANDROID}
    BUILDMODE=shared
    DARWIN=${DARWIN}
    LEPTONICA_LIB=${STAGING_DIR}/lib/liblept${LIB_EXT}
    MOD_INC=.
    TESSCAPI_CFLAGS=
    TESSERACT_LIB=${STAGING_DIR}/lib/libtesseract${LIB_EXT}
    TESSERACT_MOD=.
    all)

list(APPEND INSTALL_CMD COMMAND mkdir -p "${STAGING_DIR}/include/k2pdfopt" "${STAGING_DIR}/lib")
list(APPEND INSTALL_CMD COMMAND sh -c "cd \"$1\" && shift && cp \"$@\"" -- ${SOURCE_DIR}
    context.h koptcrop.h koptimize.h koptocr.h koptreflow.h leptonica.h setting.h
    tesseract.h k2pdfoptlib/k2pdfopt.h willuslib/willus.h
    ${STAGING_DIR}/include/k2pdfopt/
)
list(APPEND INSTALL_CMD COMMAND sh -c "cp libk2pdfopt${LIB_EXT}* \"$1\"" -- ${STAGING_DIR}/lib/)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/libk2pdfopt.git
    47caea57aaf6200fc2b24669b6417fe6919926b7
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
