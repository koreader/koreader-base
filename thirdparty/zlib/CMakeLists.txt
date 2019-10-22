project(zlib)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)

if($ENV{ANDROID})
    assert_var_defined(CHOST)

    set(LDFLAGS "${LDFLAGS} -shared -Wl,-soname,libz.so.1")
    # Only set CHOST for Android.
    # This can't be done generically because otherwise you have to specify soname as well.
    # See <https://github.com/koreader/koreader/issues/3523>.
    set(CFG_ENV_VAR "${CFG_ENV_VAR} CHOST=\"${CHOST}\"")
endif()

if($ENV{WIN32})
    # configure
    # build
    set(BUILD_VARS DESTDIR=${SOURCE_DIR} INCLUDE_PATH=include LIBRARY_PATH=lib BIN_PATH=bin)
    set(BUILD_ARGS CC="${CC}" CFLAGS="${CFLAGS}" RC="${CHOST}-windres" SHARED_MODE=1)
    # TODO: also use -j for windows?
    set(BUILD_CMD ${BUILD_VARS} ${KO_MAKE_RECURSIVE} -f win32/Makefile.gcc ${BUILD_ARGS})
    # install
    set(INSTALL_CMD ${BUILD_VARS} ${KO_MAKE_RECURSIVE} -f win32/Makefile.gcc ${BUILD_ARGS} install)
else()
    # configure
    set(CFG_ENV_VAR "${CFG_ENV_VAR} CC=\"${CC}\" CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\"")
    set(CFG_OPTS "${CFG_OPTS} --prefix=${SOURCE_DIR}")
    set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")
    # build
    set(BUILD_CMD ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} shared static)
    # install
    set(INSTALL_CMD ${KO_MAKE_RECURSIVE} install)
endif()

include(ExternalProject)
set(ZLIB_VER "1.2.11")
set(ZLIB_MD5 "1c9f62f0778697a09d36121ead88e08e")
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    URL http://gentoo.osuosl.org/distfiles/zlib-${ZLIB_VER}.tar.gz
    URL_MD5 ${ZLIB_MD5}
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
