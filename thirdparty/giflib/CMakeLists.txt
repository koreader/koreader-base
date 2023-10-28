cmake_minimum_required(VERSION 3.5.1)
project(giflib)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_ENV_VAR ac_cv_prog_have_xmlto=no "CC=${CC}" "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}")
set(CFG_OPTS --prefix=${BINARY_DIR} --libdir=${BINARY_DIR}/lib --disable-static --enable-shared --host=${CHOST})
set(CFG_CMD env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

# use limits.h instead of stdint.h for android build
if(DEFINED ENV{ANDROID})
    set(SED_CMD sh -c "${ISED} \"s|stdint.h|limits.h|g\" ${SOURCE_DIR}/lib/openbsd-reallocarray.c")

    set(SED_CMD "${SED_CMD} && ${ISED} 's|version_type=none|version_type=linux|' libtool")
    set(SED_CMD "${SED_CMD} && ${ISED} 's|need_lib_prefix=no|need_lib_prefix=yes|' libtool")
    set(SED_CMD "${SED_CMD} && ${ISED} 's|need_version=no|need_version=yes|' libtool")
    set(SED_CMD "${SED_CMD} && ${ISED} 's|library_names_spec=.*|library_names_spec=\"\\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$versuffix \\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$major \\\\\$libname\\\\\$shared_ext\"|' libtool")
    set(SED_CMD "${SED_CMD} && ${ISED} 's|soname_spec=.*|soname_spec=\"\\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$major\"|' libtool")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://gitlab.com/koreader/giflib.git
    5.1.4
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND sh -c "${ISED} \"s|\\$srcdir\\/configure \\$\\*||g\" autogen.sh" COMMAND ./autogen.sh
    CONFIGURE_COMMAND COMMAND ${CFG_CMD} COMMAND ${SED_CMD}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} install
)
