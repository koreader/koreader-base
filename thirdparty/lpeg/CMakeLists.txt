PROJECT(lpeg)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(DYNLIB_CFLAGS)
assert_var_defined(LUA_DIR)

set(BUILD_CMD_STR "${CC} ${DYNLIB_CFLAGS} -I${LUA_DIR}/src -L${LUA_DIR} -lluajit -o lpeg.so lpcap.c lpcode.c lpprint.c lptree.c lpvm.c")

set(LPEG_VER "1.0.0")
include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    URL http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-${LPEG_VER}.tar.gz
    URL_MD5 0aec64ccd13996202ad0c099e2877ece
    BUILD_IN_SOURCE 1
    # skip configure
    CONFIGURE_COMMAND ""
    BUILD_COMMAND sh -c ${BUILD_CMD_STR}
    # skip install
    INSTALL_COMMAND ""
)
