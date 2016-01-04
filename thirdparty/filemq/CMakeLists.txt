PROJECT(filemq)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(ZMQ_DIR)
assert_var_defined(CZMQ_DIR)
assert_var_defined(HOST)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)


set(CFG_ENV_VAR "CC=\"${CC}\" CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\" fmq_have_xmlto=no fmq_have_asciidoc=no")
set(CFG_OPTS "-q --prefix=${BINARY_DIR} --with-libzmq=${ZMQ_DIR} --with-libczmq=${CZMQ_DIR} --disable-static --enable-shared --host=\"${HOST}\"")
set(CFG_CMD_STR "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

set(SED_CMD1_STR "sed -i 's|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=\"\"|g' libtool")
set(SED_CMD2_STR "sed -i 's|^runpath_var=LD_RUN_PATH|runpath_var=DIE_RPATH_DIE|g' libtool")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/zeromq/filemq.git
    9a24134d4c0a84abc5eebf1dfb2eb184adee72df
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ./autogen.sh
    CONFIGURE_COMMAND sh -c ${CFG_CMD_STR} COMMAND sh -c ${SED_CMD1_STR} COMMAND sh -c ${SED_CMD2_STR}
    BUILD_COMMAND $(MAKE) -j${PROCESSOR_COUNT} --silent
    INSTALL_COMMAND $(MAKE) --silent uninstall install
)
