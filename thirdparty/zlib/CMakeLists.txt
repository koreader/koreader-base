PROJECT(zlib)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)

ep_get_source_dir(SOURCE_DIR)

if(${MINGW})
    # configure
    set(optional_cfg_cmd "")
    # build
    set(BUILD_VARS DESTDIR=${SOURCE_DIR} INCLUDE_PATH=include LIBRARY_PATH=lib BIN_PATH=bin)
    set(BUILD_ARGS CC="${CC}" RC="${CHOST}-windres" SHARED_MODE=1)
    # TODO: also use -j for windows?
    set(BUILD_CMD ${BUILD_VARS} $(MAKE) -f win32/Makefile.gcc ${BUILD_ARGS})
    # install
    set(INSTALL_CMD ${BUILD_VARS} $(MAKE) -f win32/Makefile.gcc ${BUILD_ARGS} install)
else()
    # configure
    set(optional_cfg_cmd CONFIGURE_COMMAND sh -c "CC=\"${CC}\" ./configure --prefix=${SOURCE_DIR}")
    # build
    set(BUILD_CMD $(MAKE) -j${PROCESSOR_COUNT} --silent shared static)
    # install
    set(INSTALL_CMD $(MAKE) install)
endif()

include(ExternalProject)
set(ZLIB_VER "1.2.8")
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    URL http://zlib.net/zlib-${ZLIB_VER}.tar.gz
    URL_MD5 44d667c142d7cda120332623eab69f40
    BUILD_IN_SOURCE 1
    ${optional_cfg_cmd}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
