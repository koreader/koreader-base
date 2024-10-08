list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DZSTD_BUILD_PROGRAMS=FALSE
    -DZSTD_BUILD_SHARED=$<NOT:$<BOOL:${MONOLIBTIC}>>
    -DZSTD_BUILD_STATIC=$<BOOL:${MONOLIBTIC}>
    -DZSTD_LEGACY_SUPPORT=FALSE
    -DZSTD_MULTITHREAD_SUPPORT=FALSE
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD zstd VERSION 1)
endif()

external_project(
    DOWNLOAD URL 5a473726b3445d0e5d6296afd1ab6854
    https://github.com/facebook/zstd/releases/download/v1.5.6/zstd-1.5.6.tar.gz
    SOURCE_SUBDIR build/cmake
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
