PROJECT(tar)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
enable_language(C)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(LIBS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_ENV_VAR "CC=\"${CC} -DHAVE_MKFIFO=1\" CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\"")
set(CFG_OPTS "-q LIBS=\"${LIBS}\" --host=\"${CHOST}\"")

if(${DISABLE_LARGEFILE})
    set(CFG_OPTS "${CFG_OPTS} --disable-largefile")
endif(${DISABLE_LARGEFILE})
set(CFG_CMD "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

if(${DISABLE_FORTIFY})
    # Forcibly disable FORTIFY on legacy devices...
    set(CFG_CMD "${CFG_CMD} && ${ISED} 's/# define _FORTIFY_SOURCE 2/#undef _FORTIFY_SOURCE/' config.h")
endif(${DISABLE_FORTIFY})
set(CFG_CMD sh -c "${CFG_CMD}")

include(ExternalProject)
set(TAR_VER "1.30")
ExternalProject_Add(
    tar
    URL http://ftp.gnu.org/gnu/tar/tar-${TAR_VER}.tar.gz
    URL_MD5 e0c5ed59e4dd33d765d6c90caadd3c73
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    PATCH_COMMAND ""
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS} --silent
    # skip install for tar
    # NOTE: we always update binary timestamp to notify Make for a fresh build
    INSTALL_COMMAND ${CMAKE_COMMAND} -E touch ${BINARY_DIR}/tar
)
