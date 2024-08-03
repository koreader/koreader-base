list(APPEND CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})

# Pre-emptively rename `zconf.h`: this is normaly done
# by `CMakeLists.txt` at configure time, and wreaks havoc
# with `build.d` generation. Since the later is done before
# configuring, a missing `zconf.h` would endlessly trigger
# a new zlib build.
list(APPEND PATCH_CMD COMMAND mv zconf.h zconf.h.included)

list(APPEND BUILD_CMD COMMAND ninja zlib zlibstatic)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_install_commands(INSTALL_CMD ${SOURCE_DIR}/contrib/minizip/crypt.h DESTINATION ${STAGING_DIR}/include/contrib/minizip)
append_shared_lib_install_commands(INSTALL_CMD z VERSION 1)

external_project(
    DOWNLOAD URL 5e6af153311327e516690d300527ec9e
    https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.xz
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
