list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED=$<NOT:$<BOOL:${MONOLIBTIC}>>
    -DBUILD_STATIC=ON
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD xxhash VERSION 0)
endif()

external_project(
    DOWNLOAD URL 918fa44277d81b1ac1d02ac075df4ec1
    https://github.com/Cyan4973/xxHash/archive/refs/tags/v0.8.4.tar.gz
    PATCH_OVERLAY overlay
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
