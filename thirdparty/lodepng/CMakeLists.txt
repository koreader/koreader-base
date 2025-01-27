list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD lodepng)
endif()

external_project(
    DOWNLOAD GIT 0b1d9ccfc2093e5d6620cd9a11d03ee6ff6705f5
    https://github.com/lvandeve/lodepng.git
    PATCH_OVERLAY overlay
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
