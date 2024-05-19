cmake_minimum_required(VERSION 3.5.1)
project(harfbuzz LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(FREETYPE_DIR)

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

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/soversion.patch)

# We've apparently hit a weird corner-case w/ XText where GCC/STL atomics *sometimes* horribly blow up on an ARM1136JF-S CPU w/ GCC 7.5...
# c.f., https://github.com/koreader/koreader/issues/5780 & https://github.com/koreader/koreader/issues/6024
# NOTE: Our initial approach was to only disable atomics in a very dirty manner, which only helped with the first issue.
#       This, on the other hand, appears to help with both.
if(LEGACY OR POCKETBOOK)
    list(APPEND PATCH_CMD COMMAND ${ISED} "/^#define HB_CONFIG_HH\$/{p$<SEMICOLON>s//#define HB_NO_MT/}" src/hb-config.hh)
endif()

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
    # Options.
    -DBUILD_SHARED_LIBS=TRUE
    -DHB_BUILD_SUBSET=FALSE
    -DHB_HAVE_FREETYPE=TRUE
    -DHB_HAVE_GLIB=FALSE
    -DHB_HAVE_GRAPHITE2=FALSE
    -DHB_HAVE_ICU=FALSE
    -DHB_HAVE_CORETEXT=FALSE
    # Of course, `FindFreetype` does not honor `FREETYPE_ROOT`.
    -DFREETYPE_INCLUDE_DIRS=${FREETYPE_DIR}/include/freetype2
    -DFREETYPE_LIBRARY=-L${FREETYPE_DIR}/lib$<SEMICOLON>freetype
    # Disable Python support.
    -DPYTHONINTERP_FOUND=FALSE
    -DPYTHON_EXECUTABLE=
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

set(HB_VER 8.3.1)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/harfbuzz/harfbuzz.git
    ${HB_VER}
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
