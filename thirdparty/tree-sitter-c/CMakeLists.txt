list(APPEND PATCH_FILES no_tree-sitter-cli.patch)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    # Fix ABI to match the language version, like the
    # makefile (used by the Arch Linux package) does.
    -DTREE_SITTER_ABI_VERSION=15
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_shared_lib_install_commands(INSTALL_CMD tree-sitter-c VERSION 15.0)

external_project(
    DOWNLOAD URL 02c27c7a6f92ff9b3e201358d614a78d
    https://github.com/tree-sitter/tree-sitter-c/archive/refs/tags/v0.24.2.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
