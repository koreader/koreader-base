# Get rid of a bunch of `#line` directives that trip ccache 4.9.1.
list(APPEND PATCH_CMD COMMAND ${ISED} "/^#line/d"
    src/hb-ot-shaper-khmer-machine.hh
    src/hb-ot-shaper-use-machine.hh
    src/hb-ot-shaper-myanmar-machine.hh
    src/hb-buffer-deserialize-json.hh
    src/hb-buffer-deserialize-text-glyphs.hh
    src/hb-number-parser.hh
    src/hb-ot-shaper-indic-machine.hh
    src/hb-buffer-deserialize-text-unicode.hh
)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/android.patch)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/optional-ragel.patch)

# We've apparently hit a weird corner-case w/ XText where GCC/STL atomics *sometimes* horribly blow up on an ARM1136JF-S CPU w/ GCC 7.5...
# c.f., https://github.com/koreader/koreader/issues/5780 & https://github.com/koreader/koreader/issues/6024
# NOTE: Our initial approach was to only disable atomics in a very dirty manner, which only helped with the first issue.
#       This, on the other hand, appears to help with both.
if(LEGACY OR POCKETBOOK)
    list(APPEND PATCH_CMD COMMAND ${ISED} "/^#define HB_CONFIG_HH\$/{p$<SEMICOLON>s//#define HB_NO_MT/}" src/hb-config.hh)
endif()

list(APPEND CFG_CMD COMMAND env
    ${MESON_SETUP} --default-library=shared
    -Dfreetype=enabled
    -Dtests=disabled
    -Dutilities=disabled
    "${SOURCE_DIR}"
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM} lib)

set(LIB_SPEC harfbuzz VERSION 0)
set_libname(LIB ${LIB_SPEC})

# Remove extranenous build-time rpath entries.
if(NOT DARWIN AND NOT WIN32)
    list(APPEND BUILD_CMD COMMAND chrpath -r "$ORIGIN:$ORIGIN/libs" src/${LIB})
endif()

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS src/${LIB} ${LIB_SPEC})

# Install headers.
# NOTE: to get an updated list, check the contents
# of `cmake_install.cmake` in the build directory.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    FROM "${SOURCE_DIR}/src"
    hb-aat-layout.h hb-aat.h hb-blob.h hb-buffer.h hb-common.h
    hb-cplusplus.hh hb-deprecated.h hb-draw.h hb-face.h hb-font.h
    hb-map.h hb-ot-color.h hb-ot-deprecated.h hb-ot-font.h
    hb-ot-layout.h hb-ot-math.h hb-ot-meta.h hb-ot-metrics.h
    hb-ot-name.h hb-ot-shape.h hb-ot-var.h hb-ot.h hb-paint.h
    hb-set.h hb-shape-plan.h hb-shape.h hb-style.h hb-unicode.h
    hb-version.h hb.h hb-ft.h hb-subset.h
)

thirdparty_project(
    URL https://github.com/harfbuzz/harfbuzz/releases/download/8.3.1/harfbuzz-8.3.1.tar.xz
    URL_MD5 fc4c1c0cb2e8a190db5007936f290047
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
