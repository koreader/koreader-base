list(APPEND PATCH_FILES
    cmake_tweaks.patch
    no_debug_fonts.patch
    trim_the_fat.patch
    simd_kill_switch.patch
    fix_valgrind_uninitialized_warning.patch
)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DANDROID=${ANDROID}
    -DBUILD_TRAINING_TOOLS=FALSE
    -DDISABLE_ARCHIVE=TRUE
    -DDISABLE_CURL=TRUE
    -DDISABLE_TIFF=TRUE
    -DENABLE_CCACHE=FALSE
    -DENABLE_NINJA_POOL=FALSE
    -DENABLE_PRECOMPILED_HEADERS=FALSE
    -DENABLE_SIMD=${WANT_SIMD}
    -DGRAPHICS_DISABLED=TRUE
    -DINSTALL_CONFIGS=FALSE
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

external_project(
    DOWNLOAD URL ad5c5e9ecca2a6c7f71c31b2b400d92b
    https://github.com/tesseract-ocr/tesseract/archive/refs/tags/5.5.4.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
