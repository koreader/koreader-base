list(APPEND PATCH_FILES
    # Drop duplicate cdefs, make sure turbo find its
    # libtffi_wrap library, and pull in upstream fixes.
    turbo.patch
    d7a8a247a4a2689b0f207162eb804141c87c4899.patch
)

# Remove the 7 years-old copy of a CA bundle that turbo doesn't actually use.
list(APPEND PATCH_CMD COMMAND rm turbo/ca-certificates.crt)
# Some of the LUA files are executables for no good reason.
list(APPEND PATCH_CMD COMMAND chmod a-x turbo/platform.lua turbo/socket_ffi.lua turbo/syscall.lua)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
)

list(APPEND BUILD_CMD COMMAND ninja)

if(MONOLIBTIC)
    append_install_commands(INSTALL_CMD libtffi_wrap.a DESTINATION ${STAGING_DIR}/lib)
else()
    append_binary_install_command(INSTALL_CMD libtffi_wrap${LIB_EXT} DESTINATION libs)
endif()
append_install_commands(INSTALL_CMD ${SOURCE_DIR}/turbo.lua ${SOURCE_DIR}/turbovisor.lua DESTINATION common)
append_tree_install_commands(INSTALL_CMD ${SOURCE_DIR}/turbo common/turbo)

external_project(
    DOWNLOAD GIT v2.1.3
    https://github.com/kernelsauce/turbo
    PATCH_OVERLAY overlay
    PATCH_FILES ${PATCH_FILES}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
