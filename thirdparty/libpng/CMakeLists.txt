list(APPEND PATCH_FILES math_library.patch)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DPNG_DEBUG_POSTFIX=
    -DPNG_FRAMEWORK=FALSE
    -DPNG_TOOLS=FALSE
    -DPNG_STATIC=FALSE
    -DPNG_TESTS=FALSE
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_shared_lib_install_commands(INSTALL_CMD png16 VERSION 16)

external_project(
    DOWNLOAD URL ea2484c0d6845e937bd03aefe33f15eb
    https://github.com/pnggroup/libpng/archive/refs/tags/v1.6.41.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
