list(APPEND PATCH_FILES math_library.patch)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DPNG_DEBUG_POSTFIX=
    -DPNG_FRAMEWORK=FALSE
    -DPNG_TOOLS=FALSE
    -DPNG_SHARED=$<NOT:$<BOOL:${MONOLIBTIC}>>
    -DPNG_STATIC=$<BOOL:${MONOLIBTIC}>
    -DPNG_TESTS=FALSE
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD png16 VERSION 16)
endif()

external_project(
    DOWNLOAD URL dabdabca28f211feeba199d93235c703
    https://github.com/pnggroup/libpng/archive/refs/tags/v1.6.43.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
