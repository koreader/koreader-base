cmake_minimum_required(VERSION 3.5.1)
project(lunasvg LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/extended.patch)
list(APPEND PATCH_CMD COMMAND cp -rpv ${CMAKE_CURRENT_SOURCE_DIR}/xtended ${SOURCE_DIR}/)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
    -DBUILD_SHARED_LIBS=ON
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/sammycage/lunasvg.git
    59d6f6ba835c1b7c7a0f9d4ea540ec3981777885
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
