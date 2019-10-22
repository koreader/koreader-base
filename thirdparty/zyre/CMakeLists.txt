project(zyre)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(ZMQ_DIR)
assert_var_defined(CZMQ_DIR)
assert_var_defined(HOST)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_ENV_VAR "CC=\"${CC}\" CFLAGS=\"${CFLAGS}\" CXXFLAGS=\"${CXXFLAGS}\" LDFLAGS=\"${LDFLAGS}\" zyre_have_xmlto=no zyre_have_asciidoc=no")
set(CFG_OPTS "-q --prefix=${BINARY_DIR} --with-libzmq=${ZMQ_DIR} --with-libczmq=${CZMQ_DIR} --disable-static --enable-shared --host=${HOST}")
set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

if($ENV{ANDROID})
    set(CFG_CMD "${CFG_CMD} && ${ISED} 's|version_type=none|version_type=linux|' libtool")
    set(CFG_CMD "${CFG_CMD} && ${ISED} 's|need_lib_prefix=no|need_lib_prefix=yes|' libtool")
    set(CFG_CMD "${CFG_CMD} && ${ISED} 's|need_version=no|need_version=yes|' libtool")
    set(CFG_CMD "${CFG_CMD} && ${ISED} 's|library_names_spec=.*|library_names_spec=\"\\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$versuffix \\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$major \\\\\$libname\\\\\$shared_ext\"|' libtool")
    set(CFG_CMD "${CFG_CMD} && ${ISED} 's|soname_spec=.*|soname_spec=\"\\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$major\"|' libtool")
endif()

set(SED_CMD1 "${ISED} 's|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=\"\"|g' libtool")
set(SED_CMD2 "${ISED} 's|^runpath_var=LD_RUN_PATH|runpath_var=DIE_RPATH_DIE|g' libtool")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/zeromq/zyre.git
    3a0a14a37422604c99fda8d7befeaae95c15791b
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ./autogen.sh
    CONFIGURE_COMMAND COMMAND ${CFG_CMD} COMMAND ${SED_CMD1} COMMAND ${SED_CMD2}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} installdirs uninstall install
)
