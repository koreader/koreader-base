list(APPEND PATCH_FILES
    # Remove workarounds for standalone applications and add
    # a couple of actions to be used from the osx main menu.
    cocoa.patch
)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DSDL2_DISABLE_SDL2MAIN=ON
    -DSDL_AUDIO=OFF
    -DSDL_CMAKE_DEBUG_POSTFIX= # Remove 'd' suffix for the debug build library.
    -DSDL_SHARED=ON
    -DSDL_STATIC=OFF
    -DSDL_TEST=OFF
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_shared_lib_install_commands(INSTALL_CMD SDL2-2.0 VERSION 0)

external_project(
    DOWNLOAD URL ab12cc1cf58a5dd25e69c924acb93402
    https://github.com/libsdl-org/SDL/releases/download/release-2.30.6/SDL2-2.30.6.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
