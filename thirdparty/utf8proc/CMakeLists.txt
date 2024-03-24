cmake_minimum_required(VERSION 3.5.1)
project(utf8proc LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}")

list(APPEND CMAKE_ARGS "-DBUILD_SHARED_LIBS=ON")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_PROGRAM} install)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/JuliaStrings/utf8proc.git
    v2.9.0
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
