list(APPEND CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

external_project(
    # NOTE: 53a657318af1fccc4bac7ed230729302b2391d1d is the tip
    # of the 1.2 branch. The fcrypt API we need is gone in master.
    # FIXME: Even then, something in said branch seems to upset MuPDF
    # with our custom patch as-is, so keep using the current code...
    DOWNLOAD GIT 0b46a2b4ca317b80bc53594688883f7188ac4d08
    https://github.com/nmoinvaz/minizip
    PATCH_OVERLAY overlay
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
