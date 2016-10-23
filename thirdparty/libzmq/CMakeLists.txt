PROJECT(libzmq)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
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

set(CFG_ENV_VAR "CC=\"${CC}\" CXX=\"${CXX}\" CFLAGS=\"${CFLAGS}\" CXXFLAGS=\"${CXXFLAGS}\" LDFLAGS=\"${LDFLAGS}\" LIBS=\"${STATIC_LIBSTDCPP}\"")
set(CFG_ENV_VAR "${CFG_ENV_VAR} libzmq_have_xmlto=no libzmq_have_asciidoc=no")

set(CFG_OPTS "-q --prefix=${BINARY_DIR} --disable-static --enable-shared --without-documentation --host=\"${CHOST}\"")
if(${LEGACY})
    set(CFG_OPTS "${CFG_OPTS} --disable-eventfd")
endif(${LEGACY})

set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")
set(PATCH_CMD sh -c "${ISED} \"s|-lstdc++||g\" libtool")

set(FORCE_DYNAMLIB_VERSION sed -i "s|-avoid-version||g" src/Makefile.am)
set(SKIP_TEST sed -i "s|tests||g" Makefile.am)
# clear build dir every time so make install won't fail
set(CLEAR_BUILD_DIR ${CMAKE_COMMAND} -E remove_directory ${BINARY_DIR} COMMAND ${CMAKE_COMMAND} -E make_directory ${BINARY_DIR})

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/zeromq/libzmq
    883e95b22e0bffffa72312ea1fec76199afbe458
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ./autogen.sh COMMAND ${FORCE_DYNAMLIB_VERSION} COMMAND ${SKIP_TEST} COMMAND ${CLEAR_BUILD_DIR}
    CONFIGURE_COMMAND COMMAND ${CFG_CMD} COMMAND ${PATCH_CMD}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS} --silent
    INSTALL_COMMAND $(MAKE) --silent installdirs uninstall install
)
