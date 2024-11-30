list(APPEND PATCH_FILES
    fix_meson_bzip2_option.patch
    # Work around GCC 12 ARM NEON bug (https://gcc.gnu.org/bugzilla/show_bug.cgi?id=117811).
    ftcalc_gcc12_arm_neon_fix.patch
)

list(APPEND CFG_CMD COMMAND
    ${MESON_SETUP} --default-library=$<IF:$<BOOL:${MONOLIBTIC}>,static,shared>
    -Dmmap=enabled
    -Dzlib=disabled
    ${SOURCE_DIR}
)
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    list(APPEND CMAKE_ARGS -DFT_ENABLE_ERROR_STRINGS=TRUE)
endif()

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${MESON_INSTALL})

if(NOT MONOLIBTIC)
    set(LIB_SPEC freetype VERSION 6)
    if(APPLE)
        append_shared_lib_fix_commands(INSTALL_CMD ${LIB_SPEC} ID)
    endif()
    append_shared_lib_install_commands(INSTALL_CMD ${LIB_SPEC})
endif()

external_project(
    DOWNLOAD URL 4425315beb50f913ae12d643e4e121e1
    https://github.com/freetype/freetype/archive/refs/tags/VER-2-13-3.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
