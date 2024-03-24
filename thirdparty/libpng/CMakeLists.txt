cmake_minimum_required(VERSION 3.5.1)
project(libpng LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(ZLIB_DIR)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/math_library.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}")

list(APPEND CMAKE_ARGS "-DPNG_DEBUG_POSTFIX=")
list(APPEND CMAKE_ARGS "-DPNG_TOOLS=FALSE")
list(APPEND CMAKE_ARGS "-DPNG_STATIC=FALSE")
list(APPEND CMAKE_ARGS "-DPNG_TESTS=FALSE")
list(APPEND CMAKE_ARGS "-DZLIB_ROOT=${ZLIB_DIR}")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_PROGRAM} install)

thirdparty_project(
    URL https://github.com/pnggroup/libpng/archive/refs/tags/v1.6.41.tar.gz
    URL_MD5 ea2484c0d6845e937bd03aefe33f15eb
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
