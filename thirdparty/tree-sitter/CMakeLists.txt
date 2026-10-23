list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DAMALGAMATED=ON
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_shared_lib_install_commands(INSTALL_CMD tree-sitter VERSION 0.27)

external_project(
    DOWNLOAD URL 4075094f5b7f7dbe637a361aee4e622d
    https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v0.27.1.tar.gz
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
