list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DZLIB_BUILD_TESTING=FALSE
)

list(APPEND BUILD_CMD COMMAND ninja zlib zlibstatic)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_install_commands(INSTALL_CMD ${SOURCE_DIR}/contrib/minizip/crypt.h DESTINATION ${STAGING_DIR}/include/contrib/minizip)
if(MONOLIBTIC)
    # The CMake build system does not support building & installing only
    # a static / shared library, so we have to manually cleanup after the
    # install step.
    list(APPEND INSTALL_CMD COMMAND sh -c "rm -v \"$1\"*" -- ${STAGING_DIR}/lib/libz${LIB_EXT})
else()
    append_shared_lib_install_commands(INSTALL_CMD z VERSION 1)
endif()

external_project(
    DOWNLOAD URL be8a129ec5d60c5084911fd7ea16d84e
    https://github.com/madler/zlib/releases/download/v1.3.2/zlib-1.3.2.tar.xz
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
