cmake_minimum_required(VERSION 3.5.1)
project(sdl2 LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

# remove workarounds for standalone applications and add a couple of actions
# to be used from the osx main menu.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/cocoa.patch)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}
    # Project options.
    -DSDL_AUDIO=OFF
    -DSDL_CMAKE_DEBUG_POSTFIX= # Remove 'd' suffix for the debug build library.
    -DSDL_SHARED=ON
    -DSDL_STATIC=OFF
    -DSDL_TEST=OFF
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

external_project(
    URL https://github.com/libsdl-org/SDL/releases/download/release-2.28.5/SDL2-2.28.5.tar.gz
    URL_MD5 a344eb827a03045c9b399e99af4af13d
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
)
