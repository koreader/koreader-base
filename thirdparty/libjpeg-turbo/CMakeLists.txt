list(APPEND PATCH_FILES no_cmake_rpath_shenanigans.patch)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DENABLE_SHARED=$<NOT:$<BOOL:${MONOLIBTIC}>>
    -DENABLE_STATIC=$<BOOL:${MONOLIBTIC}>
    -DWITH_JAVA=OFF
    -DWITH_JPEG8=ON
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
    append_shared_lib_install_commands(INSTALL_CMD turbojpeg VERSION 0.3.0)
endif()

external_project(
    DOWNLOAD GIT 3.0.4
    https://github.com/libjpeg-turbo/libjpeg-turbo.git
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
