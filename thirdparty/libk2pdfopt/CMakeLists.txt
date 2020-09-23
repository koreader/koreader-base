project(libk2pdfopt)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_asm")
include("koreader_thirdparty_git")

enable_language(C CXX ASM)

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
assert_var_defined(STDCPPLIB)

#fix build error due to implicit declarations of function being invalid in C99 under macOS/XCode 12 
set(CFLAGS "${CFLAGS} -Wno-error=implicit-function-declaration")

ep_get_source_dir(SOURCE_DIR)

set(BUILD_CMD sh -c "${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} BUILDMODE=shared HOST=${HOST} CC=\"${CC}\" CFLAGS=\"${CFLAGS} -O3\"")
set(BUILD_CMD "${BUILD_CMD} CXX=\"${CXX}\" CXXFLAGS=\"${CXXFLAGS}\" AR=\"${AR}\" RANLIB=\"${RANLIB}\" ZLIB=${ZLIB}")
set(BUILD_CMD "${BUILD_CMD} TESSERACT_DIR=${TESSERACT_DIR} LEPTONICA_DIR=${LEPTONICA_DIR}")
set(BUILD_CMD "${BUILD_CMD} LEPT_CFLAGS=\"${CFLAGS} -I${ZLIB_DIR} -I${PNG_DIR}/include\"")
set(BUILD_CMD "${BUILD_CMD} LEPT_LDFLAGS=\"${LDFLAGS} -L${ZLIB_DIR} -L${PNG_DIR}/lib\"")
if ($ENV{DARWIN})
    set(BUILD_CMD "${BUILD_CMD} STDCPPLIB=\"${STDCPPLIB}\" ZLIB_LDFLAGS=\"-L${ZLIB_DIR}\"")
    set(BUILD_CMD "${BUILD_CMD} PNG_LDFLAGS=\"-L${PNG_DIR}/lib\" all")
else()
    set(BUILD_CMD "${BUILD_CMD} STDCPPLIB=\"${STDCPPLIB}\" ZLIB_LDFLAGS=\"-Wl,-rpath-link,${ZLIB_DIR}\"")
    set(BUILD_CMD "${BUILD_CMD} PNG_LDFLAGS=\"-Wl,-rpath-link,${PNG_DIR}/lib\" all")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/libk2pdfopt.git
    24b7e6bc136667c98feaa1b519a99dd880b05ebe
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
