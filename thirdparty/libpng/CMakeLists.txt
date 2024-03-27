list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/math_library.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

list(APPEND CMAKE_ARGS "-DPNG_DEBUG_POSTFIX=")
list(APPEND CMAKE_ARGS "-DPNG_TOOLS=FALSE")
list(APPEND CMAKE_ARGS "-DPNG_STATIC=FALSE")
list(APPEND CMAKE_ARGS "-DPNG_TESTS=FALSE")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

set(LIB_SPEC png16 VERSION 16)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${LIB} ${LIB_SPEC})

# CMake <= 3.20 `FindPNG` module is bugged: install a `libpng16d.so` symlink
# so our version is picked up over the system one when compiling the emulator.
list(APPEND INSTALL_CMD COMMAND ln -snf ${LIB} "${STAGING_DIR}/lib/libpng16d${LIB_EXT}")

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    "${BINARY_DIR}/pnglibconf.h"
    FROM "${SOURCE_DIR}"
    png.h pngconf.h
)

thirdparty_project(
    URL https://github.com/pnggroup/libpng/archive/refs/tags/v1.6.41.tar.gz
    URL_MD5 ea2484c0d6845e937bd03aefe33f15eb
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
