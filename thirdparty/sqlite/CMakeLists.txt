PROJECT(sqlite)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(CHOST)

ep_get_binary_dir(BINARY_DIR)

set(CFG_CMD sh -c "CC=\"${CC}\" CFLAGS=\"${CFLAGS} -fno-fast-math\" ./configure")
set(CFG_CMD "${CFG_CMD} --host=${CHOST} --prefix=${BINARY_DIR}")
set(CFG_CMD "${CFG_CMD} --enable-static --disable-shared --enable-threadsafe")
set(CFG_CMD "${CFG_CMD} --disable-dynamic-extensions")

include(ExternalProject)
set(SQLITE_VER "3120200")
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    URL https://www.sqlite.org/2016/sqlite-autoconf-${SQLITE_VER}.tar.gz
    URL_HASH SHA1=b43c2e7238e54c50b95fbbd85c48792f4f39af8c
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND $(MAKE) -j1
)
