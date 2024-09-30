list(APPEND PATCH_FILES
    cmake_tweaks.patch
    # Remove workarounds for standalone applications and add
    # a couple of actions to be used from the osx main menu.
    cocoa.patch
)
if(APPIMAGE)
    # Tweak pkg-config search path (allow system packages),
    # help stupid cmake find system libraries, and fail if
    # required features / subsystems can't be enabled.
    list(APPEND PATCH_FILES appimage.patch)
endif()

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DSDL2_DISABLE_SDL2MAIN=ON
    -DSDL_CMAKE_DEBUG_POSTFIX= # Remove 'd' suffix for the debug build library.
    -DSDL_SHARED=ON
    -DSDL_STATIC=OFF
    -DSDL_TEST=OFF
    # We don't need audio support.
    -DSDL_AUDIO=OFF
    -DSDL_LIBSAMPLERATE=OFF
)
if(APPIMAGE)
    list(APPEND CMAKE_ARGS
        # Miscellaneous video features/subsystems we don't care about.
        -DSDL_DIRECTFB=OFF
        -DSDL_KMSDRM=OFF
        -DSDL_RPI=OFF
        # No libdecor-0-dev package in Ubuntu Focal.
        -DSDL_WAYLAND_LIBDECOR=OFF
    )
endif()

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
