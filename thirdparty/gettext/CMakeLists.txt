project(gettext)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)

assert_var_defined(LIBICONV_PREFIX)
assert_var_defined(CHOST_OPTS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_ENV_VAR "CC=\"${CC}\" AR=\"${AR}\" RANLIB=\"${RANLIB}\"")
if($ENV{ANDROID})
    # workaround of 'undefined reference to getdtablesize' for NDK-r11c
    set(CFG_ENV_VAR "${CFG_ENV_VAR} LDFLAGS=-lc LIBS=${NDK}/platforms/android-${NDKABI}/arch-arm/usr/lib/libc.a")
endif()
set(CFG_OPTS "--with-threads=none --disable-acl --disable-curses --disable-openmp --disable-native-java --disable-java")
set(CFG_OPTS "${CFG_OPTS} --prefix=${BINARY_DIR} --with-libiconv-prefix=${LIBICONV_PREFIX}")
set(CFG_OPTS "${CFG_OPTS} --enable-shared=false --enable-static=true ${CHOST_OPTS}")
set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

# remove HAVE_PWD_H for android build
if($ENV{ANDROID})
    set(CFG_CMD "${CFG_CMD} && ${ISED} \"s|#define HAVE_PWD_H 1||\" gettext-tools/config.h")
endif()

set(GETTEXT_VER "0.20.2")
include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    URL http://ftpmirror.gnu.org/gettext/gettext-${GETTEXT_VER}.tar.gz
    URL_MD5 30fec34a895fab4c02584449c500aac2
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} --silent
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} --silent install
)
