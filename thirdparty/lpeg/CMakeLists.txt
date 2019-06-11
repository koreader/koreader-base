project(lpeg)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(DYNLIB_CFLAGS)
assert_var_defined(LUA_DIR)

# NOTE: probably needs a similar fix as LFS: https://github.com/keplerproject/luafilesystem/commit/a84d81bc52590f930e54f108099df5d155bdc8bf
set(BUILD_CMD sh -c "${CC} ${DYNLIB_CFLAGS} -I${LUA_DIR}/src -L${LUA_DIR} -lluajit -o lpeg.so lpcap.c lpcode.c lpprint.c lptree.c lpvm.c")

set(LPEG_VER "1.0.2")
include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    URL http://distcache.FreeBSD.org/ports-distfiles/lpeg-${LPEG_VER}.tar.gz
    URL_MD5 d342571886f1abcb7afe6a83d024d583
    BUILD_IN_SOURCE 1
    # skip configure
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
