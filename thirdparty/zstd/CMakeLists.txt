cmake_minimum_required(VERSION 3.15)
project(zstd LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}")

list(APPEND CMAKE_ARGS "-DZSTD_BUILD_PROGRAMS=FALSE")
list(APPEND CMAKE_ARGS "-DZSTD_BUILD_SHARED=TRUE")
list(APPEND CMAKE_ARGS "-DZSTD_BUILD_STATIC=FALSE")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_PROGRAM} install)

thirdparty_project(
    URL https://github.com/facebook/zstd/releases/download/v1.5.5/zstd-1.5.5.tar.gz
    URL_MD5 63251602329a106220e0a5ad26ba656f
    SOURCE_SUBDIR "build/cmake"
    CMAKE_ARGS "${CMAKE_ARGS}"
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
