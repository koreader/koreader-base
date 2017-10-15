PROJECT(libiconv)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)

assert_var_defined(HOST)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_ENV_VAR "CC=\"${CC}\"")
set(CFG_OPTS "--with-threads=none --prefix=${BINARY_DIR} --enable-shared=false --enable-static=true --host=\"${HOST}\"")
set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

set(GETTEXT_VER "1.15")
include(ExternalProject)
ExternalProject_Add(
    libiconv
    URL http://ftp.gnu.org/pub/gnu/libiconv/libiconv-${GETTEXT_VER}.tar.gz
    URL_MD5 ace8b5f2db42f7b3b3057585e80d9808
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS} --silent
    INSTALL_COMMAND $(MAKE) -j${PARALLEL_JOBS} --silent install
)
