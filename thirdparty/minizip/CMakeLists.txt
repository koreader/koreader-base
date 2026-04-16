list(APPEND CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_install_commands(INSTALL_CMD ${SOURCE_DIR}/crypt.h DESTINATION ${STAGING_DIR}/include/contrib/minizip)

external_project(
    # NOTE: 53a657318af1fccc4bac7ed230729302b2391d1d is the tip
    # of the 1.2 branch. The fcrypt API we need is gone in master.
    # FIXME: Even then, something in said branch seems to upset MuPDF
    # with our custom patch as-is, so keep using the current code...
    DOWNLOAD GIT aa4758baea16e9dc03583340e62b370ea1140df9
    https://github.com/nmoinvaz/minizip
    PATCH_OVERLAY overlay
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
