cmake_minimum_required(VERSION 3.15)
project(freetype2 LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}
    # Options.
    -DBUILD_SHARED_LIBS=TRUE
    -DDISABLE_FORCE_DEBUG_POSTFIX=TRUE
    -DFT_DISABLE_BROTLI=TRUE
    -DFT_DISABLE_BZIP2=TRUE
    -DFT_DISABLE_HARFBUZZ=TRUE
    -DFT_DISABLE_PNG=TRUE
    -DFT_DISABLE_ZLIB=TRUE
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://gitlab.com/koreader/freetype2.git
    VER-2-13-2
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
