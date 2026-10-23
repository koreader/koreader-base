list(APPEND PATCH_FILES
    visibility.patch
    # Prefer our CA bundle.
    ca_bundle.patch
    # Check SSL certificate matches hostname.
    check_hostname.patch
    # Enable SSL verification by default.
    default_verify.patch
)

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
    DOWNLOAD GIT bf4770833c0f1b3a45f116f2f29168d67d0ce7a0 # v1.3.2-15-gbf47708
    https://github.com/lunarmodules/luasec
    PATCH_OVERLAY overlay
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
