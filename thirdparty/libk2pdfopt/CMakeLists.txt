set(CMAKE_PATCH_FILE ${CMAKE_CURRENT_BINARY_DIR}/k2pdfopt_exports.cmake)
target_exports(k2pdfopt WRITE_TO_FILE ${CMAKE_PATCH_FILE} CDECLS koptcontext_cdecl)
list(APPEND PATCH_CMD COMMAND ${ISED} "\$p" -e "\$s|.*|include(${CMAKE_PATCH_FILE})|" lib/CMakeLists.txt)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DANDROID=${ANDROID}
)

list(APPEND BUILD_CMD COMMAND ${KO_NINJA_RECURSIVE})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_shared_lib_install_commands(INSTALL_CMD k2pdfopt VERSION 2)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/libk2pdfopt.git
    8f7a37803eab28005c586bdcf9bd4c775278bdae
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    SOURCE_SUBDIR lib
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
