cmake_minimum_required(VERSION 3.5.1)
project(harfbuzz LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CXX)
assert_var_defined(CFLAGS)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)
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

list(APPEND PATCH_CMD COMMAND env NOCONFIGURE=1 ./autogen.sh)

# No build rpath
list(APPEND PATCH_CMD COMMAND ${ISED} "s/\\(hardcode_into_libs\\)=.*$/\\1=no/" configure)

# We've apparently hit a weird corner-case w/ XText where GCC/STL atomics *sometimes* horribly blow up on an ARM1136JF-S CPU w/ GCC 7.5...
# c.f., https://github.com/koreader/koreader/issues/5780 & https://github.com/koreader/koreader/issues/6024
# NOTE: Our initial approach was to only disable atomics in a very dirty manner, which only helped with the first issue.
#       This, on the other hand, appears to help with both.
if(LEGACY OR POCKETBOOK)
	# NOTE: This ends up in CPPFLAGS!
	set(HB_CUSTOM_CFG "-DHB_NO_MT")
endif()

set(CFG_ENV_VAR "CC=${CC}" "CXX=${CXX}" "CPPFLAGS=${HB_CUSTOM_CFG}" "CFLAGS=${CFLAGS}" "CXXFLAGS=${CXXFLAGS}" "LDFLAGS=${LDFLAGS}")
set(CFG_ENV_VAR ${CFG_ENV_VAR} "FREETYPE_CFLAGS=-I${FREETYPE_DIR}/include/freetype2")
set(CFG_ENV_VAR ${CFG_ENV_VAR} "FREETYPE_LIBS=-L${FREETYPE_DIR}/lib -lfreetype")
set(CFG_OPTS --prefix=${INSTALL_DIR} --enable-shared --disable-static --with-freetype --without-glib --without-gobject --without-cairo --without-fontconfig --without-icu --without-graphite2 --without-uniscribe --without-directwrite --without-coretext --host=${CHOST})
list(APPEND CFG_CMD COMMAND env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} install)

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
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
