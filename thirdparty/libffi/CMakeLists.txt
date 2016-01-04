PROJECT(libffi)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)
assert_var_defined(HOST)
assert_var_defined(CC)
ep_get_source_dir(BINARY_DIR)
ep_get_source_dir(SOURCE_DIR)

set(CFG_CMD_STR "CC=\"${CC}\" ${SOURCE_DIR}/configure --prefix=${BINARY_DIR} --host=${HOST} --enable-static")
if(DEFINED SYSROOT)
    set(CFG_CMD_STR "${CFG_CMD_STR} CFLAGS=\"--sysroot ${SYSROOT}\"")
endif()

include(ExternalProject)
set(LIBFFI_VER "3.2.1")
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    URL ftp://sourceware.org/pub/libffi/libffi-${LIBFFI_VER}.tar.gz
    URL_MD5 83b89587607e3eb65c70d361f13bab43
    CONFIGURE_COMMAND sh -c ${CFG_CMD_STR}
    # skip the rest, we only need the header for glib
    BUILD_COMMAND $(MAKE) -j${PROCESSORS}
    INSTALL_COMMAND $(MAKE) -j${PROCESSORS} uninstall install
)
