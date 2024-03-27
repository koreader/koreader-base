# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

string(APPEND CFLAGS " -DWITH_LUASOCKET -I. -I${STAGING_DIR}/include")

set(LIBS "luasocket/libluasocket.a ${STAGING_DIR}/lib/libcrypto${LIB_EXT} ${STAGING_DIR}/lib/libssl${LIB_EXT}")
if(USE_LUAJIT_LIB)
    string(APPEND LIBS " ${STAGING_DIR}/lib/libluajit${LIB_EXT}")
endif()

set(MAKE_CMD
    ${KO_MAKE_RECURSIVE}
    "AR=${AR}" "RANLIB=${RANLIB}"
    "CC=${CC}" "CFLAGS=${CFLAGS}"
    "LDFLAGS=${DYNLIB_LDFLAGS}"
    "LIBS=${LIBS}" "EXTRA=${LIBS}"
)

list(APPEND BUILD_CMD COMMAND ${MAKE_CMD} -C src/luasocket)
list(APPEND BUILD_CMD COMMAND ${MAKE_CMD} -C src ssl.so)

append_binary_install_command(INSTALL_CMD BYPRODUCTS src/ssl.so common/)
append_install_commands(INSTALL_CMD BYPRODUCTS src/ssl.lua DESTINATION common/)
append_install_commands(INSTALL_CMD BYPRODUCTS src/https.lua DESTINATION common/ssl/)

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
    BYPRODUCTS ${BYPRODUCTS}
)
