if(LEGACY)
    # Revert 8d7a98d on legacy devices, pipe2 was introduced in Linux 2.6.27 & glibc 2.9
    list(APPEND PATCH_FILES kindle_legacy.patch)
endif()

list(APPEND CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

external_project(
    # NOTE: As of right now (1f9eaf4eeef348d1efe0f3c7fe8ab670653cfbb1),
    # wait until stuff settles down before bumping this.
    DOWNLOAD GIT e715396a4951ee91c40a98d2824a130f158268bb
    https://github.com/famzah/popen-noshell.git
    PATCH_OVERLAY overlay
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
