cmake_minimum_required(VERSION 3.5.1)
project(giflib LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

list(APPEND PATCH_CMD ${ISED} "s|\\$srcdir/configure \\$\\*||g" autogen.sh)
list(APPEND PATCH_CMD COMMAND ./autogen.sh)

set(CFG_ENV_VAR ac_cv_prog_have_xmlto=no "CC=${CC}" "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}")
set(CFG_OPTS --prefix=${INSTALL_DIR} --disable-static --enable-shared --host=${CHOST})
list(APPEND CFG_CMD COMMAND env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

# use limits.h instead of stdint.h for android build
if(DEFINED ENV{ANDROID})
    list(APPEND CFG_CMD COMMAND ${ISED} "s|stdint.h|limits.h|g" ${SOURCE_DIR}/lib/openbsd-reallocarray.c)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} install)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://gitlab.com/koreader/giflib.git
    5.1.4
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
