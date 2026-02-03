list(APPEND PATCH_FILES
    cmake_tweaks.patch
    extended.patch
)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
    # Project options.
    -DXTENDED_DIR=${CMAKE_CURRENT_SOURCE_DIR}/xtended
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD lunasvg)
endif()

external_project(
    DOWNLOAD GIT v2.3.9
    https://github.com/sammycage/lunasvg.git
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/xtended/*
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
