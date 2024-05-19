cmake_minimum_required(VERSION 3.15)
project(zlib LANGUAGES)

include("koreader_thirdparty_common")

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM} zlib zlibstatic)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

list(APPEND INSTALL_CMD COMMAND mkdir -p ${INSTALL_DIR}/include/contrib/minizip)
list(APPEND INSTALL_CMD COMMAND cp ${SOURCE_DIR}/contrib/minizip/crypt.h ${INSTALL_DIR}/include/contrib/minizip/)

external_project(
    URL https://github.com/madler/zlib/releases/download/v1.3/zlib-1.3.tar.xz
    URL_MD5 b49e70aacafacfceb1107943497f5545
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
