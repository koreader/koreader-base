cmake_minimum_required(VERSION 3.15)
project(harfbuzz LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/soversion.patch)

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

# We've apparently hit a weird corner-case w/ XText where GCC/STL atomics *sometimes* horribly blow up on an ARM1136JF-S CPU w/ GCC 7.5...
# c.f., https://github.com/koreader/koreader/issues/5780 & https://github.com/koreader/koreader/issues/6024
# NOTE: Our initial approach was to only disable atomics in a very dirty manner, which only helped with the first issue.
#       This, on the other hand, appears to help with both.
if(LEGACY OR POCKETBOOK)
    list(APPEND PATCH_CMD COMMAND ${ISED} "/^#define HB_CONFIG_HH\$/{p$<SEMICOLON>s//#define HB_NO_MT/}" src/hb-config.hh)
endif()

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}")

list(APPEND CMAKE_ARGS "-DBUILD_SHARED_LIBS=TRUE")
list(APPEND CMAKE_ARGS "-DHB_BUILD_SUBSET=FALSE")
list(APPEND CMAKE_ARGS "-DHB_HAVE_FREETYPE=TRUE")
list(APPEND CMAKE_ARGS "-DHB_HAVE_GLIB=FALSE")
list(APPEND CMAKE_ARGS "-DHB_HAVE_GRAPHITE2=FALSE")
list(APPEND CMAKE_ARGS "-DHB_HAVE_ICU=FALSE")
if(DARWIN)
    list(APPEND CMAKE_ARGS "-DHB_HAVE_CORETEXT=FALSE")
endif()
# Disable Python support.
list(APPEND CMAKE_ARGS "-DPYTHONINTERP_FOUND=FALSE")
list(APPEND CMAKE_ARGS "-DPYTHON_EXECUTABLE=")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_PROGRAM} install)

thirdparty_project(
    URL https://github.com/harfbuzz/harfbuzz/releases/download/8.3.1/harfbuzz-8.3.1.tar.xz
    URL_MD5 fc4c1c0cb2e8a190db5007936f290047
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
