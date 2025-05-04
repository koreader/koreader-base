list(APPEND PATCH_FILES math_library.patch)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DPNG_DEBUG_POSTFIX=
    -DPNG_FRAMEWORK=FALSE
    -DPNG_HARDWARE_OPTIMIZATIONS=$<BOOL:${WANT_SIMD}>
    -DPNG_SHARED=$<NOT:$<BOOL:${MONOLIBTIC}>>
    -DPNG_STATIC=$<BOOL:${MONOLIBTIC}>
    -DPNG_TESTS=FALSE
    -DPNG_TOOLS=FALSE
)
# Rely on `-mfpu=neon` ifdefs for enabling NEON on 32bits ARM.
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "arm")
    list(APPEND CMAKE_ARGS -DPNG_ARM_NEON=on)
endif()

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD png16 VERSION 16)
endif()

external_project(
    DOWNLOAD URL be6cc9e411c26115db3b9eab1159a1d9
    https://github.com/pnggroup/libpng/archive/refs/tags/v1.6.48.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
