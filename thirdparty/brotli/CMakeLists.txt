list(APPEND PATCH_FILES cmake_tweaks.patch)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=FALSE
    # Project options.
    -DBROTLI_DISABLE_TESTS=TRUE
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

external_project(
    DOWNLOAD URL 3a6a3dba82a3604792d3cb0bd41bca60
    https://github.com/google/brotli/archive/refs/tags/v1.1.0.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
