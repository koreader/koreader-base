cmake_minimum_required(VERSION 3.5.1)
project(libk2pdfopt LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(CXX)
assert_var_defined(CXXFLAGS)
assert_var_defined(AR)
assert_var_defined(LDFLAGS)
assert_var_defined(ZLIB)
assert_var_defined(ZLIB_DIR)
assert_var_defined(PNG_DIR)
assert_var_defined(LEPTONICA_DIR)
assert_var_defined(TESSERACT_DIR)
assert_var_defined(K2PDFOPT_DIR)

if (DEFINED ENV{DARWIN})
    #fix build error due to implicit declarations of function being invalid in C99 under macOS/XCode 12
    set(CFLAGS "${CFLAGS} -Wno-error=implicit-function-declaration")
endif()

# Fix build error when compiling with -std=gnu++17: ISO
# C++17 does not allow 'register' storage class specifier.
set(CXXFLAGS "${CXXFLAGS} -Wno-register -Wno-error=register")

ep_get_source_dir(SOURCE_DIR)

# NOTE: This may be dangerously close to being too long (and as such, is at risk of random failure if your base path is even halfway long-ish)...
# FIXME: Horrible nastiness on *native* builds happens if we set LDFLAGS here...
#        (Namely, one of the libtool linking stage for tesseract fails to pickup the -L flags necessary to find liblept. Cross builds work fine. Yay, libtool).
set(BUILD_CMD ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} BUILDMODE=shared HOST=${HOST} CC=${CC} "CFLAGS=${CFLAGS}")
set(BUILD_CMD ${BUILD_CMD} CXX=${CXX} "CXXFLAGS=${CXXFLAGS}" AR=${AR} RANLIB=${RANLIB} ZLIB=${ZLIB})
set(BUILD_CMD ${BUILD_CMD} TESSERACT_DIR=${TESSERACT_DIR} LEPTONICA_DIR=${LEPTONICA_DIR} K2PDFOPT_DIR=${K2PDFOPT_DIR})
set(BUILD_CMD ${BUILD_CMD} "LEPT_CFLAGS=-I${ZLIB_DIR} -I${PNG_DIR}/include")
set(BUILD_CMD ${BUILD_CMD} "LEPT_LDFLAGS=-L${K2PDFOPT_DIR} -lpng -lz")
set(BUILD_CMD ${BUILD_CMD} "ZLIB_LDFLAGS=-L${ZLIB_DIR}")
set(BUILD_CMD ${BUILD_CMD} "PNG_LDFLAGS=-L${PNG_DIR}/lib" all)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/libk2pdfopt.git
    47caea57aaf6200fc2b24669b6417fe6919926b7
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
