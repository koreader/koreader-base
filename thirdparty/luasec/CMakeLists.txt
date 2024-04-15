cmake_minimum_required(VERSION 3.5.1)
project(luasec LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

assert_var_defined(AR)
assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(CRYPTO_LIB)
assert_var_defined(DYNLIB_LDFLAGS)
assert_var_defined(LUAINC)
assert_var_defined(LUALIB)
assert_var_defined(LUAPATH)
assert_var_defined(OPENSSL_DIR)
assert_var_defined(RANLIB)
assert_var_defined(SSL_LIB)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

string(APPEND CFLAGS " -DWITH_LUASOCKET -I. -I${LUAINC} -I${OPENSSL_DIR}/include")

set(LIBS "luasocket/libluasocket.a ${CRYPTO_LIB} ${SSL_LIB}")
if(LUALIB)
    string(APPEND LIBS " ${LUALIB}")
endif()

set(MAKE_CMD
    ${KO_MAKE_RECURSIVE}
    AR=${AR} RANLIB=${RANLIB}
    CC=${CC} CFLAGS=${CFLAGS}
    LDFLAGS=${DYNLIB_LDFLAGS}
    LIBS=${LIBS} EXTRA=${LIBS}
    LUACPATH=${LUAPATH} LUAPATH=${LUAPATH}
)

list(APPEND BUILD_CMD COMMAND ${MAKE_CMD} -C src/luasocket)
list(APPEND BUILD_CMD COMMAND ${MAKE_CMD} -C src ssl.so)

list(APPEND INSTALL_CMD COMMAND ${MAKE_CMD} -C src install)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/brunoos/luasec
    tags/v1.3.2
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
