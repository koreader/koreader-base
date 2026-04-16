list(APPEND PATCH_FILES
    no_cmake_rpath_shenanigans.patch
    no_12_or_16_bits_precision.patch
    no_simdcoverage_exe.patch
    hwcap_neon.patch
)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DENABLE_SHARED=$<NOT:$<BOOL:${MONOLIBTIC}>>
    -DENABLE_STATIC=$<BOOL:${MONOLIBTIC}>
    -DWITH_JAVA=OFF
    -DWITH_JPEG8=ON
    -DWITH_TESTS=OFF
    -DWITH_TOOLS=OFF
    # Make sure we disable ASM if we don't support SIMD.
    -DREQUIRE_SIMD=$<BOOL:${WANT_SIMD}>
    -DWITH_SIMD=$<BOOL:${WANT_SIMD}>
    # Reproducible builds: use release date.
    -DBUILD=20240508
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD jpeg VERSION 8)
    append_shared_lib_install_commands(INSTALL_CMD turbojpeg VERSION 0.4.0)
endif()

external_project(
    DOWNLOAD URL 997f868afac9f358a098617d16f36167
    https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.1.4.1/libjpeg-turbo-3.1.4.1.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
