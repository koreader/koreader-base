list(APPEND CFG_CMD COMMAND
    ${MESON_SETUP} --default-library=shared
    -Dbin=false
    -Ddocs=false
    -Dtests=false
    ${SOURCE_DIR}
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${MESON_INSTALL})

set(LIB_SPEC fribidi)
if(NOT ANDROID)
    list(APPEND LIB_SPEC VERSION 0)
endif()
if(APPLE)
    append_shared_lib_fix_commands(INSTALL_CMD ${LIB_SPEC} ID)
endif()
append_shared_lib_install_commands(INSTALL_CMD ${LIB_SPEC})

external_project(
    DOWNLOAD URL 25d1e5097fa621c0412c1a1c89ce857a
    https://github.com/fribidi/fribidi/releases/download/v1.0.14/fribidi-1.0.14.tar.xz
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
