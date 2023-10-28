cmake_minimum_required(VERSION 3.5.1)
project(libzmq)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

assert_var_defined(CC)
assert_var_defined(CXX)
assert_var_defined(CFLAGS)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# added -Wno-unused-result in CXXFLAGS to ignore sodium_init() warning
set(CFG_ENV_VAR "CC=${CC}" "CXX=${CXX}" "CFLAGS=${CFLAGS}" "CXXFLAGS=${CXXFLAGS} -Wno-unused-result" "LDFLAGS=${LDFLAGS}")
set(CFG_ENV_VAR ${CFG_ENV_VAR} libzmq_have_xmlto=no libzmq_have_asciidoc=no)

set(CFG_OPTS --prefix=${BINARY_DIR} --libdir=${BINARY_DIR}/lib --disable-static --enable-shared --without-documentation --host=${CHOST})
if(DEFINED ENV{LEGACY} OR DEFINED ENV{POCKETBOOK})
    set(CFG_OPTS ${CFG_OPTS} --disable-eventfd)
endif()

set(CFG_CMD env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

if(DEFINED ENV{ANDROID})
    set(SED_CMD sh -c "${ISED} 's|version_type=none|version_type=linux|' libtool")
    set(SED_CMD "${SED_CMD} && ${ISED} 's|need_lib_prefix=no|need_lib_prefix=yes|' libtool")
    set(SED_CMD "${SED_CMD} && ${ISED} 's|need_version=no|need_version=yes|' libtool")
    set(SED_CMD "${SED_CMD} && ${ISED} 's|library_names_spec=.*|library_names_spec=\"\\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$versuffix \\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$major \\\\\$libname\\\\\$shared_ext\"|' libtool")
    set(SED_CMD "${SED_CMD} && ${ISED} 's|soname_spec=.*|soname_spec=\"\\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$major\"|' libtool")
endif()

set(FORCE_DYNAMLIB_VERSION sh -c "${ISED} \"s|-avoid-version||g\" src/Makefile.am")
set(SKIP_TEST sh -c "${ISED} \"s|tests||g\" Makefile.am")
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
    CONFIGURE_COMMAND COMMAND ${CFG_CMD} COMMAND ${SED_CMD}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} installdirs uninstall install
)
