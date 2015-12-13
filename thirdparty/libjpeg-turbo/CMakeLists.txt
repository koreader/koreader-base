PROJECT(libjpeg-turbo)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C CXX)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_ENV_VAR "CC=\"${CC}\" CXX=\"${CXX}\" CPPFLAGS=\"${CPPFLAGS}\" LDFLAGS=\"${LDFLAGS}\" ")
set(CFG_OPTS "-q --prefix=${BINARY_DIR} --host=\"${CHOST}\" --disable-static --enable-shared --with-jpeg8")
if(${WITHOUT_SIMD})
    set(CFG_OPTS "${CFG_OPTS} --without-simd")
endif(${WITHOUT_SIMD})
set(CFG_CMD_STR "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

set(LIBJPEG_TURBO_VER "1.4.2")
include(ExternalProject)
ExternalProject_Add(
    libjpeg-turbo
    URL http://download.sourceforge.net/libjpeg-turbo/libjpeg-turbo-${LIBJPEG_TURBO_VER}.tar.gz
    URL_MD5 86b0d5f7507c2e6c21c00219162c3c44
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    CONFIGURE_COMMAND sh -c ${CFG_CMD_STR}
    BUILD_COMMAND $(MAKE) -j${PROCESSOR_COUNT} --silent
    INSTALL_COMMAND $(MAKE) -j${PROCESSOR_COUNT} --silent install
)
