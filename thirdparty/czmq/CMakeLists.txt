project(czmq)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(ZMQ_DIR)
assert_var_defined(HOST)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

#-Wno-error so we can build on glibc 2.24 in spite of readdir_r
set(CFG_ENV_VAR "CC=\"${CC}\" LDFLAGS=\"${LDFLAGS}\" CFLAGS=\"-Wno-error ${CFLAGS}\" czmq_have_xmlto=no czmq_have_asciidoc=no")
set(CFG_OPTS "-q --prefix=${BINARY_DIR} --with-gnu-ld --with-libzmq=${ZMQ_DIR} --disable-static --enable-shared --host=${HOST}")
set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

# hack to remove hardcoded rpath
set(SED_CMD1 sh -c "${ISED} 's|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=\"\"|g' libtool")
set(SED_CMD2 sh -c "${ISED} 's|^runpath_var=LD_RUN_PATH|runpath_var=DIE_RPATH_DIE|g' libtool")

# patch: ignore limited broadcast address
set(PATCH_CMD1 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zbeacon.patch")
# patch: add _DEFAULT_SOURCE define for glibc starting at version 2.20
set(PATCH_CMD2 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/czmq_default_source_define.patch")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/zeromq/czmq.git
    2a0ddbc4b2dde623220d7f4980ddd60e910cfa78
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ./autogen.sh COMMAND ${PATCH_CMD1} COMMAND ${PATCH_CMD2}
    CONFIGURE_COMMAND COMMAND ${CFG_CMD} COMMAND ${SED_CMD1} COMMAND ${SED_CMD2}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} installdirs uninstall install
)
