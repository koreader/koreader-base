list(APPEND PATCH_FILES luajit.patch)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
)

list(APPEND BUILD_CMD COMMAND ninja)

if(MONOLIBTIC)
    append_install_commands(INSTALL_CMD lpeg.a DESTINATION ${STAGING_DIR}/lib)
else()
    append_binary_install_command(INSTALL_CMD lpeg.so DESTINATION common)
endif()
append_install_commands(INSTALL_CMD ${SOURCE_DIR}/re.lua DESTINATION common)

external_project(
    DOWNLOAD URL c9914cc6036d4afa2f49e5c659a214a5
    https://github.com/roberto-ieru/LPeg/archive/refs/tags/v1.1.0.tar.gz
    PATCH_OVERLAY overlay
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
