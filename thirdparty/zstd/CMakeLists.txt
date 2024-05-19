cmake_minimum_required(VERSION 3.5.1)
project(zstd LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
    # Project options.
    -DZSTD_BUILD_PROGRAMS=FALSE
    -DZSTD_BUILD_SHARED=TRUE
    -DZSTD_BUILD_STATIC=FALSE
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/facebook/zstd.git
    tags/v1.5.5
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    SOURCE_SUBDIR build/cmake
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
