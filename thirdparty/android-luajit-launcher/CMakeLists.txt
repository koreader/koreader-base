list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD 7z)
endif()
append_shared_lib_install_commands(INSTALL_CMD ioctl)
append_shared_lib_install_commands(INSTALL_CMD luajit-launcher)

external_project(
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
