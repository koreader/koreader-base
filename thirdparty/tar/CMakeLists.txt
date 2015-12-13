PROJECT(tar)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
enable_language(C)

assert_var_defined(LIBS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_ENV_VAR "CC=\"${CC}\"")
set(CFG_OPTS "-q LIBS=${LIBS} --host=\"${CHOST}\"")

if(${DISABLE_LARGEFILE})
    set(CFG_OPTS "${CFG_OPTS} --disable-largefile")
endif(${DISABLE_LARGEFILE})
set(CFG_CMD_STR "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

if(${DISABLE_FORTIFY})
    # Forcibly disable FORTIFY on legacy devices...
    set(CFG_CMD_STR "${CFG_CMD_STR} && sed -e 's/# define _FORTIFY_SOURCE 2/#undef _FORTIFY_SOURCE/' -i config.h")
endif(${DISABLE_FORTIFY})

include(ExternalProject)
set(TAR_VER "1.28")
ExternalProject_Add(
    tar
    URL http://ftp.gnu.org/gnu/tar/tar-${TAR_VER}.tar.gz
    URL_MD5 6ea3dbea1f2b0409b234048e021a9fd7
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    PATCH_COMMAND patch -N -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/tar-0001-fix-build-failure.patch
    CONFIGURE_COMMAND sh -c ${CFG_CMD_STR}
    BUILD_COMMAND $(MAKE) -j${PROCESSOR_COUNT} --silent
    # skip install for tar
    # NOTE: we always update binary timestamp to notify Make for a fresh build
    INSTALL_COMMAND ${CMAKE_COMMAND} -E touch ${BINARY_DIR}/tar
)
