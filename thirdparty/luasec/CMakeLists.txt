cmake_minimum_required(VERSION 3.15)
project(luasec LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

string(APPEND CFLAGS " -DWITH_LUASOCKET -I. -I${STAGING_DIR}/include")

set(LIBS "luasocket/libluasocket.a ${STAGING_DIR}/lib/libcrypto${LIB_EXT} ${STAGING_DIR}/lib/libssl${LIB_EXT}")
if(USE_LUAJIT_LIB)
    string(APPEND LIBS " ${STAGING_DIR}/lib/libluajit${LIB_EXT}")
endif()

set(LUAPATH "${OUTPUT_DIR}/common")

set(MAKE_CMD
    ${KO_MAKE_RECURSIVE}
    "AR=${AR}" "RANLIB=${RANLIB}"
    "CC=${CC}" "CFLAGS=${CFLAGS}"
    "LDFLAGS=${DYNLIB_LDFLAGS}"
    "LIBS=${LIBS}" "EXTRA=${LIBS}"
    "LUACPATH=${LUAPATH}" "LUAPATH=${LUAPATH}"
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

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
