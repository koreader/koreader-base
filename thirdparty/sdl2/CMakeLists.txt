project(sdl LANGUAGES)

# remove workarounds for standalone applications and add a couple of actions
# to be used from the osx main menu.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/cocoa.patch)

list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")

# Project options.
list(APPEND CMAKE_ARGS
    -DSDL_TEST=OFF
    -DSDL_SHARED=ON
    -DSDL_STATIC=OFF
    -DSDL_AUDIO=OFF
)

list(APPEND BUILD_CMD ${KO_MAKE_PROGRAM})

# Install shared lib.
set(BUILD_LIB "libSDL2-2.0")
if(CMAKE_BUILD_TYPE STREQUAL Debug)
    string(APPEND BUILD_LIB "d")
endif()
string(APPEND BUILD_LIB "${LIB_EXT}")
append_shared_lib_install_command(INSTALL_CMD "${BUILD_LIB}" SDL2)

set(SDL2_VER "2.28.1")
set(SDL2_MD5 "ccd2cd02b2ad4f71c2588747028953c3")

thirdparty_project(
    BUILD_ALWAYS
    URL https://github.com/libsdl-org/SDL/releases/download/release-${SDL2_VER}/SDL2-${SDL2_VER}.tar.gz
    URL_MD5 ${SDL2_MD5}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
