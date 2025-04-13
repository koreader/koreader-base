list(APPEND PATCH_FILES
    cmake_tweaks.patch
)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
    # Project options.
    -DLIBRESSL_APPS=OFF
    -DLIBRESSL_TESTS=OFF
    -DENABLE_ASM=${WANT_SIMD}
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD crypto VERSION 55)
    append_shared_lib_install_commands(INSTALL_CMD ssl VERSION 58)
endif()

external_project(
    DOWNLOAD URL 4775b6b187a93c527eeb95a13e6ebd64
    https://github.com/libressl/portable/releases/download/v4.0.0/libressl-4.0.0.tar.gz
    https://cdn.openbsd.org/pub/OpenBSD/LibreSSL/libressl-4.0.0.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
