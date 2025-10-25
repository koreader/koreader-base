list(APPEND PATCH_FILES cmake_tweaks.patch)
if(ANDROID)
    list(APPEND PATCH_FILES android.patch)
endif()

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
    append_shared_lib_install_commands(INSTALL_CMD crypto VERSION 57)
    append_shared_lib_install_commands(INSTALL_CMD ssl VERSION 60)
endif()

external_project(
    DOWNLOAD URL 985a9e1ac27d542857d666cdae2582b9
    https://cdn.openbsd.org/pub/OpenBSD/LibreSSL/libressl-4.2.0.tar.gz
    https://cloudflare.cdn.openbsd.org/pub/OpenBSD/LibreSSL/libressl-4.2.0.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
