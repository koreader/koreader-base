PROJECT(libjpeg-turbo)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(LIBTOOLIZE libtoolize)
if(APPLE)
    set(LIBTOOLIZE glibtoolize)
endif()

set(CFG_ENV_VAR "CC=\"${CC}\" CXX=\"${CXX}\" CPPFLAGS=\"${CPPFLAGS}\" LDFLAGS=\"${LDFLAGS}\" ")
set(CFG_OPTS "-q --prefix=${BINARY_DIR} --host=\"${CHOST}\" --disable-static --enable-shared --with-jpeg8")
if(${WITHOUT_SIMD})
    set(CFG_OPTS "${CFG_OPTS} --without-simd")
endif(${WITHOUT_SIMD})
set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/libjpeg-turbo/libjpeg-turbo.git
    1.5.0
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    libjpeg-turbo
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${LIBTOOLIZE} COMMAND aclocal COMMAND autoheader COMMAND autoconf COMMAND automake --force-missing --add-missing
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS} --silent
    INSTALL_COMMAND $(MAKE) -j${PARALLEL_JOBS} --silent install
)
