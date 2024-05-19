cmake_minimum_required(VERSION 3.15)
project(lpeg LANGUAGES)

include("koreader_thirdparty_common")

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/luajit.patch)

string(JOIN " " DLLFLAGS ${DYNLIB_LDFLAGS} ${LUAJIT_LIB})

list(APPEND BUILD_CMD
    ${KO_MAKE_RECURSIVE}
    CC=${CC}
    COPT=${CFLAGS}
    DLLFLAGS=${DLLFLAGS}
    LUADIR=${LUAJIT_INC}
    lpeg.so
)

external_project(
    URL http://distcache.FreeBSD.org/ports-distfiles/lpeg-1.0.2.tar.gz
    URL_MD5 d342571886f1abcb7afe6a83d024d583
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
