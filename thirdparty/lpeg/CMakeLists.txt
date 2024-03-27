# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/luajit.patch)

set(DLLFLAGS "${DYNLIB_LDFLAGS}")
if(USE_LUAJIT_LIB)
    string(APPEND DLLFLAGS " ${STAGING_DIR}/lib/libluajit${LIB_EXT}")
endif()

list(APPEND BUILD_CMD
    ${KO_MAKE_RECURSIVE}
    "CC=${CC}"
    "COPT=${CFLAGS}"
    "DLLFLAGS=${DLLFLAGS}"
    "LUADIR=${STAGING_DIR}/include"
    lpeg.so
)

append_binary_install_command(INSTALL_CMD BYPRODUCTS lpeg.so common/)
append_install_commands(INSTALL_CMD BYPRODUCTS re.lua DESTINATION common/)

thirdparty_project(
    URL http://distcache.FreeBSD.org/ports-distfiles/lpeg-1.0.2.tar.gz
    URL_MD5 d342571886f1abcb7afe6a83d024d583
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
