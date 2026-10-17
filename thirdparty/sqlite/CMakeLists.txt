list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD sqlite3 VERSION 0)
endif()

external_project(
    DOWNLOAD URL 44b55a31f2d928521787bc48c6087937
    https://www.sqlite.org/2026/sqlite-amalgamation-3540100.zip
    https://www2.sqlite.org/2026/sqlite-amalgamation-3540100.zip
    https://www3.sqlite.org/2026/sqlite-amalgamation-3540100.zip
    PATCH_OVERLAY overlay
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
