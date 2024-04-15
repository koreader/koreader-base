cmake_minimum_required(VERSION 3.5.1)
project(czmq LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(ZMQ_DIR)
assert_var_defined(CHOST)

# -Wno-error so we can build on glibc 2.24 in spite of readdir_r
set(CFG_ENV_VAR "CC=${CC}" "LDFLAGS=${LDFLAGS}" "CFLAGS=${CFLAGS} -Wno-error" czmq_have_xmlto=no czmq_have_asciidoc=no)
set(CFG_OPTS --prefix=${INSTALL_DIR} --with-gnu-ld --with-libzmq=${ZMQ_DIR} --disable-static --enable-shared --host=${CHOST})
list(APPEND CFG_CMD COMMAND env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

if(DEFINED ENV{ANDROID})
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

# Hack to remove hardcoded rpath
list(APPEND CFG_CMD COMMAND ${ISED} "s|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=\"\"|g" libtool)
list(APPEND CFG_CMD COMMAND ${ISED} "s|^runpath_var=LD_RUN_PATH|runpath_var=DIE_RPATH_DIE|g" libtool)

list(APPEND PATCH_CMD COMMAND ./autogen.sh)
if(NOT DEFINED ENV{DARWIN})
    # patch: ignore limited broadcast address
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zbeacon.patch)
    # patch: add _DEFAULT_SOURCE define for glibc starting at version 2.20
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/czmq_default_source_define.patch)
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} install)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/zeromq/czmq.git
    2a0ddbc4b2dde623220d7f4980ddd60e910cfa78
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
