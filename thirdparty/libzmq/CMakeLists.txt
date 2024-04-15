cmake_minimum_required(VERSION 3.5.1)
project(libzmq LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CXX)
assert_var_defined(CFLAGS)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)

list(APPEND PATCH_CMD COMMAND ./autogen.sh)
# Force dynamic lib version.
list(APPEND PATCH_CMD COMMAND ${ISED} "s|-avoid-version||g" src/Makefile.am)
# Skip tests.
list(APPEND PATCH_CMD COMMAND ${ISED} "s|tests||g" Makefile.am)
# Clear build dir every time so make install won't fail.
list(APPEND PATCH_CMD COMMAND ${CMAKE_COMMAND} -E remove_directory ${BINARY_DIR} COMMAND ${CMAKE_COMMAND} -E make_directory ${BINARY_DIR})

# added -Wno-unused-result in CXXFLAGS to ignore sodium_init() warning
list(APPEND CFG_ENV_VAR "CC=${CC}" "CXX=${CXX}" "CFLAGS=${CFLAGS}" "CXXFLAGS=${CXXFLAGS} -Wno-unused-result" "LDFLAGS=${LDFLAGS}")
list(APPEND CFG_ENV_VAR libzmq_have_xmlto=no libzmq_have_asciidoc=no)

list(APPEND CFG_OPTS --prefix=${INSTALL_DIR} --disable-static --enable-shared --without-documentation --host=${CHOST})
if(DEFINED ENV{LEGACY} OR DEFINED ENV{POCKETBOOK})
    list(APPEND CFG_OPTS --disable-eventfd)
endif()

list(APPEND CFG_CMD COMMAND env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

if(DEFINED ENV{ANDROID})
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} install)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/zeromq/libzmq
    883e95b22e0bffffa72312ea1fec76199afbe458
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
