PROJECT(mupdf)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(HOSTCFLAGS)
assert_var_defined(HOSTCC)
assert_var_defined(OS)
set(BUILD_CMD_GENERATE sh -c "env CFLAGS=\"${HOSTCFLAGS}\" $(MAKE) -j${PARALLEL_JOBS} generate build=\"release\" CC=\"${HOSTCC}\" verbose=1")

assert_var_defined(LDFLAGS)
assert_var_defined(XCFLAGS)
set(STATIC_BUILD_CMD "$(MAKE) -j${PARALLEL_JOBS}")
set(STATIC_BUILD_CMD "${STATIC_BUILD_CMD} LDFLAGS=\"${LDFLAGS}\" XCFLAGS=\"${XCFLAGS}\"")
set(STATIC_BUILD_CMD "${STATIC_BUILD_CMD} CC=\"${CC}\" AR=\"${AR}\" build=\"release\" MUDRAW= MUTOOL= CURL_LIB= OS=${OS}")
set(STATIC_BUILD_CMD "${STATIC_BUILD_CMD} verbose=1 FREETYPE_DIR=nonexisting JPEG_DIR=nonexisting ZLIB_DIR=nonexisting CROSSCOMPILE=yes")
set(STATIC_BUILD_CMD sh -c "${STATIC_BUILD_CMD} third libs")

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
assert_var_defined(MUPDF_LIB)
assert_var_defined(RPATH)
if($ENV{DARWIN})
    set(LINK_OPTS "-Wl,-rpath,'${RPATH}'")
    set(LINK_OPTS "${LINK_OPTS} -Wl,-all_load ${MUPDF_LIB_STATIC}")
    set(LINK_OPTS "${LINK_OPTS} -Wl,-all_load ${MUPDF_THIRDPARTY_LIBS}")
    set(LINK_OPTS "${LINK_OPTS} -dynamiclib -undefined dynamic_lookup")
    set(LINK_OPTS "${LINK_OPTS} build/release/libjbig2dec.a")
else()
    set(LINK_OPTS "-Wl,-E -Wl,-rpath,'${RPATH}'")
    set(LINK_OPTS "${LINK_OPTS} -Wl,--whole-archive ${MUPDF_LIB_STATIC}")
    set(LINK_OPTS "${LINK_OPTS} -Wl,--no-whole-archive ${MUPDF_THIRDPARTY_LIBS}")
    set(LINK_OPTS "${LINK_OPTS} -Wl,-soname=${MUPDF_SONAME}")
    set(LINK_OPTS "${LINK_OPTS} build/release/libmupdfthird.a")
endif()
set(SHARED_BUILD_STR "${CC} -shared ${CFLAGS} ${LINK_OPTS} ${AES_LIB} ${ZLIB} ${JPEG_LIB} ${FREETYPE_LIB} -o ${MUPDF_LIB} -lm")

# explictly use envs defined in Makefile.defs
if($ENV{ANDROID})
    set(SHARED_BUILD_STR "${SHARED_BUILD_STR} -llog")
endif($ENV{ANDROID})

set(SHARED_BUILD_CMD sh -c "${SHARED_BUILD_STR}")
# use external fonts
set(PATCH_CMD1 sh -c "patch -N -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/external_fonts.patch || true")
# add support for encryted zips
set(PATCH_CMD2 sh -c "patch -N -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/encrypted_zip.patch || true")
# use libjpeg as a shared library
set(PATCH_CMD3 sh -c "patch -N -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg_shared.patch || true")
# vec_dot fix (see https://github.com/ArtifexSoftware/mupdf/pull/5, needed for v1.12)
set(PATCH_CMD4 sh -c "patch -N -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/vec_dot.patch || true")
# needed for Android
set(PATCH_CMD5 sh -c "patch -N -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/size_max.patch || true")
# needed to not fail reading some PNG with icc with our -DNO_ICC
set(PATCH_CMD6 sh -c "patch -N -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/no_icc_fixes.patch || true")

# TODO: ignore shared git submodules built outside of mupdf by ourselves
# https://git.ghostscript.com/mupdf.git is slow, so we use the official mirror on GitHub
ep_get_source_dir(SOURCE_DIR)
ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/ArtifexSoftware/mupdf.git
    tags/1.12.0
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
