project(libzmq)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

assert_var_defined(CC)
assert_var_defined(CXX)
assert_var_defined(CFLAGS)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(STATIC_LIBSTDCPP)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# added -Wno-unused-result in CXXFLAGS to ignore sodium_init() warning
set(CFG_ENV_VAR "CC=\"${CC}\" CXX=\"${CXX}\" CFLAGS=\"${CFLAGS}\" CXXFLAGS=\"${CXXFLAGS} -Wno-unused-result\" LDFLAGS=\"${LDFLAGS}\" LIBS=\"${STATIC_LIBSTDCPP}\"")
set(CFG_ENV_VAR "${CFG_ENV_VAR} libzmq_have_xmlto=no libzmq_have_asciidoc=no")

set(CFG_OPTS "-q --prefix=${BINARY_DIR} --disable-static --enable-shared --disable-libbsd --disable-libunwind --without-docs --host=\"${CHOST}\"")
if(DEFINED ENV{LEGACY} OR DEFINED ENV{POCKETBOOK})
    set(CFG_OPTS "${CFG_OPTS} --disable-eventfd")
endif()

set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")
set(PATCH_CMD sh -c "${ISED} \"s|-lstdc++||g\" libtool")

set(SKIP_TEST sh -c "${ISED} \"s|tests||g\" Makefile.am")
# clear build dir every time so make install won't fail
set(CLEAR_BUILD_DIR ${CMAKE_COMMAND} -E remove_directory ${BINARY_DIR} COMMAND ${CMAKE_COMMAND} -E make_directory ${BINARY_DIR})

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/zeromq/libzmq
    tags/v4.3.1
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ./autogen.sh COMMAND COMMAND ${SKIP_TEST} COMMAND ${CLEAR_BUILD_DIR}
    CONFIGURE_COMMAND COMMAND ${CFG_CMD} COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} installdirs uninstall install
)
