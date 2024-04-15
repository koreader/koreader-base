cmake_minimum_required(VERSION 3.5.1)
project(sdl2 LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

# remove workarounds for standalone applications and add a couple of actions
# to be used from the osx main menu.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/cocoa.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

# Project options.
list(APPEND CMAKE_ARGS
    -DSDL_AUDIO=OFF
    -DSDL_CMAKE_DEBUG_POSTFIX=
    -DSDL_SHARED=ON
    -DSDL_STATIC=OFF
    -DSDL_TEST=OFF
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

set(SDL2_VER "2.28.5")
set(SDL2_MD5 "a344eb827a03045c9b399e99af4af13d")

external_project(
    URL https://github.com/libsdl-org/SDL/releases/download/release-${SDL2_VER}/SDL2-${SDL2_VER}.tar.gz
    URL_MD5 ${SDL2_MD5}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
)
