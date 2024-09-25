list(APPEND PATCH_FILES visibility.patch)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
)

list(APPEND BUILD_CMD COMMAND ninja)

if(MONOLIBTIC)
    append_install_commands(INSTALL_CMD ssl.a DESTINATION ${STAGING_DIR}/lib)
else()
    append_binary_install_command(INSTALL_CMD ssl.so DESTINATION common)
endif()
append_install_commands(INSTALL_CMD ${SOURCE_DIR}/src/ssl.lua DESTINATION common)
append_install_commands(INSTALL_CMD ${SOURCE_DIR}/src/https.lua DESTINATION common/ssl)

external_project(
    DOWNLOAD GIT v1.3.2
    https://github.com/brunoos/luasec
    PATCH_OVERLAY overlay
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
