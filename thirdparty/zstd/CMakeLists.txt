list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}
    # Project options.
    -DZSTD_BUILD_PROGRAMS=FALSE
    -DZSTD_BUILD_SHARED=TRUE
    -DZSTD_BUILD_STATIC=FALSE
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_shared_lib_install_commands(INSTALL_CMD zstd VERSION 1)

external_project(
    URL https://github.com/facebook/zstd/releases/download/v1.5.5/zstd-1.5.5.tar.gz
    URL_MD5 63251602329a106220e0a5ad26ba656f
    SOURCE_SUBDIR build/cmake
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
