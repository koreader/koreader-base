list(APPEND PATCH_FILES
    iconv-proto-compat.patch
    miniconv-config.patch
)

list(APPEND PATCH_CMD COMMAND rm config.h)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=FALSE
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

external_project(
    DOWNLOAD URL 5871dfaced0f3d5f96c032f30b0590ae
    https://github.com/malord/miniconv/archive/170ddcb9ac8eda1e08e7426acecb6a5733cf1d36.tar.gz
    PATCH_FILES ${PATCH_FILES}
    PATCH_OVERLAY overlay
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
