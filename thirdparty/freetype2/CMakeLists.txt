cmake_minimum_required(VERSION 3.15)
project(freetype2 LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}")

list(APPEND CMAKE_ARGS "-DBUILD_SHARED_LIBS=TRUE")
list(APPEND CMAKE_ARGS "-DDISABLE_FORCE_DEBUG_POSTFIX=TRUE")
list(APPEND CMAKE_ARGS "-DFT_DISABLE_BROTLI=TRUE")
list(APPEND CMAKE_ARGS "-DFT_DISABLE_BZIP2=TRUE")
list(APPEND CMAKE_ARGS "-DFT_DISABLE_HARFBUZZ=TRUE")
list(APPEND CMAKE_ARGS "-DFT_DISABLE_PNG=TRUE")
list(APPEND CMAKE_ARGS "-DFT_DISABLE_ZLIB=TRUE")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_PROGRAM} install)

thirdparty_project(
    URL https://github.com/freetype/freetype/archive/refs/tags/VER-2-13-2.tar.gz
    URL_MD5 dcd1af080e43fe0c984c34bf3e7d5e16
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
