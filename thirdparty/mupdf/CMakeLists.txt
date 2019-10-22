project(mupdf)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(HOSTCFLAGS)
assert_var_defined(HOSTCC)
assert_var_defined(OS)
if($ENV{KODEBUG})
    set(MUPDF_BUILD_TYPE "debug")
else()
    set(MUPDF_BUILD_TYPE "release")
endif()

# There's some headers to generate on the host's side first, before we run our actual build (where we enforce CROSSCOMPILE to avoid trying to regen those).
set(BUILD_CMD_GENERATE sh -c "env CFLAGS=\"${HOSTCFLAGS}\" ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} generate build=\"${MUPDF_BUILD_TYPE}\" CC=\"${HOSTCC}\" LDFLAGS=\"\" verbose=\"no\"")

assert_var_defined(LDFLAGS)
assert_var_defined(XCFLAGS)
# disable a couple of things to save a small bit of space
# CMYK plotter only 100 kB
# javascript (for form data validation) close to 800 kB
set(XCFLAGS "${XCFLAGS} -DFZ_PLOTTERS_CMYK=0 -DFZ_ENABLE_JS=0")
set(STATIC_BUILD_CMD sh -c "${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}")
set(STATIC_BUILD_CMD "${STATIC_BUILD_CMD} LDFLAGS=\"${LDFLAGS}\" XCFLAGS=\"${XCFLAGS}\"")
set(STATIC_BUILD_CMD "${STATIC_BUILD_CMD} CC=\"${CC}\" CXX=\"${CXX}\" AR=\"${AR}\" build=\"${MUPDF_BUILD_TYPE}\" MUDRAW= MUTOOL= CURL_LIB= OS=${OS}")
set(STATIC_BUILD_CMD "${STATIC_BUILD_CMD} verbose=\"no\" FREETYPE_DIR=nonexisting HARFBUZZ_DIR=nonexisting LIBJPEG_DIR=nonexisting ZLIB_DIR=nonexisting CROSSCOMPILE=\"yes\"")
set(STATIC_BUILD_CMD "${STATIC_BUILD_CMD} SYS_HARFBUZZ_CFLAGS=\"\" SYS_HARFBUZZ_LIBS=\"-lharfbuzz\"")
set(STATIC_BUILD_CMD "${STATIC_BUILD_CMD} third libs")

# by default, mupdf compiles to a static library:
# we generate a dynamic library from the static library:
assert_var_defined(CFLAGS)
assert_var_defined(MUPDF_LIB_STATIC)
assert_var_defined(MUPDF_THIRDPARTY_LIBS)
assert_var_defined(MUPDF_SONAME)
assert_var_defined(ZLIB)
assert_var_defined(AES_LIB)
assert_var_defined(JPEG_LIB)
assert_var_defined(FREETYPE_LIB)
assert_var_defined(HARFBUZZ_LIB)
assert_var_defined(MUPDF_LIB)
assert_var_defined(RPATH)
if($ENV{DARWIN})
    set(LINK_OPTS "-Wl,-rpath,'${RPATH}'")
    set(LINK_OPTS "${LINK_OPTS} -Wl,-all_load ${MUPDF_LIB_STATIC}")
    set(LINK_OPTS "${LINK_OPTS} -Wl,-all_load ${MUPDF_THIRDPARTY_LIBS}")
    set(LINK_OPTS "${LINK_OPTS} -dynamiclib -undefined dynamic_lookup")
else()
    set(LINK_OPTS "-Wl,-E -Wl,-rpath,'${RPATH}'")
    set(LINK_OPTS "${LINK_OPTS} -Wl,--whole-archive ${MUPDF_LIB_STATIC}")
    set(LINK_OPTS "${LINK_OPTS} -Wl,--no-whole-archive ${MUPDF_THIRDPARTY_LIBS}")
    set(LINK_OPTS "${LINK_OPTS} -Wl,-soname=${MUPDF_SONAME}")
    set(LINK_OPTS "${LINK_OPTS} build/${MUPDF_BUILD_TYPE}/libmupdfthird.a")
endif()
set(SHARED_BUILD_STR sh -c "${CC} -shared ${CFLAGS} ${LINK_OPTS} ${AES_LIB} ${ZLIB} ${JPEG_LIB} ${FREETYPE_LIB} ${HARFBUZZ_LIB} -o ${MUPDF_LIB} -lm")

# explictly use envs defined in Makefile.defs
if($ENV{ANDROID})
    set(SHARED_BUILD_STR "${SHARED_BUILD_STR} -llog")
endif()

set(SHARED_BUILD_CMD "${SHARED_BUILD_STR}")
# use external fonts
set(PATCH_CMD1 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/external_fonts.patch")
# add support for encryted zips
set(PATCH_CMD2 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/encrypted_zip.patch")
# use libjpeg as a shared library
set(PATCH_CMD3 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg_shared.patch")
# Disable potentially crashy ARM ASM (it's 7 years old, and hell to debug)
# NOTE: There's also a few ARCH_UNALIGNED_OK checks, but we never did pass that define.
#       (FWIW, we *could*, on anything not kindle-legacy).
set(PATCH_CMD4 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/no_arm_asm.patch")
# Honor CFLAGS
set(PATCH_CMD5 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/honor_cflags.patch")
# Patch for https://bugs.ghostscript.com/show_bug.cgi?id=698877; should be in upstream from 1.15
# cf. https://github.com/koreader/koreader/issues/5182
set(PATCH_CMD6 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/upstream-698877.patch")

# TODO: ignore shared git submodules built outside of mupdf by ourselves
# https://git.ghostscript.com/mupdf.git is slow, so we use the official mirror on GitHub
ep_get_source_dir(SOURCE_DIR)
ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/ArtifexSoftware/mupdf.git
    tags/1.13.0
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND COMMAND ${PATCH_CMD1} COMMAND ${PATCH_CMD2} COMMAND ${PATCH_CMD3} COMMAND ${PATCH_CMD4} COMMAND ${PATCH_CMD5} COMMAND ${PATCH_CMD6}
    # skip configure
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD_GENERATE} COMMAND ${STATIC_BUILD_CMD} COMMAND ${SHARED_BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
