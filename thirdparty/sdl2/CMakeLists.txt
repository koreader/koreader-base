# remove workarounds for standalone applications and add a couple of actions
# to be used from the osx main menu.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/cocoa.patch)
# FIXME: koreader should really be using `libSDL2-2.0.so.0` instead.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/no_library_versioning.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

# No 'd' suffix for the debug build library.
list(APPEND CMAKE_ARGS "-DSDL_CMAKE_DEBUG_POSTFIX=")

# Project options.
list(APPEND CMAKE_ARGS
    -DSDL_AUDIO=OFF
    -DSDL_SHARED=ON
    -DSDL_STATIC=OFF
    -DSDL_TEST=OFF
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

set(LIB_SPEC SDL2)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${LIB} ${LIB_SPEC})

thirdparty_project(
    URL https://github.com/libsdl-org/SDL/releases/download/release-2.28.5/SDL2-2.28.5.tar.gz
    URL_MD5 a344eb827a03045c9b399e99af4af13d
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
