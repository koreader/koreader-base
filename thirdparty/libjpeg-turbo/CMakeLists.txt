list(APPEND PATCH_FILES no_cmake_rpath_shenanigans.patch)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DENABLE_STATIC=OFF
    -DENABLE_SHARED=ON
    -DWITH_JAVA=OFF
    -DWITH_JPEG8=ON
    # Reproducible builds: use release date.
    -DBUILD=20240508
)
# Make sure we disable ASM if we don't support SIMD.
if(NOT WANT_SIMD)
    list(APPEND CMAKE_ARGS
        -DREQUIRE_SIMD=OFF
        -DWITH_SIMD=OFF
    )
endif()

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_shared_lib_install_commands(INSTALL_CMD jpeg VERSION 8)
append_shared_lib_install_commands(INSTALL_CMD turbojpeg)

external_project(
    DOWNLOAD GIT 3.0.3
    https://github.com/libjpeg-turbo/libjpeg-turbo.git
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
