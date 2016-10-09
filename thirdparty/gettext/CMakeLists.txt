PROJECT(gettext)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)

assert_var_defined(LIBICONV_PREFIX)
assert_var_defined(CHOST_OPTS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_ENV_VAR "CC=\"${CC}\"")
if(${IS_ANDROID})
    # workaround of 'undefined reference to getdtablesize' for NDK-r11c
    set(CFG_ENV_VAR "${CFG_ENV_VAR} LDFLAGS=-lc LIBS=${NDK}/platforms/android-${NDKABI}/arch-arm/usr/lib/libc.a")
endif()
set(CFG_OPTS "--with-threads=none --prefix=${BINARY_DIR} --with-libiconv-prefix=${LIBICONV_PREFIX} --enable-shared=false --enable-static=true ${CHOST_OPTS}")
set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")
# remove HAVE_PWD_H for android build
if(${IS_ANDROID})
    set(CFG_CMD "${CFG_CMD} && ${ISED} \"s|#define HAVE_PWD_H 1||\" gettext-tools/config.h")
endif()

set(GETTEXT_VER "0.19")
include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    URL http://ftp.gnu.org/pub/gnu/gettext/gettext-${GETTEXT_VER}.tar.gz
    URL_MD5 eae24a623e02b33e3e1024adff9a5a08
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS} --silent
    INSTALL_COMMAND $(MAKE) -j${PARALLEL_JOBS} --silent install
)
