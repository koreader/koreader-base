PROJECT(dropbear)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
enable_language(C)

assert_var_defined(LIBS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_ENV_VAR "CC=\"${CC} -DHAVE_MKFIFO=1\"")
set(CFG_OPTS "-q LIBS=\"${LIBS}\" --host=\"${CHOST}\"")

if(${DISABLE_LARGEFILE})
    set(CFG_OPTS "${CFG_OPTS} --disable-largefile")
endif(${DISABLE_LARGEFILE})
set(CFG_CMD "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

if(${DISABLE_FORTIFY})
    # Forcibly disable FORTIFY on legacy devices...
    set(CFG_CMD "${CFG_CMD} && ${ISED} 's/# define _FORTIFY_SOURCE 2/#undef _FORTIFY_SOURCE/' config.h")
endif(${DISABLE_FORTIFY})
set(CFG_CMD sh -c ${CFG_CMD})

include(ExternalProject)
set(DROPBEAR_VER "2018.76")
ExternalProject_Add(
    dropbear
    URL https://matt.ucc.asn.au/dropbear/releases/dropbear-${DROPBEAR_VER}.tar.bz2
    URL_MD5 c3912f7fcdcc57c99937e4a79480d2c2 
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS} --silent
    INSTALL_COMMAND ""
)
