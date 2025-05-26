list(APPEND PATCH_FILES
    android.patch
    no-subset.patch
)

# Get rid of a bunch of `#line` directives that trip ccache 4.9.1.
# NOTE: this has also the nice effect of "touching" each file, so
# the build system does not try to regenerate them (and building
# without ragel is consistently possible).
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

list(APPEND CFG_CMD COMMAND
    ${MESON_SETUP} --default-library=$<IF:$<BOOL:${MONOLIBTIC}>,static,shared>
    -Dfreetype=enabled
    -Dtests=disabled
    -Dutilities=disabled
    ${SOURCE_DIR}
)

set(DEFINES
    HB_DISABLE_DEPRECATED
    HB_NO_BUFFER_MESSAGE
    HB_NO_BUFFER_SERIALIZE
    HB_NO_COLOR
    HB_NO_LAYOUT_COLLECT_GLYPHS
    HB_NO_LAYOUT_RARELY_USED
    HB_NO_LAYOUT_UNUSED
    HB_NO_META
    HB_NO_PAINT
    HB_NO_STYLE
)

# We've apparently hit a weird corner-case w/ XText where GCC/STL atomics *sometimes* horribly blow up on an ARM1136JF-S CPU w/ GCC 7.5 & up...
# c.f., https://github.com/koreader/koreader/issues/5780 & https://github.com/koreader/koreader/issues/6024
# NOTE: Our initial approach was to only disable atomics in a very dirty manner, which only helped with the first issue.
#       This, on the other hand, appears to help with both.
if(LEGACY OR POCKETBOOK)
    list(APPEND DEFINES HB_NO_MT)
endif()

list(APPEND CFG_CMD COMMAND sh -c "printf '#define %s\\n' \"$@\" >>config.h" -- ${DEFINES})

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${MESON_INSTALL})

if(NOT MONOLIBTIC)
    set(LIB_SPEC harfbuzz VERSION 0)
    if(APPLE)
        append_shared_lib_fix_commands(INSTALL_CMD ${LIB_SPEC} ID)
    endif()
    append_shared_lib_install_commands(INSTALL_CMD ${LIB_SPEC})
endif()

external_project(
    DOWNLOAD URL 53d77e130fc16e95c4e8a09c0c6fbd85
    https://github.com/harfbuzz/harfbuzz/releases/download/11.2.1/harfbuzz-11.2.1.tar.xz
    PATCH_FILES ${PATCH_FILES}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
