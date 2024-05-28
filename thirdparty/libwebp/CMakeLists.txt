cmake_minimum_required(VERSION 3.5.1)
project(libwebp LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CXX)
assert_var_defined(LDFLAGS)

list(APPEND PATCH_CMD COMMAND ./autogen.sh)

# No build rpath
list(APPEND PATCH_CMD COMMAND ${ISED} "s/\\(hardcode_into_libs\\)=.*$/\\1=no/" configure)

set(CFG_ENV_VAR "CC=${CC}" "CXX=${CXX}" "CPPFLAGS=${CPPFLAGS}" "LDFLAGS=${LDFLAGS}")
# Note: with "--disable-libwebpmux --disable-libwebpdemux --enable-libwebpdecoder", we could
# build libwebpdecoder.so only, which would be smaller and fine decoding single frame webp
# images. But it fails on animated webp images, not even rendering the first frame.
# We need the regular libraries (libwebp.so and libwebpdemux.so) to handle them
# (but we can left out the encoder, libwebpmux.so).
set(CFG_OPTS --prefix=${INSTALL_DIR} --disable-static --enable-shared --host=${CHOST} --disable-libwebpmux)
list(APPEND CFG_CMD COMMAND env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} install)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/webmproject/libwebp.git
    v1.3.2
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
