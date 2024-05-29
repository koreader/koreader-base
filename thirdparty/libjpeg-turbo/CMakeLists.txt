list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/no_cmake_rpath_shenanigans.patch)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DENABLE_STATIC=OFF
    -DENABLE_SHARED=ON
    -DWITH_JAVA=OFF
    -DWITH_JPEG8=ON
    # Reproducible builds: use release date.
    -DBUILD=20240124
)
# Make sure we disable ASM if we don't support SIMD.
if(NOT WANT_SIMD)
    list(APPEND CMAKE_ARGS
        -DREQUIRE_SIMD=OFF
        -DWITH_SIMD=OFF
    )
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_shared_lib_install_commands(INSTALL_CMD jpeg VERSION 8)
append_shared_lib_install_commands(INSTALL_CMD turbojpeg)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/libjpeg-turbo/libjpeg-turbo.git
    3.0.2
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
