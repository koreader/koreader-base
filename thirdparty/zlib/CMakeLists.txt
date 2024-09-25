# Pre-emptively rename `zconf.h`: this is normaly done
# by `CMakeLists.txt` at configure time, and wreaks havoc
# with `build.d` generation. Since the later is done before
# configuring, a missing `zconf.h` would endlessly trigger
# a new zlib build.
list(APPEND PATCH_CMD COMMAND mv zconf.h zconf.h.included)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DINSTALL_PKGCONFIG_DIR=${STAGING_DIR}/lib/pkgconfig
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
    DOWNLOAD URL 5e6af153311327e516690d300527ec9e
    https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.xz
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
