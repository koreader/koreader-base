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
if(GLIBC_VERSION_MAX AND GLIBC_VERSION_MAX VERSION_LESS "2.8")
    # Avoid pulling-in `__asprintf_chk@GLIBC_2.8` and `__vasprintf_chk@GLIBC_2.8`.
    list(APPEND CMAKE_ARGS -DHAVE_ASPRINTF=FALSE)
endif()

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD crypto VERSION 57)
    append_shared_lib_install_commands(INSTALL_CMD ssl VERSION 60)
endif()

external_project(
    DOWNLOAD URL ed2f4274ed8f2733ab257f0fe97aedaf
    https://github.com/libressl/portable/releases/download/v4.4.0/libressl-4.4.0.tar.gz
    https://cloudflare.cdn.openbsd.org/pub/OpenBSD/LibreSSL/libressl-4.4.0.tar.gz
    https://cdn.openbsd.org/pub/OpenBSD/LibreSSL/libressl-4.4.0.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
