# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

list(APPEND CMAKE_ARGS "-DZSTD_BUILD_PROGRAMS=FALSE")
list(APPEND CMAKE_ARGS "-DZSTD_BUILD_SHARED=TRUE")
list(APPEND CMAKE_ARGS "-DZSTD_BUILD_STATIC=FALSE")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

set(LIB_SPEC zstd VERSION 1)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS lib/${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    FROM "${SOURCE_DIR}/lib"
    zdict.h zstd.h zstd_errors.h
)

thirdparty_project(
    URL https://github.com/facebook/zstd/releases/download/v1.5.5/zstd-1.5.5.tar.gz
    URL_MD5 63251602329a106220e0a5ad26ba656f
    SOURCE_SUBDIR "build/cmake"
    CMAKE_ARGS "${CMAKE_ARGS}"
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
