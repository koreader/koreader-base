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
set(STATIC_BUILD_CMD "${STATIC_BUILD_CMD} CC=\"${CC}\" build=\"release\" MUDRAW= MUTOOL= CURL_LIB= OS=${OS}")
set(STATIC_BUILD_CMD "${STATIC_BUILD_CMD} verbose=1 FREETYPE_DIR=nonexisting JPEG_DIR=nonexisting ZLIB_DIR=nonexisting CROSSCOMPILE=yes")
set(STATIC_BUILD_CMD "${STATIC_BUILD_CMD} third libs")

# by default, mupdf compiles to a static library:
# we generate a dynamic library from the static library:
assert_var_defined(CFLAGS)
assert_var_defined(MUPDF_LIB_STATIC)
assert_var_defined(MUPDF_JS_LIB_STATIC)
assert_var_defined(MUPDF_THIRDPARTY_LIBS)
assert_var_defined(MUPDF_SONAME)
assert_var_defined(ZLIB)
assert_var_defined(AES_LIB)
assert_var_defined(JPEG_LIB)
assert_var_defined(FREETYPE_LIB)
assert_var_defined(MUPDF_LIB)
assert_var_defined(RPATH)
set(LINK_OPTS "-Wl,-E -Wl,-rpath,'${RPATH}'")
set(LINK_OPTS "${LINK_OPTS} -Wl,--whole-archive ${MUPDF_LIB_STATIC}")
set(LINK_OPTS "${LINK_OPTS} -Wl,--whole-archive ${MUPDF_JS_LIB_STATIC}")
set(LINK_OPTS "${LINK_OPTS} -Wl,--no-whole-archive ${MUPDF_THIRDPARTY_LIBS}")
set(LINK_OPTS "${LINK_OPTS} -Wl,-soname=${MUPDF_SONAME}")
set(LINK_OPTS "${LINK_OPTS} build/release/libopenjpeg.a build/release/libmujs.a build/release/libjbig2dec.a")
set(SHARED_BUILD_CMD "${CC} -shared ${CFLAGS} ${LINK_OPTS} ${AES_LIB} ${ZLIB} ${JPEG_LIB} ${FREETYPE_LIB} -o ${MUPDF_LIB} -lm")
if(${ANDROID})
    set(SHARED_BUILD_CMD "${SHARED_BUILD_CMD} -llog")
endif(${ANDROID})

# TODO: ignore shared git submodules built outside of mupdf by ourselves
ep_get_source_dir(SOURCE_DIR)
ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://gitlab.com/koreader/mupdf.git
    c3a0d0fe7615ae201efd882dc961f3815a92a375
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
	# MuPDF patch: use external fonts
    PATCH_COMMAND sh -c "patch -N -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/external_fonts.patch || true"
    # skip configure
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD_GENERATE} COMMAND sh -c ${STATIC_BUILD_CMD} COMMAND sh -c ${SHARED_BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
