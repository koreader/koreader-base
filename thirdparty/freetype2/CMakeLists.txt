list(APPEND CFG_CMD COMMAND
    ${MESON_SETUP} --default-library=shared
    -Dmmap=enabled
    -Dzlib=disabled
    ${SOURCE_DIR}
)
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    list(APPEND CMAKE_ARGS -DFT_ENABLE_ERROR_STRINGS=TRUE)
endif()

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${MESON_INSTALL})

set(LIB_SPEC freetype)
if(NOT ANDROID)
    list(APPEND LIB_SPEC VERSION 6)
endif()
if(APPLE)
    append_shared_lib_fix_commands(INSTALL_CMD ${LIB_SPEC} ID)
endif()
append_shared_lib_install_commands(INSTALL_CMD ${LIB_SPEC})

external_project(
    DOWNLOAD URL dcd1af080e43fe0c984c34bf3e7d5e16
    https://github.com/freetype/freetype/archive/refs/tags/VER-2-13-2.tar.gz
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
