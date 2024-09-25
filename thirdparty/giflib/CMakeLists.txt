if(ANDROID)
    # Use `limits.h` instead of `stdint.h`.
    list(APPEND PATCH_CMD COMMAND ${ISED} "s|stdint.h|limits.h|g" openbsd-reallocarray.c)
endif()

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD gif VERSION 7)
endif()

external_project(
    DOWNLOAD URL 913dd251492134e235ee3c9a91987a4d
    https://sourceforge.net/projects/giflib/files/giflib-5.2.2.tar.gz
    PATCH_OVERLAY overlay
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
