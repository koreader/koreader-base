project(harfbuzz)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

assert_var_defined(CC)
assert_var_defined(CXX)
assert_var_defined(CHOST)
assert_var_defined(CPPFLAGS)
assert_var_defined(CFLAGS)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(FREETYPE_DIR)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# We've apparently hit a weird corner-case w/ XText where GCC/STL atomics *sometimes* horribly blow up on an ARM1136JF-S CPU w/ GCC 7.5...
# c.f., https://github.com/koreader/koreader/issues/5780 & https://github.com/koreader/koreader/issues/6024
# NOTE: Our initial approach was to only disable atomics in a very dirty manner, which only helped with the first issue.
#       This, on the other hand, appears to help with both.
if(DEFINED ENV{LEGACY} OR DEFINED ENV{POCKETBOOK})
	# NOTE: This ends up in CPPFLAGS!
	set(HB_CUSTOM_CFG "-DHB_NO_MT")
endif()

set(CFG_ENV_VAR "CC=\"${CC}\" CXX=\"${CXX}\" CPPFLAGS=\"${CPPFLAGS} ${HB_CUSTOM_CFG}\" CFLAGS=\"${CFLAGS}\" CXXFLAGS=\"${CXXFLAGS}\" LDFLAGS=\"${LDFLAGS}\"")
set(CFG_ENV_VAR "${CFG_ENV_VAR} FREETYPE_CFLAGS=\"-I${FREETYPE_DIR}/include/freetype2\"")
set(CFG_ENV_VAR "${CFG_ENV_VAR} FREETYPE_LIBS=\"-L${FREETYPE_DIR} -lfreetype\"")
set(CFG_OPTS "--prefix=\"${BINARY_DIR}\" --libdir=\"${BINARY_DIR}/lib\" --enable-shared --disable-static --with-freetype --without-glib --without-gobject --without-cairo --without-fontconfig --without-icu --without-graphite2 --without-uniscribe --without-directwrite --without-coretext --host=\"${CHOST}\"")
set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

set(AUTOGEN_CMD sh -c "env NOCONFIGURE=1 ./autogen.sh")

if($ENV{ANDROID})
    set(CFG_CMD "${CFG_CMD} && ${ISED} 's|version_type=none|version_type=linux|' libtool")
    set(CFG_CMD "${CFG_CMD} && ${ISED} 's|need_lib_prefix=no|need_lib_prefix=yes|' libtool")
    set(CFG_CMD "${CFG_CMD} && ${ISED} 's|need_version=no|need_version=yes|' libtool")
    set(CFG_CMD "${CFG_CMD} && ${ISED} 's|library_names_spec=.*|library_names_spec=\"\\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$versuffix \\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$major \\\\\$libname\\\\\$shared_ext\"|' libtool")
    set(CFG_CMD "${CFG_CMD} && ${ISED} 's|soname_spec=.*|soname_spec=\"\\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$major\"|' libtool")
endif()

set(HB_VER 7.0.0)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/harfbuzz/harfbuzz.git
    ${HB_VER}
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND COMMAND ${PATCH_CMD} COMMAND ${AUTOGEN_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${CONSTRAINED_PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} install
)
