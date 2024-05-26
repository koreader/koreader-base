list(APPEND CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM} zlib zlibstatic)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_install_commands(INSTALL_CMD ${SOURCE_DIR}/contrib/minizip/crypt.h DESTINATION ${STAGING_DIR}/include/contrib/minizip)
append_shared_lib_install_commands(INSTALL_CMD z VERSION 1)

external_project(
    URL https://github.com/madler/zlib/releases/download/v1.3/zlib-1.3.tar.xz
    URL_MD5 b49e70aacafacfceb1107943497f5545
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
