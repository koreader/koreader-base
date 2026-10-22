list(APPEND CFG_CMD COMMAND
    ${MESON_SETUP} --default-library=$<IF:$<BOOL:${MONOLIBTIC}>,static,shared>
    -Derror_strings=$<IF:$<STREQUAL:${CMAKE_BUILD_TYPE},Debug>,true,false>
    -Dbrotli=enabled
    -Dharfbuzz=disabled
    -Dmmap=enabled
    -Dzlib=system
    ${SOURCE_DIR}
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${MESON_INSTALL})

if(NOT MONOLIBTIC)
    set(LIB_SPEC freetype VERSION 6)
    if(APPLE)
        append_shared_lib_fix_commands(INSTALL_CMD ${LIB_SPEC} ID)
    endif()
    append_shared_lib_install_commands(INSTALL_CMD ${LIB_SPEC})
endif()

external_project(
    DOWNLOAD URL a327f211fb238360c1e0ce3859e3a8e8
    https://github.com/freetype/freetype/archive/refs/tags/VER-2-15-0.tar.gz
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
