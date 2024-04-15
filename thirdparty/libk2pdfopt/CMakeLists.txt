cmake_minimum_required(VERSION 3.5.1)
project(libk2pdfopt LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(CXX)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(LEPTONICA_DIR)
assert_var_defined(TESSERACT_DIR)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/slightly-less-fuglyness.patch)
list(APPEND PATCH_CMD COMMAND mv tesseract_mod/tesscapi.cpp tesscapi.cpp)
list(APPEND PATCH_CMD COMMAND mv include_mod/tesseract.h tesseract.h)
list(APPEND PATCH_CMD COMMAND sh -c "printf '#pragma once\\n#include <allheaders.h>' >leptonica.h")

if (DARWIN)
    #fix build error due to implicit declarations of function being invalid in C99 under macOS/XCode 12
    set(CFLAGS "${CFLAGS} -Wno-error=implicit-function-declaration")
endif()

set(CPPFLAGS "-I${LEPTONICA_DIR}/include/leptonica -I${TESSERACT_DIR}/include/tesseract -I.")
set(CFLAGS "${CFLAGS} ${CPPFLAGS}")
set(CXXFLAGS "${CXXFLAGS} ${CPPFLAGS}")

list(APPEND BUILD_CMD COMMAND
    ${KO_MAKE_RECURSIVE}
    ANDROID=${ANDROID} DARWIN=${DARWIN}
    CC=${CC}
    CFLAGS=${CFLAGS}
    CXX=${CXX}
    CXXFLAGS=${CXXFLAGS}
    LDFLAGS=${LDFLAGS}
    LEPTONICA_LIB=${LEPTONICA_LIB}
    MOD_INC=.
    TESSCAPI_CFLAGS=
    TESSERACT_LIB=${TESSERACT_LIB}
    TESSERACT_MOD=.
    all)

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
)
