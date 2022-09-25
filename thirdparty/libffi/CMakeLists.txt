project(libffi)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)

assert_var_defined(HOST)
assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(BINARY_DIR)
ep_get_source_dir(SOURCE_DIR)

set(CFG_CMD sh -c "CC=\"${CC}\" CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\" ${SOURCE_DIR}/configure --prefix=${BINARY_DIR} --libdir=${BINARY_DIR}/lib --host=${HOST} --enable-static")
if(DEFINED SYSROOT)
    set(CFG_CMD "${CFG_CMD} CFLAGS=\"--sysroot ${SYSROOT}\"")
endif()

include(ExternalProject)
set(LIBFFI_VER "3.4.3")
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    URL https://sourceware.org/pub/libffi/libffi-${LIBFFI_VER}.tar.gz
    URL_MD5 b57b0ac1d1072681cee9148a417bd2ec
    CONFIGURE_COMMAND ${CFG_CMD}
    # skip the rest, we only need the header for glib
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} uninstall install
)
