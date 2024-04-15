cmake_minimum_required(VERSION 3.15)
project(libk2pdfopt LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

list(APPEND CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF})

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/benoit-pierre/libk2pdfopt.git
    365dce883f56e00842c27cc6fa63e3cd8b590880
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    CMAKE_ARGS ${CMAKE_ARGS}
    SOURCE_SUBDIR lib
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
